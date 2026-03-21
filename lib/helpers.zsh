#!/bin/zsh
# ─────────────────────────────────────────────────────
# helpers.zsh - dev-toolkit 공용 헬퍼 함수
# 명령 실행, 로깅, 재시도, 타임아웃 등 유틸리티
# ─────────────────────────────────────────────────────

# config.zsh 로드
source "${0:A:h}/config.zsh" || { echo "ERROR: config.zsh 로드 실패"; return 1; }

# ─── 1. 로그 초기화 (안전한 로그 디렉토리 생성) ────────────
# 사용법: local log_file=$(helpers_init_logging "script_name")
helpers_init_logging() {
  local script_name="$1"
  local log_dir="${LOG_DIR}"

  # 디렉토리 생성 및 권한 확인
  if ! mkdir -p "$log_dir" 2>/dev/null; then
    echo "ERROR: 로그 디렉토리 생성 실패: $log_dir" >&2
    return 1
  fi
  if [[ ! -w "$log_dir" ]]; then
    echo "ERROR: 로그 디렉토리 쓰기 권한 없음: $log_dir" >&2
    return 1
  fi

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local log_file="$log_dir/${script_name}_${timestamp}.log"
  touch "$log_file" && chmod 600 "$log_file"
  echo "$log_file"
}

# ─── 2. 명령 실행 및 로깅 (eval 없는 안전한 방식) ─────────
# 사용법: helpers_run_and_log "$log_file" command arg1 arg2
helpers_run_and_log() {
  local log_file="$1"
  shift
  echo "$(date "+$LOG_FORMAT") - $*" >> "$log_file"
  "$@" >> "$log_file" 2>&1
  return $?
}

# ─── 3. 로그 로테이션 ─────────────────────────────────────
# 오래된 로그 삭제, 파일 개수 제한, 디스크 사용량 경고
helpers_rotate_logs() {
  local log_dir="${LOG_DIR}"
  [[ ! -d "$log_dir" ]] && return 0

  # 오래된 파일 삭제 (macOS find 호환: -mtime +N은 N일 초과)
  local retention=${LOG_RETENTION_DAYS:-7}
  find "$log_dir" -name "*.log" -type f -mtime +${retention} -delete 2>/dev/null || true

  # 파일 개수 제한 (macOS 호환: -printf 대신 ls -t 사용)
  local -a log_files
  log_files=( "$log_dir"/*.log(N) )  # (N) = nullglob, 파일 없으면 빈 배열
  local file_count=${#log_files[@]}
  if (( file_count > LOG_MAX_FILES )); then
    # ls -t로 수정 시간 기준 정렬 후, 오래된 파일부터 삭제
    ls -t "$log_dir"/*.log 2>/dev/null | \
      tail -n $((file_count - LOG_MAX_FILES)) | \
      while IFS= read -r f; do rm -f "$f"; done
  fi

  # 디스크 사용량 경고
  local usage_mb=$(du -sm "$log_dir" 2>/dev/null | cut -f1)
  local max_size=${LOG_MAX_SIZE_MB:-100}
  if [[ -n "$usage_mb" ]] && (( usage_mb > max_size )); then
    echo "WARNING: 로그 디렉토리 사용량: ${usage_mb}MB (${max_size}MB 초과)" >&2
  fi
}

# ─── 4. 재시도 로직 ───────────────────────────────────────
# 사용법: helpers_retry command arg1 arg2
# MAX_RETRIES 횟수만큼 재시도, RETRY_DELAY_SECONDS 간격
helpers_retry() {
  local max_attempts=${MAX_RETRIES}
  local delay=${RETRY_DELAY_SECONDS}
  local attempt=1

  while (( attempt <= max_attempts )); do
    if "$@"; then
      return 0
    fi
    if (( attempt < max_attempts )); then
      echo "재시도 $attempt/$max_attempts..." >&2
      sleep "$delay"
    fi
    ((attempt++))
  done
  return 1
}

# ─── 5. 타임아웃 실행 ─────────────────────────────────────
# 사용법: helpers_run_with_timeout 30 command arg1 arg2
# 지정된 초 안에 명령이 완료되지 않으면 종료 (exit code 124)
helpers_run_with_timeout() {
  local timeout_sec=$1
  shift

  if command -v timeout &>/dev/null; then
    timeout "$timeout_sec" "$@"
    local exit_code=$?
    if (( exit_code == 124 )); then
      echo "ERROR: 명령어 타임아웃 (${timeout_sec}초 초과)" >&2
    fi
    return $exit_code
  else
    # timeout 명령어가 없으면 백그라운드 + wait 방식으로 대체
    "$@" &
    local pid=$!
    local elapsed=0
    while (( elapsed < timeout_sec )); do
      if ! kill -0 "$pid" 2>/dev/null; then
        wait "$pid"
        return $?
      fi
      sleep 1
      ((elapsed++))
    done
    kill -TERM "$pid" 2>/dev/null || true
    sleep 1
    kill -KILL "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null  # 좀비 프로세스 방지를 위해 reap
    echo "ERROR: 명령어 타임아웃 (${timeout_sec}초 초과)" >&2
    return 124
  fi
}

# ─── 6. 헬스 체크 (디스크 공간 등) ────────────────────────
# 사용법: helpers_check_health
# 디스크 공간 100MB 미만 시 경고 출력
helpers_check_health() {
  # 디스크 공간 확인 (100MB 미만 경고)
  local free_kb=$(df -k "$HOME" | tail -1 | awk '{print $4}')
  if (( free_kb < 102400 )); then
    echo "WARNING: 디스크 공간 부족 ($(( free_kb / 1024 ))MB 남음)" >&2
  fi
}
