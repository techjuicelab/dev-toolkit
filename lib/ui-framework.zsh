#!/bin/zsh
# ─────────────────────────────────────────────────────
# ui-framework.zsh - dev-toolkit 통합 UI 프레임워크
# 화면 제어, 박스 드로잉, 진행률, 메시지 출력 통합
# ─────────────────────────────────────────────────────

# config.zsh 로드
source "${0:A:h}/config.zsh" || { echo "ERROR: config.zsh 로드 실패"; return 1; }

# ═══════════════════════════════════════════════════════
# 0. 터미널 호환성 감지
# ═══════════════════════════════════════════════════════

# TUI 기능 활성화 여부 (색상, 커서 제어 등)
UI_TUI_ENABLED=true

# stdout이 터미널인지 확인
if [[ ! -t 1 ]]; then
  UI_TUI_ENABLED=false
fi

# TERM이 색상을 지원하는지 확인
if [[ -z "$TERM" || "$TERM" == "dumb" ]]; then
  UI_TUI_ENABLED=false
fi

# NO_COLOR 환경 변수 지원 (https://no-color.org/)
if [[ -n "${NO_COLOR:-}" ]]; then
  UI_TUI_ENABLED=false
fi

# ─── 터미널 크기 감지 ──────────────────────────────
if [[ "$UI_TUI_ENABLED" == true ]]; then
  UI_TERMINAL_LINES=$(tput lines 2>/dev/null || echo 24)
  UI_TERMINAL_COLS=$(tput cols 2>/dev/null || echo 80)

  # 최소 터미널 크기 확인 (80x24)
  if (( UI_TERMINAL_COLS < 80 || UI_TERMINAL_LINES < 24 )); then
    echo "⚠️  터미널 크기가 작습니다 (${UI_TERMINAL_COLS}x${UI_TERMINAL_LINES}). 최소 80x24 권장." >&2
  fi
else
  UI_TERMINAL_LINES=24
  UI_TERMINAL_COLS=80
fi

# 진행률 바 위치를 터미널 높이에 맞게 조정
UI_PROGRESS_BAR_LINE=${PROGRESS_BAR_LINE:-$((UI_TERMINAL_LINES - 2))}

# 메시지 영역 크기를 터미널 높이에 맞게 조정
UI_MAX_MESSAGES=${MAX_MESSAGES:-$((UI_PROGRESS_BAR_LINE - MESSAGE_LINE - 2))}

# TUI 비활성화 시 색상 변수를 빈 문자열로 재정의
if [[ "$UI_TUI_ENABLED" != true ]]; then
  COLOR_RESET=''
  COLOR_BOLD=''
  COLOR_DIM=''
  COLOR_GREEN=''
  COLOR_RED=''
  COLOR_YELLOW=''
  COLOR_BLUE=''
  COLOR_CYAN=''
  COLOR_MAGENTA=''
  COLOR_PURPLE=''
  COLOR_ORANGE=''
  COLOR_PINK=''
fi

# ═══════════════════════════════════════════════════════
# 1. 화면 제어 함수
# ═══════════════════════════════════════════════════════

# 화면 초기화
ui_clear_screen() {
  [[ "$UI_TUI_ENABLED" == true ]] && clear
}

# 커서 숨기기
ui_hide_cursor() {
  [[ "$UI_TUI_ENABLED" == true ]] && printf "\e[?25l"
}

# 커서 보이기
ui_show_cursor() {
  [[ "$UI_TUI_ENABLED" == true ]] && printf "\e[?25h"
}

# 지정한 줄로 커서 이동 (1-based 행 번호)
ui_move_to_line() {
  [[ "$UI_TUI_ENABLED" == true ]] && printf "\e[${1};0H"
}

# 커서 위치부터 화면 끝까지 삭제
ui_clear_from_cursor() {
  [[ "$UI_TUI_ENABLED" == true ]] && printf "\e[0J"
}

# 현재 줄 전체 삭제
ui_clear_line() {
  [[ "$UI_TUI_ENABLED" == true ]] && printf "\e[2K"
}

# ═══════════════════════════════════════════════════════
# 2. 박스 드로잉 (통일된 create_title_box)
# ═══════════════════════════════════════════════════════

# 제목 박스 생성
# 사용법: ui_create_title_box "제목 텍스트" [박스너비]
# 한글/이모지의 터미널 표시 폭을 정확히 계산하여 레이아웃 정렬
ui_create_title_box() {
  local title="$1"
  local box_width="${2:-$BOX_WIDTH}"  # config.zsh의 BOX_WIDTH 사용 (기본값 52)

  # 실제 터미널 표시 너비 계산
  # - 한글: 2칸 차지하지만 ${#title}은 3바이트로 계산 → +1 보정 불필요 (이미 길이에 포함)
  # - 이모지: 2칸 차지하지만 ${#title}에서 과소 계산됨 → +1 보정
  # - 기존 스크립트 로직: display_width = str_len + emoji_count + hangul_count
  local str_len=${#title}
  local emoji_count=$(echo "$title" | grep -oE '[🔄🐳🍺🛠️🎯🚀⚡🔌🔧📦💾🌐🧹📚📱🎉🎊🚨]' | wc -l | tr -d ' ')
  local hangul_count=$(echo "$title" | grep -oE '[가-힣]' | wc -l | tr -d ' ')
  local display_width=$((str_len + emoji_count + hangul_count))

  # 박스 내부 여백 계산 (실제 표시 너비 기준)
  local inner_padding=$((box_width - display_width - 2))
  local left_padding=$((inner_padding / 2 + 2))
  local right_padding=$((inner_padding - left_padding + 2))

  # 수평선 생성 (박스 크기 기준) - printf로 루프 대체하여 성능 최적화
  local horizontal_line=$(printf '═%.0s' $(seq 1 $box_width))

  # 제목 라인 생성 (실제 표시 기준 패딩) - printf로 루프 대체하여 성능 최적화
  local left_spaces=$(printf ' %.0s' $(seq 1 $left_padding))
  local right_spaces=$(printf ' %.0s' $(seq 1 $right_padding))
  local title_line="║${left_spaces}${title}${right_spaces}║"

  echo -e "${COLOR_BOLD}${COLOR_CYAN}╔${horizontal_line}╗${COLOR_RESET}"
  echo -e "${COLOR_BOLD}${COLOR_CYAN}${title_line}${COLOR_RESET}"
  echo -e "${COLOR_BOLD}${COLOR_CYAN}╚${horizontal_line}╝${COLOR_RESET}"
}

# ═══════════════════════════════════════════════════════
# 3. 메시지 출력 시스템
# ═══════════════════════════════════════════════════════

# 글로벌 메시지 라인 카운터
# MESSAGE_LINE은 config.zsh에서 로드, UI_MAX_MESSAGES는 동적 계산됨
UI_CURRENT_MESSAGE_LINE=$MESSAGE_LINE

# 메시지 출력 (화면 + 로그 파일)
# 사용법: ui_add_message <색상변수> <메시지> [로그파일경로]
# TUI 모드에서는 화면 위치 기반 출력, 비TUI 모드에서는 일반 출력
ui_add_message() {
  local color="$1"
  local message="$2"
  local log_file="$3"

  # 로그 파일에는 ANSI 코드 없이 순수 텍스트만 기록
  if [[ -n "$log_file" ]]; then
    local clean_message=$(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')
    echo "$(date "+${LOG_FORMAT}") - $clean_message" >> "$log_file"
  fi

  if [[ "$UI_TUI_ENABLED" == true ]]; then
    # 메시지 영역 초과 시 스크롤 리셋
    if [ $UI_CURRENT_MESSAGE_LINE -gt $((MESSAGE_LINE + UI_MAX_MESSAGES)) ]; then
      ui_move_to_line $MESSAGE_LINE
      ui_clear_from_cursor
      UI_CURRENT_MESSAGE_LINE=$MESSAGE_LINE
    fi
    ui_move_to_line $UI_CURRENT_MESSAGE_LINE
    ui_clear_line
    echo -e "${color}${message}${COLOR_RESET}"
    UI_CURRENT_MESSAGE_LINE=$((UI_CURRENT_MESSAGE_LINE + 1))
  else
    # 비TUI 모드: 일반 출력
    echo -e "${color}${message}${COLOR_RESET}"
  fi
}

# 편의 메시지 함수 (로그 파일은 UI_LOG_FILE 글로벌 변수 사용)
# 각 스크립트에서 UI_LOG_FILE을 설정하면 자동으로 로그에 기록됨
UI_LOG_FILE=""

ui_echo_info() {
  ui_add_message "$COLOR_CYAN" "${EMOJI[info]}  [INFO] $1" "$UI_LOG_FILE"
}

ui_echo_success() {
  ui_add_message "$COLOR_GREEN" "${EMOJI[success]} [OK] $1" "$UI_LOG_FILE"
}

ui_echo_warn() {
  ui_add_message "$COLOR_ORANGE" "${EMOJI[warning]}  [WARN] $1" "$UI_LOG_FILE"
}

ui_echo_error() {
  ui_add_message "${COLOR_RED}${COLOR_BOLD}" "${EMOJI[error]} [ERROR] $1" "$UI_LOG_FILE"
}

# ═══════════════════════════════════════════════════════
# 4. 진행률 시스템
# ═══════════════════════════════════════════════════════

# 글로벌 진행률 상태
UI_CURRENT_PCT=0
UI_CURRENT_MAIN_STEP=0

# 진행 단계 배열 (각 스크립트에서 설정)
# 사용 예:
#   ui_main_step_names=("📚 레포지토리 갱신" "⬆️ Formulae 업그레이드")
#   ui_main_step_weights=(40 60)
ui_main_step_names=()
ui_main_step_weights=()

# 진행률 업데이트
# 사용법: ui_update_progress <완료된_단계수> <현재_단계_진행률_0-100>
# step: 0-based 완료된 단계 수 (현재 단계 이전까지 완료된 수)
# prog: 현재 단계의 진행률 (0-100)
ui_update_progress() {
  local step=$1
  local prog=$2
  local cum=0

  # zsh 배열은 1-based 인덱싱
  # step=0이면 아직 아무 단계도 완료되지 않음
  # step=1이면 첫 번째 단계(인덱스 1)가 완료됨
  for ((i=1; i<=step; i++)); do
    cum=$((cum + ui_main_step_weights[i]))
  done

  # 현재 진행 중인 단계의 기여분 계산
  # step+1은 zsh 1-based에서 다음 단계의 가중치
  local contrib=$((ui_main_step_weights[step+1] * prog / 100))
  UI_CURRENT_PCT=$((cum + contrib))
  ((UI_CURRENT_PCT > 100)) && UI_CURRENT_PCT=100

  ui_draw_progress_bar
}

# 현재 단계 설정 (단계 카운터 업데이트 + 진행률 0%로 초기화)
# 사용법: ui_set_current_step <단계번호_0-based>
ui_set_current_step() {
  UI_CURRENT_MAIN_STEP=$1
  ui_update_progress $1 0
}

# 진행 바 렌더링
# UI_PROGRESS_BAR_LINE (동적 계산), BAR_FILLED, BAR_EMPTY 등 사용
ui_draw_progress_bar() {
  [[ "$UI_TUI_ENABLED" != true ]] && return

  local pct=$UI_CURRENT_PCT
  # zsh 배열은 1-based 인덱싱: 현재 단계(0-based) + 1 = 배열 인덱스
  local name="${ui_main_step_names[$((UI_CURRENT_MAIN_STEP + 1))]}"
  local len=40

  ((pct > 100)) && pct=100
  local fill=$((len * pct / 100))
  local emp=$((len - fill))

  # printf로 루프 대체하여 성능 최적화 (fill/emp가 0인 경우 빈 문자열 유지)
  local bar_filled="" bar_empty=""
  if (( fill > 0 )); then
    bar_filled=$(printf "${BAR_FILLED}%.0s" $(seq 1 $fill))
  fi
  if (( emp > 0 )); then
    bar_empty=$(printf "${BAR_EMPTY}%.0s" $(seq 1 $emp))
  fi

  local progress_color="${COLOR_CYAN}"
  ((pct >= 100)) && progress_color="${COLOR_GREEN}"

  # 3개 ANSI 시퀀스를 1개로 통합 (move_to_line + clear_line + clear_from_cursor)
  printf "\e[${UI_PROGRESS_BAR_LINE};0H\e[2K"
  printf "${COLOR_BOLD}${COLOR_PURPLE}${EMOJI[progress]} 전체 진행:${COLOR_RESET} ${BAR_BORDER_LEFT}${progress_color}%s${COLOR_RESET}${COLOR_DIM}%s${COLOR_RESET}${BAR_BORDER_RIGHT} ${COLOR_BOLD}${COLOR_GREEN}%3d%%${COLOR_RESET} ${COLOR_DIM}|${COLOR_RESET} %s\n" \
    "$bar_filled" "$bar_empty" "$pct" "$name"
}

# ═══════════════════════════════════════════════════════
# 5. 사용자 확인
# ═══════════════════════════════════════════════════════

# 사용자 확인 프롬프트 (while 루프 기반, 최대 3회 시도)
# 사용법: ui_confirm "진행하시겠습니까?" [Y|N]
# 반환값: 0=예, 1=아니오
# default: Y(기본 실행) 또는 N(기본 취소)
ui_confirm() {
  local prompt="$1"
  local default="${2:-Y}"  # 기본값: Y (실행)
  local max_attempts=3
  local attempts=0

  local hint="(Y/n)"
  [[ "$default" == "N" || "$default" == "n" ]] && hint="(y/N)"

  while (( attempts < max_attempts )); do
    printf "${COLOR_CYAN}${prompt} ${COLOR_DIM}${hint}${COLOR_RESET}: "
    local ans
    read ans

    # 빈 입력: 기본값 적용
    if [[ -z "$ans" ]]; then
      if [[ "$default" == "Y" || "$default" == "y" ]]; then
        return 0
      else
        return 1
      fi
    fi

    # Y/y → 실행
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      return 0
    fi

    # N/n → 취소
    if [[ "$ans" =~ ^[Nn]$ ]]; then
      return 1
    fi

    # 잘못된 입력
    (( attempts++ ))
    if (( attempts >= max_attempts )); then
      ui_echo_error "최대 입력 횟수를 초과했습니다. 작업을 취소합니다."
      return 1
    fi
    ui_echo_warn "잘못된 입력입니다. Y 또는 n을 입력하세요."
  done
}

# ═══════════════════════════════════════════════════════
# 6. 의존성 검사
# ═══════════════════════════════════════════════════════

# 외부 명령어 존재 여부 확인
# 사용법: ui_check_dependency "docker" "Docker"
# 반환값: 0=존재, 1=없음 (에러 메시지 출력)
ui_check_dependency() {
  local cmd="$1"
  local friendly_name="${2:-$cmd}"

  if ! command -v "$cmd" &>/dev/null; then
    ui_echo_error "${friendly_name}이(가) 설치되어 있지 않습니다. 스크립트를 종료합니다."
    return 1
  fi
  return 0
}

# ═══════════════════════════════════════════════════════
# 7. 신호 처리 및 정리
# ═══════════════════════════════════════════════════════

# 터미널 상태 복원 및 정리
# 커서를 다시 보이게 하고 진행 바 아래로 커서 이동
ui_cleanup() {
  ui_show_cursor
  if [[ "$UI_TUI_ENABLED" == true ]]; then
    ui_move_to_line $((UI_PROGRESS_BAR_LINE + 2))
  fi
}

# 트랩 설정 (EXIT, INT, TERM, HUP 시 cleanup 실행)
# 사용법: ui_setup_traps 또는 ui_setup_traps "custom_cleanup_func"
ui_setup_traps() {
  local cleanup_func="${1:-ui_cleanup}"
  trap "$cleanup_func" EXIT INT TERM HUP
}

# ═══════════════════════════════════════════════════════
# 8. 유틸리티 함수
# ═══════════════════════════════════════════════════════

# 로그 디렉토리 생성 및 검증
# 사용법: ui_init_log_file "script_name"
# 결과: UI_LOG_FILE 글로벌 변수에 로그 파일 경로 설정
ui_init_log_file() {
  local script_name="$1"
  local timestamp=$(date +%Y%m%d_%H%M%S)

  if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
    ui_echo_error "로그 디렉토리 생성 실패: $LOG_DIR"
    return 1
  fi
  if [[ ! -w "$LOG_DIR" ]]; then
    ui_echo_error "로그 디렉토리에 쓰기 권한이 없습니다: $LOG_DIR"
    return 1
  fi

  UI_LOG_FILE="$LOG_DIR/${script_name}_${timestamp}.log"
}

# 명령어 실행 및 로그 기록
# 사용법: ui_run_and_log <명령어> [인자...]
# 출력은 로그 파일로, 반환값은 명령어 종료 코드
ui_run_and_log() {
  if [[ -n "$UI_LOG_FILE" ]]; then
    echo "$(date "+${LOG_FORMAT}") - $*" >> "$UI_LOG_FILE"
    "$@" >> "$UI_LOG_FILE" 2>&1
  else
    "$@" >/dev/null 2>&1
  fi
  return $?
}

# 명령어 실행 및 로그 기록 (LANG=C 환경)
# Homebrew 등 로케일 영향을 받는 명령어용
# 사용법: ui_log_cmd <명령어> [인자...]
ui_log_cmd() {
  if [[ -n "$UI_LOG_FILE" ]]; then
    echo "$(date "+${LOG_FORMAT}") - $*" >> "$UI_LOG_FILE"
    LANG=C LC_ALL=C "$@" >> "$UI_LOG_FILE" 2>&1
  else
    LANG=C LC_ALL=C "$@" >/dev/null 2>&1
  fi
  return $?
}

# 헤더 출력 (제목 박스 + 로그 파일 경로)
# 사용법: ui_print_header "제목 텍스트"
ui_print_header() {
  local title="$1"
  ui_move_to_line 1
  ui_clear_from_cursor
  ui_create_title_box "$title"
  if [[ -n "$UI_LOG_FILE" ]]; then
    echo -e "${COLOR_DIM}📁 로그 파일: ${UI_LOG_FILE}${COLOR_RESET}"
  fi
  echo
}

# 메시지 영역 리셋 (메시지 출력 위치를 초기화)
ui_reset_message_area() {
  UI_CURRENT_MESSAGE_LINE=$MESSAGE_LINE
  if [[ "$UI_TUI_ENABLED" == true ]]; then
    ui_move_to_line $MESSAGE_LINE
    ui_clear_from_cursor
  fi
}
