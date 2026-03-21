#!/bin/zsh
# ─────────────────────────────────────────────────────
# run_tests.zsh - dev-toolkit 테스트 러너
# 사용법: zsh test/run_tests.zsh
# ─────────────────────────────────────────────────────

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
LIB_DIR="${PROJECT_DIR}/lib"
PASS=0
FAIL=0
TOTAL=0

# 색상
GREEN=$'\e[32m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
RESET=$'\e[0m'

# config.local.zsh가 없으면 임시 생성 (config.zsh의 반환값 1 방지)
_CONFIG_LOCAL_CREATED=false
if [[ ! -f "${LIB_DIR}/config.local.zsh" ]]; then
  touch "${LIB_DIR}/config.local.zsh"
  _CONFIG_LOCAL_CREATED=true
fi

assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  ((TOTAL++))
  if [[ "$expected" == "$actual" ]]; then
    ((PASS++))
    echo "  ${GREEN}✅ PASS${RESET}: $msg"
  else
    ((FAIL++))
    echo "  ${RED}❌ FAIL${RESET}: $msg"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
  fi
}

assert_true() {
  local condition="$1" msg="$2"
  ((TOTAL++))
  if eval "$condition"; then
    ((PASS++))
    echo "  ${GREEN}✅ PASS${RESET}: $msg"
  else
    ((FAIL++))
    echo "  ${RED}❌ FAIL${RESET}: $msg"
  fi
}

assert_file_exists() {
  local file="$1" msg="$2"
  ((TOTAL++))
  if [[ -f "$file" ]]; then
    ((PASS++))
    echo "  ${GREEN}✅ PASS${RESET}: $msg"
  else
    ((FAIL++))
    echo "  ${RED}❌ FAIL${RESET}: $msg - 파일 없음: $file"
  fi
}

echo "═══════════════════════════════════════════════"
echo " dev-toolkit 테스트 스위트"
echo "═══════════════════════════════════════════════"
echo

# Run test files
for test_file in "$SCRIPT_DIR"/test_*.zsh; do
  if [[ -f "$test_file" ]]; then
    echo "${YELLOW}▶ $(basename "$test_file")${RESET}"
    source "$test_file"
    echo
  fi
done

# 임시 생성한 config.local.zsh 정리
if [[ "$_CONFIG_LOCAL_CREATED" == true ]]; then
  rm -f "${LIB_DIR}/config.local.zsh"
fi

echo "═══════════════════════════════════════════════"
echo " 결과: ${GREEN}${PASS} 통과${RESET} / ${RED}${FAIL} 실패${RESET} / 총 ${TOTAL}개"
echo "═══════════════════════════════════════════════"

(( FAIL > 0 )) && exit 1
exit 0
