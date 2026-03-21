#!/bin/zsh
# ─────────────────────────────────────────────────────
# config.zsh - dev-toolkit 공유 설정
# 모든 스크립트에서 source하여 사용하는 중앙 설정 파일
# ─────────────────────────────────────────────────────

# ─── 버전 관리 ──────────────────────────────────────
DEV_TOOLKIT_VERSION="2.0.0"
typeset -A SCRIPT_VERSIONS=(
  [asdf_update]="1.2.0"
  [brew_update]="1.2.0"
  [docker_reset]="1.3.1"
  [devcontainer_setup]="1.2.0"
)

# ─── 색상 팔레트 (256색 ANSI) ──────────────────────
COLOR_RESET=$'\e[0m'
COLOR_BOLD=$'\e[1m'
COLOR_DIM=$'\e[2m'
COLOR_GREEN=$'\e[38;5;46m'
COLOR_RED=$'\e[38;5;196m'
COLOR_YELLOW=$'\e[38;5;226m'
COLOR_BLUE=$'\e[38;5;39m'
COLOR_CYAN=$'\e[38;5;51m'
COLOR_MAGENTA=$'\e[38;5;201m'
COLOR_PURPLE=$'\e[38;5;141m'
COLOR_ORANGE=$'\e[38;5;208m'
COLOR_PINK=$'\e[38;5;205m'

# ─── 진행 바 스타일 ────────────────────────────────
BAR_FILLED=$'●'
BAR_EMPTY=$'○'
BAR_BORDER_LEFT='▌'
BAR_BORDER_RIGHT='▐'

# ─── 화면 레이아웃 상수 ────────────────────────────
MESSAGE_LINE=7
MAX_MESSAGES=15
PROGRESS_BAR_LINE=25

# ─── 제목 박스 기본 폭 ─────────────────────────────
BOX_WIDTH=52

# ─── 이모지 매핑 ───────────────────────────────────
typeset -A EMOJI=(
  [asdf]="🔄"
  [homebrew]="🍺"
  [docker]="🐳"
  [devcontainer]="🛠️"
  [info]="ℹ️"
  [success]="✅"
  [warning]="⚠️"
  [error]="❌"
  [fire]="🔥"
  [party]="🎊"
  [plugin]="🔌"
  [tool]="🔧"
  [progress]="⚡"
)

# ─── 로그 설정 ──────────────────────────────────────
LOG_DIR="${HOME}/.zsh.d/logs"
LOG_FORMAT="%Y-%m-%d %H:%M:%S"
LOG_RETENTION_DAYS=7
LOG_MAX_FILES=30
LOG_MAX_SIZE_MB=100

# ─── 타임아웃/재시도 설정 ──────────────────────────
COMMAND_TIMEOUT_SECONDS=300
MAX_RETRIES=3
RETRY_DELAY_SECONDS=1

# ─── 사용자 설정 오버라이드 ────────────────────────
# config.local.zsh가 있으면 로드 (개인 설정)
local config_local="${0:A:h}/config.local.zsh"
if [[ -f "$config_local" ]]; then
  source "$config_local"
fi
