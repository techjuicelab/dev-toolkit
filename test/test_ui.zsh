#!/bin/zsh
# ─────────────────────────────────────────────────────
# test_ui.zsh - ui-framework.zsh 테스트
# ─────────────────────────────────────────────────────

# ui-framework.zsh 로드 (config.zsh도 자동 로드됨)
source "${LIB_DIR}/ui-framework.zsh" || true

# ─── UI_TUI_ENABLED 플래그 확인 ─────────────────────
assert_true '[[ -n "$UI_TUI_ENABLED" ]]' "UI_TUI_ENABLED 변수 존재"
assert_true '[[ "$UI_TUI_ENABLED" == true || "$UI_TUI_ENABLED" == false ]]' \
  "UI_TUI_ENABLED 값은 true 또는 false"

# ─── ui_create_title_box 출력 테스트 ─────────────────
local box_output=$(ui_create_title_box "테스트 제목")
assert_true '[[ -n "$box_output" ]]' "ui_create_title_box 출력 생성됨"
assert_true '[[ "$box_output" == *"╔"* ]]' "ui_create_title_box 출력에 ╔ 포함"
assert_true '[[ "$box_output" == *"╗"* ]]' "ui_create_title_box 출력에 ╗ 포함"
assert_true '[[ "$box_output" == *"╚"* ]]' "ui_create_title_box 출력에 ╚ 포함"
assert_true '[[ "$box_output" == *"╝"* ]]' "ui_create_title_box 출력에 ╝ 포함"
assert_true '[[ "$box_output" == *"║"* ]]' "ui_create_title_box 출력에 ║ 포함"
assert_true '[[ "$box_output" == *"═"* ]]' "ui_create_title_box 출력에 ═ 포함"
assert_true '[[ "$box_output" == *"테스트 제목"* ]]' "ui_create_title_box 출력에 제목 텍스트 포함"

# 커스텀 폭 테스트
local box_wide=$(ui_create_title_box "Wide" 60)
assert_true '[[ -n "$box_wide" ]]' "ui_create_title_box 커스텀 폭 출력 생성됨"

# ─── ui_echo_info 출력 테스트 ────────────────────────
local info_output=$(ui_echo_info "정보 메시지" 2>&1)
assert_true '[[ -n "$info_output" ]]' "ui_echo_info 출력 생성됨"
assert_true '[[ "$info_output" == *"INFO"* ]]' "ui_echo_info 출력에 INFO 포함"

# ─── ui_echo_success 출력 테스트 ─────────────────────
local success_output=$(ui_echo_success "성공 메시지" 2>&1)
assert_true '[[ -n "$success_output" ]]' "ui_echo_success 출력 생성됨"
assert_true '[[ "$success_output" == *"OK"* ]]' "ui_echo_success 출력에 OK 포함"

# ─── ui_echo_warn 출력 테스트 ────────────────────────
local warn_output=$(ui_echo_warn "경고 메시지" 2>&1)
assert_true '[[ -n "$warn_output" ]]' "ui_echo_warn 출력 생성됨"
assert_true '[[ "$warn_output" == *"WARN"* ]]' "ui_echo_warn 출력에 WARN 포함"

# ─── ui_echo_error 출력 테스트 ───────────────────────
local error_output=$(ui_echo_error "오류 메시지" 2>&1)
assert_true '[[ -n "$error_output" ]]' "ui_echo_error 출력 생성됨"
assert_true '[[ "$error_output" == *"ERROR"* ]]' "ui_echo_error 출력에 ERROR 포함"

# ─── ui_check_dependency 테스트 ──────────────────────
# 존재하는 명령어 (zsh)
ui_check_dependency "zsh" "Zsh" 2>/dev/null
assert_true '[[ $? -eq 0 ]]' "ui_check_dependency: zsh 존재 감지"

# 존재하지 않는 명령어
ui_check_dependency "nonexistent_cmd_12345" "NonExistent" >/dev/null 2>&1
local dep_rc=$?
assert_true "[[ $dep_rc -ne 0 ]]" "ui_check_dependency: 존재하지 않는 명령어 감지"

# ─── UI 글로벌 상태 변수 확인 ────────────────────────
assert_true '[[ -n "$UI_CURRENT_MESSAGE_LINE" ]]' "UI_CURRENT_MESSAGE_LINE 정의됨"
assert_true '[[ -n "$UI_CURRENT_PCT" ]]'           "UI_CURRENT_PCT 정의됨"
assert_eq "0" "$UI_CURRENT_PCT" "UI_CURRENT_PCT 초기값은 0"

# ─── ui_add_message 로그 파일 기록 테스트 ────────────
local test_tmpdir=$(mktemp -d)
local test_log="${test_tmpdir}/ui_test.log"
touch "$test_log"

ui_add_message "" "테스트 로그 메시지" "$test_log" >/dev/null 2>&1
if [[ -f "$test_log" ]]; then
  local log_content=$(cat "$test_log")
  assert_true '[[ "$log_content" == *"테스트 로그 메시지"* ]]' "ui_add_message 로그 파일에 메시지 기록"
fi

# 정리
rm -rf "$test_tmpdir"
