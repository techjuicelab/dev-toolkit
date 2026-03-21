#!/bin/zsh
# ─────────────────────────────────────────────────────
# test_helpers.zsh - helpers.zsh 테스트
# ─────────────────────────────────────────────────────

# helpers.zsh 로드 (config.zsh도 자동 로드됨)
source "${LIB_DIR}/helpers.zsh" || true

# 테스트용 임시 디렉토리 생성
TEST_TMPDIR=$(mktemp -d)
ORIG_LOG_DIR="$LOG_DIR"

# ─── helpers_init_logging 테스트 ─────────────────────
# LOG_DIR을 임시 디렉토리로 변경
LOG_DIR="${TEST_TMPDIR}/logs"

local log_file=$(helpers_init_logging "test_script")
assert_true '[[ $? -eq 0 ]]' "helpers_init_logging 정상 반환"
assert_file_exists "$log_file" "helpers_init_logging 로그 파일 생성됨"

# 파일 권한 확인 (600 = rw-------)
if [[ -f "$log_file" ]]; then
  local perms=$(stat -f "%Lp" "$log_file" 2>/dev/null || stat -c "%a" "$log_file" 2>/dev/null)
  assert_eq "600" "$perms" "로그 파일 권한은 600"
fi

# 파일명 패턴 확인
local log_basename=$(basename "$log_file")
assert_true '[[ "$log_basename" == test_script_*.log ]]' "로그 파일명 패턴: test_script_TIMESTAMP.log"

# ─── helpers_run_and_log 테스트 ──────────────────────
local cmd_log="${TEST_TMPDIR}/cmd_test.log"
touch "$cmd_log"

helpers_run_and_log "$cmd_log" echo "hello world"
assert_true '[[ $? -eq 0 ]]' "helpers_run_and_log 정상 반환"

local log_content=$(cat "$cmd_log")
assert_true '[[ "$log_content" == *"echo hello world"* ]]' "helpers_run_and_log 명령어가 로그에 기록됨"
assert_true '[[ "$log_content" == *"hello world"* ]]'      "helpers_run_and_log 출력이 로그에 기록됨"

# 실패하는 명령어 테스트
helpers_run_and_log "$cmd_log" false
local run_and_log_rc=$?
assert_true "[[ $run_and_log_rc -ne 0 ]]" "helpers_run_and_log 실패 명령어 반환값 전달"

# ─── helpers_rotate_logs: 빈 디렉토리 처리 테스트 ────
local empty_log_dir="${TEST_TMPDIR}/empty_logs"
mkdir -p "$empty_log_dir"
LOG_DIR="$empty_log_dir"

helpers_rotate_logs
assert_true '[[ $? -eq 0 ]]' "helpers_rotate_logs 빈 디렉토리에서 오류 없음"

# 존재하지 않는 디렉토리 처리
LOG_DIR="${TEST_TMPDIR}/nonexistent"
helpers_rotate_logs
assert_true '[[ $? -eq 0 ]]' "helpers_rotate_logs 존재하지 않는 디렉토리에서 오류 없음"

# ─── helpers_retry 테스트 ────────────────────────────
# 성공하는 명령어는 즉시 반환
helpers_retry true
assert_true '[[ $? -eq 0 ]]' "helpers_retry 성공 명령어 즉시 반환"

# 항상 실패하는 명령어는 MAX_RETRIES 후 실패 반환
# RETRY_DELAY_SECONDS를 0으로 설정하여 테스트 속도 향상
local orig_delay=$RETRY_DELAY_SECONDS
RETRY_DELAY_SECONDS=0
helpers_retry false 2>/dev/null
local retry_rc=$?
assert_true "[[ $retry_rc -ne 0 ]]" "helpers_retry 실패 명령어 최종 실패 반환"
RETRY_DELAY_SECONDS=$orig_delay

# ─── helpers_check_health 테스트 ─────────────────────
helpers_check_health 2>/dev/null
assert_true '[[ $? -eq 0 ]]' "helpers_check_health 정상 실행"

# ─── 정리 ────────────────────────────────────────────
LOG_DIR="$ORIG_LOG_DIR"
rm -rf "$TEST_TMPDIR"
