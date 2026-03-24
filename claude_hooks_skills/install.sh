#!/usr/bin/env bash
# install.sh — 대상 프로젝트에 Claude Code hooks/skills를 선택 설치
#
# 사용법:
#   대상 프로젝트 폴더에서 실행:
#     bash ~/.zsh.d/claude_hooks_skills/install.sh
#   또는 alias:
#     claude-setup-hooks
#
# 조작법:
#   ↑/↓  항목 이동
#   Space 선택/해제 토글
#   a    전체 선택
#   n    전체 해제
#   Enter 설치 시작
#   q    취소

# No set -e or set -u — they cause problems with interactive read and heredocs

# --- 색상 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- 경로 설정 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"

# --- 설치 항목 정의 ---
NAMES=("commit-session" "load-recent-changes" "merge-worktree" "verify-implementation" "manage-skills")
TYPES=("hook" "hook" "skill" "skill" "skill")
DESCS=(
  "세션 종료 시 자동 WIP 커밋 + CHANGELOG 업데이트"
  "세션 시작 시 최근 변경사항 컨텍스트 로드"
  "worktree 브랜치를 squash-merge"
  "등록된 verify 스킬 통합 실행"
  "세션 변경사항 분석 및 verify 스킬 관리"
)
TOTAL=${#NAMES[@]}

# 선택 상태 (동적 생성)
SELECTED=()
for ((i = 0; i < TOTAL; i++)); do
  SELECTED+=(1)
done
CURSOR=0

# 실패한 항목 추적
FAILED=()

# --- 터미널 제어 ---
cleanup() {
  printf '\033[?25h'  # show cursor
  stty sane 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# 메뉴 라인 수 동적 계산
calc_menu_lines() {
  local lines=0
  local prev_type=""
  lines=$((lines + 1))  # "설치할 항목을 선택하세요:"
  lines=$((lines + 1))  # blank
  for ((i = 0; i < TOTAL; i++)); do
    if [[ "${TYPES[$i]}" != "$prev_type" ]]; then
      prev_type="${TYPES[$i]}"
      lines=$((lines + 1))  # section header
    fi
    lines=$((lines + 1))  # item
  done
  lines=$((lines + 1))  # blank
  lines=$((lines + 1))  # key help line
  echo "$lines"
}

MENU_LINES=$(calc_menu_lines)

draw_menu() {
  local i current_type

  printf "${BOLD}설치할 항목을 선택하세요:${NC}\n"
  printf "\n"

  current_type=""
  for ((i = 0; i < TOTAL; i++)); do
    local type="${TYPES[$i]}"
    local name="${NAMES[$i]}"
    local desc="${DESCS[$i]}"

    if [[ "$type" != "$current_type" ]]; then
      current_type="$type"
      if [[ "$type" == "hook" ]]; then
        printf "  ${YELLOW}── Hooks ──${NC}\n"
      else
        printf "  ${YELLOW}── Skills ──${NC}\n"
      fi
    fi

    local prefix="   "
    if [[ $i -eq $CURSOR ]]; then
      prefix=" ${CYAN}▸${NC} "
    fi

    local check="${DIM}[ ]${NC}"
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      check="${GREEN}[✓]${NC}"
    fi

    if [[ $i -eq $CURSOR ]]; then
      printf "${prefix}${check} ${BOLD}${CYAN}${name}${NC} — ${desc}\n"
    else
      printf "${prefix}${check} ${BOLD}${name}${NC} — ${desc}\n"
    fi
  done

  printf "\n"
  printf "  ${DIM}↑↓${NC} 이동  ${DIM}Space${NC} 선택  ${DIM}a${NC} 전체선택  ${DIM}n${NC} 전체해제  ${DIM}Enter${NC} 설치  ${DIM}q${NC} 취소\n"
}

redraw_menu() {
  # Move cursor up MENU_LINES lines, then clear from cursor to end of screen
  printf "\033[${MENU_LINES}A"
  printf "\033[J"
  draw_menu
}

# --- 키 입력 읽기 ---
read_key() {
  local key seq
  IFS= read -rsn1 key </dev/tty 2>/dev/null || { printf "ESC"; return; }
  if [[ "$key" == $'\x1b' ]]; then
    IFS= read -rsn2 -t 0.5 seq </dev/tty 2>/dev/null || true
    case "$seq" in
      '[A') printf "UP" ;;
      '[B') printf "DOWN" ;;
      *)    printf "ESC" ;;
    esac
  elif [[ "$key" == "" ]]; then
    printf "ENTER"
  elif [[ "$key" == " " ]]; then
    printf "SPACE"
  else
    printf "%s" "$key"
  fi
}

# --- 설치 함수 ---
install_hook() {
  local name="$1"
  local src="${SCRIPT_DIR}/.claude/hooks/${name}.sh"
  local dst="${TARGET_DIR}/.claude/hooks/${name}.sh"

  if [[ ! -f "$src" ]]; then
    printf "  ${RED}✗${NC} ${name} — 소스 파일 없음\n"
    return 1
  fi

  if ! mkdir -p "${TARGET_DIR}/.claude/hooks" 2>/dev/null; then
    printf "  ${RED}✗${NC} ${name} — 디렉토리 생성 실패\n"
    return 1
  fi

  if ! cp "$src" "$dst" 2>/dev/null; then
    printf "  ${RED}✗${NC} ${name} — 파일 복사 실패\n"
    return 1
  fi

  chmod +x "$dst"
  printf "  ${GREEN}✓${NC} hook: ${name}\n"
}

install_skill() {
  local name="$1"
  local src="${SCRIPT_DIR}/.claude/skills/${name}/SKILL.md"
  local dst_dir="${TARGET_DIR}/.claude/skills/${name}"

  if [[ ! -f "$src" ]]; then
    printf "  ${RED}✗${NC} ${name} — 소스 파일 없음\n"
    return 1
  fi

  if ! mkdir -p "$dst_dir" 2>/dev/null; then
    printf "  ${RED}✗${NC} ${name} — 디렉토리 생성 실패\n"
    return 1
  fi

  if ! cp "$src" "${dst_dir}/SKILL.md" 2>/dev/null; then
    printf "  ${RED}✗${NC} ${name} — 파일 복사 실패\n"
    return 1
  fi

  printf "  ${GREEN}✓${NC} skill: ${name}\n"
}

generate_settings() {
  local settings_file="${TARGET_DIR}/.claude/settings.json"
  local needs_commit=0
  local needs_load=0

  [[ "${SELECTED[0]}" -eq 1 ]] && needs_commit=1
  [[ "${SELECTED[1]}" -eq 1 ]] && needs_load=1

  if [[ $needs_commit -eq 0 ]] && [[ $needs_load -eq 0 ]]; then
    return 0
  fi

  if ! mkdir -p "${TARGET_DIR}/.claude" 2>/dev/null; then
    printf "  ${RED}✗${NC} settings.json — 디렉토리 생성 실패\n"
    return 1
  fi

  if [[ -f "$settings_file" ]]; then
    cp "$settings_file" "${settings_file}.bak"
    printf "  ${YELLOW}↳${NC} 기존 settings.json 백업 → settings.json.bak\n"
  fi

  # Build JSON with printf — $CLAUDE_PROJECT_DIR stays literal
  if [[ $needs_commit -eq 1 ]] && [[ $needs_load -eq 1 ]]; then
    # Both hooks
    printf '%s\n' '{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/commit-session.sh",
            "async": true,
            "timeout": 120
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/load-recent-changes.sh"
          }
        ]
      }
    ]
  }
}' > "$settings_file"

  elif [[ $needs_commit -eq 1 ]]; then
    # Only commit hook
    printf '%s\n' '{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/commit-session.sh",
            "async": true,
            "timeout": 120
          }
        ]
      }
    ]
  }
}' > "$settings_file"

  elif [[ $needs_load -eq 1 ]]; then
    # Only load hook
    printf '%s\n' '{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/load-recent-changes.sh"
          }
        ]
      }
    ]
  }
}' > "$settings_file"

  fi

  printf "  ${GREEN}✓${NC} settings.json 업데이트\n"
}

# ========== 메인 ==========

printf "\n"
printf "${CYAN}${BOLD}╔══════════════════════════════════════════════════╗${NC}\n"
printf "${CYAN}${BOLD}║   Claude Code Hooks & Skills Installer          ║${NC}\n"
printf "${CYAN}${BOLD}╚══════════════════════════════════════════════════╝${NC}\n"
printf "\n"
printf "${BOLD}대상:${NC} ${TARGET_DIR}\n"

# 대상 디렉토리가 git repo인지 확인
if ! git -C "$TARGET_DIR" rev-parse --git-dir &>/dev/null; then
  printf "\n"
  printf "${RED}오류: 현재 디렉토리가 git 저장소가 아닙니다.${NC}\n"
  printf "대상 프로젝트 폴더에서 실행해주세요.\n"
  exit 1
fi

# 자기 자신에 설치 방지
if [[ "$TARGET_DIR" == "$SCRIPT_DIR" ]]; then
  printf "\n"
  printf "${RED}오류: 이 저장소 자체에는 설치할 수 없습니다.${NC}\n"
  printf "대상 프로젝트 폴더에서 실행해주세요.\n"
  exit 1
fi

printf "\n"

# 메뉴 그리기
printf '\033[?25l'  # hide cursor
draw_menu

# 인터랙티브 루프
while true; do
  key=$(read_key)

  case "$key" in
    UP)
      if [[ $CURSOR -gt 0 ]]; then
        CURSOR=$((CURSOR - 1))
      else
        CURSOR=$((TOTAL - 1))
      fi
      redraw_menu
      ;;
    DOWN)
      if [[ $CURSOR -lt $((TOTAL - 1)) ]]; then
        CURSOR=$((CURSOR + 1))
      else
        CURSOR=0
      fi
      redraw_menu
      ;;
    SPACE)
      if [[ "${SELECTED[$CURSOR]}" -eq 1 ]]; then
        SELECTED[$CURSOR]=0
      else
        SELECTED[$CURSOR]=1
      fi
      redraw_menu
      ;;
    a|A)
      for ((i = 0; i < TOTAL; i++)); do
        SELECTED[$i]=1
      done
      redraw_menu
      ;;
    n|N)
      for ((i = 0; i < TOTAL; i++)); do
        SELECTED[$i]=0
      done
      redraw_menu
      ;;
    q|Q|ESC)
      printf '\033[?25h'  # show cursor
      printf "\n취소되었습니다.\n"
      exit 0
      ;;
    ENTER)
      total_selected=0
      for s in "${SELECTED[@]}"; do
        total_selected=$((total_selected + s))
      done
      if [[ $total_selected -eq 0 ]]; then
        redraw_menu
        continue
      fi
      break
      ;;
  esac
done

printf '\033[?25h'  # show cursor

# --- 설치 실행 ---
printf "\n"
printf "${BOLD}설치 중...${NC}\n"
printf "\n"

installed=0
failed=0

# 설치 항목을 동적으로 순회
for ((i = 0; i < TOTAL; i++)); do
  if [[ "${SELECTED[$i]}" -eq 1 ]]; then
    if [[ "${TYPES[$i]}" == "hook" ]]; then
      if install_hook "${NAMES[$i]}"; then
        installed=$((installed + 1))
      else
        failed=$((failed + 1))
        FAILED+=("${NAMES[$i]}")
      fi
    else
      if install_skill "${NAMES[$i]}"; then
        installed=$((installed + 1))
      else
        failed=$((failed + 1))
        FAILED+=("${NAMES[$i]}")
      fi
    fi
  fi
done

# Settings.json 생성
generate_settings

printf "\n"
if [[ $failed -gt 0 ]]; then
  printf "${YELLOW}${BOLD}완료! ${installed}개 성공, ${failed}개 실패${NC}\n"
  printf "${RED}실패 항목: ${FAILED[*]}${NC}\n"
else
  printf "${GREEN}${BOLD}완료! ${installed}개 항목이 설치되었습니다.${NC}\n"
fi
printf "\n"
printf "${CYAN}설치 경로: ${TARGET_DIR}/.claude/${NC}\n"
printf "\n"
