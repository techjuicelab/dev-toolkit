#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

# 필수 명령어 확인
for cmd in iptables ipset curl jq dig; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: 필수 명령어 '$cmd'가 설치되어 있지 않습니다"
    exit 1
  fi
done

# aggregate는 선택사항 (없으면 CIDR 집계 건너뜀)
HAS_AGGREGATE=false
if command -v aggregate &>/dev/null; then
  HAS_AGGREGATE=true
fi

# 루트 권한 확인
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: 이 스크립트는 root 권한으로 실행해야 합니다"
  exit 1
fi

# iptables 규칙 백업
BACKUP_RULES="/tmp/iptables_backup_$$.rules"
iptables-save > "$BACKUP_RULES" 2>/dev/null || true

# ERR 트랩: 실패 시 규칙 복원
restore_rules() {
  echo "ERROR: 스크립트 실패, 기존 규칙을 복원합니다..."
  if [[ -f "$BACKUP_RULES" ]]; then
    iptables-restore < "$BACKUP_RULES" 2>/dev/null || true
    rm -f "$BACKUP_RULES"
  fi
}
trap restore_rules ERR

# 정상 종료 시 백업 파일 정리
cleanup_backup() {
  rm -f "$BACKUP_RULES"
}
trap cleanup_backup EXIT

# GitHub API에서 메타 정보 가져오기 (재시도 로직 포함)
fetch_github_meta() {
  local max_retries=3
  for ((i=1; i<=max_retries; i++)); do
    local result
    if result=$(curl -s --connect-timeout 10 --max-time 30 https://api.github.com/meta); then
      echo "$result"
      return 0
    fi
    echo "GitHub API 연결 재시도... ($i/$max_retries)" >&2
    sleep $((i * 2))
  done
  return 1
}

# 1. Extract Docker DNS info BEFORE any flushing
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

# Flush existing rules and delete existing ipsets
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

# 2. Selectively restore ONLY internal Docker DNS resolution
if [ -n "$DOCKER_DNS_RULES" ]; then
    echo "Restoring Docker DNS rules..."
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
else
    echo "No Docker DNS rules to restore"
fi

# First allow DNS and localhost before any restrictions
# Allow outbound DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
# Allow inbound DNS responses
iptables -A INPUT -p udp --sport 53 -j ACCEPT
# Allow outbound SSH
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
# Allow inbound SSH responses
iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Create ipset with CIDR support
ipset create allowed-domains hash:net

# Fetch GitHub meta information and aggregate + add their IP ranges
echo "Fetching GitHub IP ranges..."
gh_ranges=$(fetch_github_meta)
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges"
    exit 1
fi

if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
    echo "ERROR: GitHub API response missing required fields"
    exit 1
fi

echo "Processing GitHub IPs..."
if $HAS_AGGREGATE; then
    while read -r cidr; do
        if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
            echo "ERROR: Invalid CIDR range from GitHub meta: $cidr"
            exit 1
        fi
        echo "Adding GitHub range $cidr"
        ipset add allowed-domains "$cidr"
    done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
else
    echo "WARNING: aggregate 명령어 없음, CIDR 집계 없이 원본 IP 범위를 사용합니다"
    while read -r cidr; do
        if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
            echo "ERROR: Invalid CIDR range from GitHub meta: $cidr"
            exit 1
        fi
        echo "Adding GitHub range $cidr"
        ipset add allowed-domains "$cidr"
    done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]')
fi

# Resolve and add other allowed domains
for domain in \
    "registry.npmjs.org" \
    "api.anthropic.com" \
    "sentry.io" \
    "statsig.anthropic.com" \
    "statsig.com" \
    "marketplace.visualstudio.com" \
    "vscode.blob.core.windows.net" \
    "update.code.visualstudio.com"; do
    echo "Resolving $domain..."
    local_ips=""
    if ! local_ips=$(dig +noall +answer A "$domain" 2>/dev/null | awk '$4 == "A" {print $5}'); then
        echo "WARNING: $domain DNS 해석 실패, 건너뜁니다"
        continue
    fi
    if [ -z "$local_ips" ]; then
        echo "WARNING: $domain DNS 해석 실패, 건너뜁니다"
        continue
    fi

    while read -r ip; do
        if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "ERROR: Invalid IP from DNS for $domain: $ip"
            exit 1
        fi
        echo "Adding $ip for $domain"
        ipset add allowed-domains "$ip"
    done < <(echo "$local_ips")
done

# Get host IP from default route
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -z "$HOST_IP" ]; then
    echo "ERROR: Failed to detect host IP"
    exit 1
fi

HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
echo "Host network detected as: $HOST_NETWORK"

# Set up remaining iptables rules
iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT

# Set default policies to DROP first
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# First allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Then allow only specific outbound traffic to allowed domains
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# Explicitly REJECT all other outbound traffic for immediate feedback
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

echo "Firewall configuration complete"
echo "Verifying firewall rules..."
if curl --connect-timeout 5 --max-time 30 https://example.com >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - was able to reach https://example.com"
    exit 1
else
    echo "Firewall verification passed - unable to reach https://example.com as expected"
fi

# Verify GitHub API access
if ! curl --connect-timeout 5 --max-time 30 https://api.github.com/zen >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - unable to reach https://api.github.com"
    exit 1
else
    echo "Firewall verification passed - able to reach https://api.github.com as expected"
fi
