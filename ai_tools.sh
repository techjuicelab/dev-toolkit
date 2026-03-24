#!/bin/zsh
# 파일 경로: ~/.zsh.d/ai_tools.sh
# 설명: AI 및 자동화 도구 환경변수, alias, 유틸리티 함수

# ──────────────────────────────────────────────────────────
# ai tools | AI·자동화 환경 설정 및 단축 명령어
# ──────────────────────────────────────────────────────────
#
# 사용법:
#   ai:load            - 1Password에서 API 키를 환경변수로 로드
#   ai:unload          - 로드된 API 키 환경변수 제거
#   ai:status          - 현재 로드된 키 상태 확인 (마스킹)
#   cc                 - Claude Code (skip-permissions 모드)
#   claude-setup-hooks - Claude Code hooks & skills 설치
#   n8n:health         - n8n 서버 상태 확인
#   n8n:logs           - n8n 최근 실행 로그 확인
#
# 의존성: op (1Password CLI v2)
# 시크릿 관리: 1Password Vault "AI Automation"

# ── 내부 상수 ──
readonly _AI_VAULT="AI Automation"
_AI_LOADED=0

# ── Claude Code ──
alias cc="claude --dangerously-skip-permissions"
alias claude-setup-hooks="bash /Users/techjuice/Documents/dev/ai/hooks/ai-hooks-skills-sample/install.sh"

# ── 1Password 의존성 확인 ──
function _ai_check_op {
  if ! command -v op &>/dev/null; then
    echo "[ERROR] 1Password CLI(op)가 설치되어 있지 않습니다."
    echo "  brew install --cask 1password-cli"
    return 1
  fi
  return 0
}

# ── 환경변수 마스킹 헬퍼 ──
function _ai_mask_value {
  local val="$1"
  if [[ -z "$val" ]]; then
    echo "(미설정)"
  else
    local len=${#val}
    if (( len <= 8 )); then
      echo "${val:0:2}***"
    else
      echo "${val:0:4}...${val: -4}"
    fi
  fi
}

# ── API 키 로드 (1Password → 환경변수) ──
function ai:load {
  _ai_check_op || return 1

  echo "[INFO] 1Password '$_AI_VAULT' Vault에서 시크릿을 로드합니다..."
  echo "  (Touch ID 인증이 필요할 수 있습니다)"
  echo ""

  # Z.AI
  export ZAI_API_KEY=$(op read "op://$_AI_VAULT/Z.AI/api_key" 2>/dev/null)

  # Google Gemini
  export GEMINI_API_KEY=$(op read "op://$_AI_VAULT/Google Gemini/api_key" 2>/dev/null)
  export GEMINI_API_KEY_KITCHEN=$(op read "op://$_AI_VAULT/Google Gemini/api_key_kitchen" 2>/dev/null)

  # Notion API Token
  export NOTION_API_TOKEN=$(op read "op://$_AI_VAULT/Notion/api_token" 2>/dev/null)

  # Notion Database IDs
  export NOTION_MASTER_DB_ID=$(op read "op://$_AI_VAULT/Notion/Phrasal Verb/master_db_id" 2>/dev/null)
  export NOTION_LESSONS_DB_ID=$(op read "op://$_AI_VAULT/Notion/Phrasal Verb/lessons_db_id" 2>/dev/null)

  # KidsNote DBs
  export NOTION_DB_KIDSNOTE_INBOX=$(op read "op://$_AI_VAULT/Notion/KidsNote/db_inbox" 2>/dev/null)
  export NOTION_DB_KIDSNOTE_MEDICATION=$(op read "op://$_AI_VAULT/Notion/KidsNote/db_medication" 2>/dev/null)
  export NOTION_DB_KIDSNOTE_TEMPERATURE=$(op read "op://$_AI_VAULT/Notion/KidsNote/db_temperature" 2>/dev/null)
  export NOTION_DB_KIDSNOTE_STATUS=$(op read "op://$_AI_VAULT/Notion/KidsNote/db_status" 2>/dev/null)
  export NOTION_DB_KIDSNOTE_KINDERGARTEN=$(op read "op://$_AI_VAULT/Notion/KidsNote/db_kindergarten" 2>/dev/null)
  export NOTION_DB_KIDSNOTE_HOSPITAL=$(op read "op://$_AI_VAULT/Notion/KidsNote/db_hospital" 2>/dev/null)
  export NOTION_DB_KIDSNOTE_TEACHER=$(op read "op://$_AI_VAULT/Notion/KidsNote/db_teacher" 2>/dev/null)
  export NOTION_DB_KIDSNOTE_SPECIAL=$(op read "op://$_AI_VAULT/Notion/KidsNote/db_special" 2>/dev/null)

  # Kitchen Talk DB
  export NOTION_DB_KITCHEN_INVENTORY=$(op read "op://$_AI_VAULT/Notion/Kitchen Talk/db_inventory" 2>/dev/null)

  # Meeting Notes DB
  export NOTION_DB_MEETING_NOTES=$(op read "op://$_AI_VAULT/Notion/Meeting/db_notes" 2>/dev/null)

  # Receipt DB
  export NOTION_DB_RECEIPT=$(op read "op://$_AI_VAULT/Notion/Receipt/db_receipt" 2>/dev/null)

  # PARA System DBs
  export NOTION_DB_PARA_INBOX=$(op read "op://$_AI_VAULT/Notion/PARA/db_inbox" 2>/dev/null)
  export NOTION_DB_PARA_PROJECTS=$(op read "op://$_AI_VAULT/Notion/PARA/db_projects" 2>/dev/null)
  export NOTION_DB_PARA_AREAS=$(op read "op://$_AI_VAULT/Notion/PARA/db_areas" 2>/dev/null)
  export NOTION_DB_PARA_RESOURCES=$(op read "op://$_AI_VAULT/Notion/PARA/db_resources" 2>/dev/null)
  export NOTION_DB_PARA_ARCHIVES=$(op read "op://$_AI_VAULT/Notion/PARA/db_archives" 2>/dev/null)
  export NOTION_DB_PARA_DASHBOARD=$(op read "op://$_AI_VAULT/Notion/PARA/db_dashboard" 2>/dev/null)

  # Naver Search API
  export NAVER_CLIENT_ID=$(op read "op://$_AI_VAULT/Naver Search API/client_id" 2>/dev/null)
  export NAVER_CLIENT_SECRET=$(op read "op://$_AI_VAULT/Naver Search API/client_secret" 2>/dev/null)

  # N2YO Satellite API
  export N2YO_API_KEY=$(op read "op://$_AI_VAULT/N2YO Satellite API/api_key" 2>/dev/null)

  # GitHub
  export GITHUB_TOKEN=$(op read "op://$_AI_VAULT/GitHub/token" 2>/dev/null)
  export GITHUB_WEBHOOK_SECRET=$(op read "op://$_AI_VAULT/GitHub/webhook_secret" 2>/dev/null)

  # Telegram Bots
  export TELEGRAM_BOT_TOKEN_PARA=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_para" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_KITCHEN=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_kitchen" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_PIANO=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_piano" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_RECEIPT=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_receipt" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_DASHBOARD=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_dashboard" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_MEETING=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_meeting" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_KIDSNOTE=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_kidsnote" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_ENGLISH_TUTOR=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_english_tutor" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_ANALOGY=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_analogy" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_STORY=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_story" 2>/dev/null)
  export TELEGRAM_BOT_TOKEN_WATCHDOG=$(op read "op://$_AI_VAULT/Telegram Bots/Bots/bot_token_watchdog" 2>/dev/null)
  export TELEGRAM_CHAT_ID=$(op read "op://$_AI_VAULT/Telegram Bots/Chat IDs/chat_id" 2>/dev/null)
  export TELEGRAM_CHAT_ID_KITCHEN_GROUP=$(op read "op://$_AI_VAULT/Telegram Bots/Chat IDs/chat_id_kitchen_group" 2>/dev/null)
  export TELEGRAM_CHAT_ID_ECOMMERCE_GROUP=$(op read "op://$_AI_VAULT/Telegram Bots/Chat IDs/chat_id_ecommerce_group" 2>/dev/null)

  # Shared PostgreSQL
  export SHARED_DB_HOST=$(op read "op://$_AI_VAULT/Shared PostgreSQL/host" 2>/dev/null)
  export SHARED_DB_PORT=$(op read "op://$_AI_VAULT/Shared PostgreSQL/port" 2>/dev/null)

  # n8n
  export N8N_API_KEY=$(op read "op://$_AI_VAULT/n8n/api_key" 2>/dev/null)
  export N8N_URL=$(op read "op://$_AI_VAULT/n8n/url" 2>/dev/null)

  # Groq
  export GROQ_API_KEY=$(op read "op://$_AI_VAULT/Groq/api_key" 2>/dev/null)

  _AI_LOADED=1
  echo "[OK] 환경변수 로드 완료. ai:status 로 확인하세요."
}

# ── 환경변수 제거 ──
function ai:unload {
  local vars=(
    ZAI_API_KEY
    GEMINI_API_KEY GEMINI_API_KEY_KITCHEN
    NOTION_API_TOKEN
    NOTION_MASTER_DB_ID NOTION_LESSONS_DB_ID
    NOTION_DB_KIDSNOTE_INBOX NOTION_DB_KIDSNOTE_MEDICATION
    NOTION_DB_KIDSNOTE_TEMPERATURE NOTION_DB_KIDSNOTE_STATUS
    NOTION_DB_KIDSNOTE_KINDERGARTEN NOTION_DB_KIDSNOTE_HOSPITAL
    NOTION_DB_KIDSNOTE_TEACHER NOTION_DB_KIDSNOTE_SPECIAL
    NOTION_DB_KITCHEN_INVENTORY NOTION_DB_MEETING_NOTES
    NOTION_DB_RECEIPT
    NOTION_DB_PARA_INBOX NOTION_DB_PARA_PROJECTS
    NOTION_DB_PARA_AREAS NOTION_DB_PARA_RESOURCES
    NOTION_DB_PARA_ARCHIVES NOTION_DB_PARA_DASHBOARD
    NAVER_CLIENT_ID NAVER_CLIENT_SECRET
    N2YO_API_KEY
    GITHUB_TOKEN GITHUB_WEBHOOK_SECRET
    TELEGRAM_BOT_TOKEN_PARA TELEGRAM_BOT_TOKEN_KITCHEN
    TELEGRAM_BOT_TOKEN_PIANO TELEGRAM_BOT_TOKEN_RECEIPT
    TELEGRAM_BOT_TOKEN_DASHBOARD TELEGRAM_BOT_TOKEN_MEETING
    TELEGRAM_BOT_TOKEN_KIDSNOTE TELEGRAM_BOT_TOKEN_ENGLISH_TUTOR
    TELEGRAM_BOT_TOKEN_ANALOGY TELEGRAM_BOT_TOKEN_STORY
    TELEGRAM_BOT_TOKEN_WATCHDOG
    TELEGRAM_CHAT_ID TELEGRAM_CHAT_ID_KITCHEN_GROUP
    TELEGRAM_CHAT_ID_ECOMMERCE_GROUP
    SHARED_DB_HOST SHARED_DB_PORT
    N8N_API_KEY N8N_URL
    GROQ_API_KEY
  )

  for var in "${vars[@]}"; do
    unset "$var"
  done

  _AI_LOADED=0
  echo "[OK] 모든 AI/자동화 환경변수가 제거되었습니다."
}

# ── 로드 상태 확인 ──
function ai:status {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " AI/자동화 환경변수 상태"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if (( _AI_LOADED )); then
    echo " 상태: 로드됨"
  else
    echo " 상태: 미로드 (ai:load 로 로드하세요)"
  fi
  echo ""

  local -A sections=(
    ["Z.AI"]="ZAI_API_KEY"
    ["Google Gemini"]="GEMINI_API_KEY GEMINI_API_KEY_KITCHEN"
    ["Notion"]="NOTION_API_TOKEN"
    ["Naver"]="NAVER_CLIENT_ID NAVER_CLIENT_SECRET"
    ["N2YO"]="N2YO_API_KEY"
    ["GitHub"]="GITHUB_TOKEN GITHUB_WEBHOOK_SECRET"
    ["Telegram"]="TELEGRAM_BOT_TOKEN_PARA TELEGRAM_CHAT_ID"
    ["PostgreSQL"]="SHARED_DB_HOST SHARED_DB_PORT"
    ["n8n"]="N8N_API_KEY N8N_URL"
    ["Groq"]="GROQ_API_KEY"
  )

  for section in Z.AI "Google Gemini" Notion Naver N2YO GitHub Telegram PostgreSQL n8n Groq; do
    local vars="${sections[$section]}"
    local first_var="${vars%% *}"
    local val="${(P)first_var}"
    local masked=$(_ai_mask_value "$val")
    printf "  %-16s %s\n" "$section" "$masked"
  done

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ── n8n 유틸리티 ──

# n8n 서버 상태 확인
function n8n:health {
  local url="${N8N_URL:-http://localhost:29418}"
  local response
  response=$(curl -s -o /dev/null -w "%{http_code}" "$url/healthz" 2>/dev/null)
  if [[ "$response" == "200" ]]; then
    echo "[OK] n8n 서버 정상 ($url)"
  else
    echo "[ERROR] n8n 서버 응답 없음 ($url, HTTP $response)"
    return 1
  fi
}

# n8n 최근 워크플로우 실행 로그 (최근 5건)
function n8n:logs {
  local url="${N8N_URL:-http://localhost:29418}"
  local key="${N8N_API_KEY}"
  if [[ -z "$key" ]]; then
    echo "[WARN] N8N_API_KEY가 설정되지 않았습니다. ai:load 를 먼저 실행하세요."
    return 1
  fi
  curl -s "$url/api/v1/executions?limit=5" \
    -H "X-N8N-API-KEY: $key" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "[ERROR] n8n API 호출 실패"
}
