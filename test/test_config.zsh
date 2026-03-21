#!/bin/zsh
# ─────────────────────────────────────────────────────
# test_config.zsh - config.zsh 테스트
# ─────────────────────────────────────────────────────

# config.zsh 로드 (|| true: config.local.zsh 미존재 시 반환값 1 무시)
source "${LIB_DIR}/config.zsh" || true

# ─── COLOR_* 변수 존재 확인 ──────────────────────────
assert_true '[[ -n "$COLOR_RESET" ]]'   "COLOR_RESET 정의됨"
assert_true '[[ -n "$COLOR_BOLD" ]]'    "COLOR_BOLD 정의됨"
assert_true '[[ -n "$COLOR_DIM" ]]'     "COLOR_DIM 정의됨"
assert_true '[[ -n "$COLOR_GREEN" ]]'   "COLOR_GREEN 정의됨"
assert_true '[[ -n "$COLOR_RED" ]]'     "COLOR_RED 정의됨"
assert_true '[[ -n "$COLOR_YELLOW" ]]'  "COLOR_YELLOW 정의됨"
assert_true '[[ -n "$COLOR_BLUE" ]]'    "COLOR_BLUE 정의됨"
assert_true '[[ -n "$COLOR_CYAN" ]]'    "COLOR_CYAN 정의됨"
assert_true '[[ -n "$COLOR_MAGENTA" ]]' "COLOR_MAGENTA 정의됨"
assert_true '[[ -n "$COLOR_PURPLE" ]]'  "COLOR_PURPLE 정의됨"
assert_true '[[ -n "$COLOR_ORANGE" ]]'  "COLOR_ORANGE 정의됨"
assert_true '[[ -n "$COLOR_PINK" ]]'    "COLOR_PINK 정의됨"

# ─── BAR_* 변수 존재 확인 ────────────────────────────
assert_true '[[ -n "$BAR_FILLED" ]]'       "BAR_FILLED 정의됨"
assert_true '[[ -n "$BAR_EMPTY" ]]'        "BAR_EMPTY 정의됨"
assert_true '[[ -n "$BAR_BORDER_LEFT" ]]'  "BAR_BORDER_LEFT 정의됨"
assert_true '[[ -n "$BAR_BORDER_RIGHT" ]]' "BAR_BORDER_RIGHT 정의됨"

# ─── 화면 레이아웃 상수 확인 ─────────────────────────
assert_true '[[ -n "$MESSAGE_LINE" ]]'      "MESSAGE_LINE 정의됨"
assert_true '[[ -n "$MAX_MESSAGES" ]]'      "MAX_MESSAGES 정의됨"
assert_true '[[ -n "$PROGRESS_BAR_LINE" ]]' "PROGRESS_BAR_LINE 정의됨"
assert_eq "7"  "$MESSAGE_LINE"      "MESSAGE_LINE 값은 7"
assert_eq "15" "$MAX_MESSAGES"      "MAX_MESSAGES 값은 15"
assert_eq "25" "$PROGRESS_BAR_LINE" "PROGRESS_BAR_LINE 값은 25"

# ─── BOX_WIDTH 확인 ─────────────────────────────────
assert_eq "52" "$BOX_WIDTH" "BOX_WIDTH 값은 52"

# ─── EMOJI 연관 배열 확인 ────────────────────────────
assert_true '[[ ${(t)EMOJI} == "association" ]]' "EMOJI는 연관 배열"
assert_true '[[ -n "${EMOJI[info]}" ]]'          "EMOJI[info] 정의됨"
assert_true '[[ -n "${EMOJI[success]}" ]]'       "EMOJI[success] 정의됨"
assert_true '[[ -n "${EMOJI[warning]}" ]]'       "EMOJI[warning] 정의됨"
assert_true '[[ -n "${EMOJI[error]}" ]]'         "EMOJI[error] 정의됨"
assert_true '[[ -n "${EMOJI[asdf]}" ]]'          "EMOJI[asdf] 정의됨"
assert_true '[[ -n "${EMOJI[homebrew]}" ]]'      "EMOJI[homebrew] 정의됨"
assert_true '[[ -n "${EMOJI[docker]}" ]]'        "EMOJI[docker] 정의됨"

# ─── 로그 설정 확인 ─────────────────────────────────
assert_true '[[ -n "$LOG_DIR" ]]'    "LOG_DIR 정의됨"
assert_true '[[ -n "$LOG_FORMAT" ]]' "LOG_FORMAT 정의됨"
assert_eq "${HOME}/.zsh.d/logs" "$LOG_DIR" "LOG_DIR 경로 확인"
assert_eq "%Y-%m-%d %H:%M:%S" "$LOG_FORMAT" "LOG_FORMAT 형식 확인"
assert_true '[[ -n "$LOG_RETENTION_DAYS" ]]' "LOG_RETENTION_DAYS 정의됨"
assert_true '[[ -n "$LOG_MAX_FILES" ]]'      "LOG_MAX_FILES 정의됨"
assert_true '[[ -n "$LOG_MAX_SIZE_MB" ]]'    "LOG_MAX_SIZE_MB 정의됨"

# ─── SCRIPT_VERSIONS 연관 배열 확인 ─────────────────
assert_true '[[ ${(t)SCRIPT_VERSIONS} == "association" ]]' "SCRIPT_VERSIONS는 연관 배열"
assert_true '[[ -n "${SCRIPT_VERSIONS[asdf_update]}" ]]'   "SCRIPT_VERSIONS[asdf_update] 정의됨"
assert_true '[[ -n "${SCRIPT_VERSIONS[brew_update]}" ]]'   "SCRIPT_VERSIONS[brew_update] 정의됨"
assert_true '[[ -n "${SCRIPT_VERSIONS[docker_reset]}" ]]'  "SCRIPT_VERSIONS[docker_reset] 정의됨"

# ─── 타임아웃/재시도 설정 확인 ──────────────────────
assert_true '[[ -n "$COMMAND_TIMEOUT_SECONDS" ]]' "COMMAND_TIMEOUT_SECONDS 정의됨"
assert_true '[[ -n "$MAX_RETRIES" ]]'             "MAX_RETRIES 정의됨"
assert_true '[[ -n "$RETRY_DELAY_SECONDS" ]]'     "RETRY_DELAY_SECONDS 정의됨"
assert_eq "3" "$MAX_RETRIES" "MAX_RETRIES 값은 3"

# ─── DEV_TOOLKIT_VERSION 확인 ───────────────────────
assert_true '[[ -n "$DEV_TOOLKIT_VERSION" ]]' "DEV_TOOLKIT_VERSION 정의됨"
