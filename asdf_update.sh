#!/bin/zsh
# 파일 경로: ~/.zsh.d/asdf_update.sh
# 설명: asdf-vm으로 관리되는 모든 플러그인과 도구를 최신 버전으로 업데이트합니다.

# ──────────────────────────────────────────────────────────
# asdf:update | asdf-vm 플러그인 및 도구 자동 업데이트
# ──────────────────────────────────────────────────────────
asdf:update() {
  # 스크립트 버전 정보
  local VERSION="1.2.0" # 오류 수정 후 버전 업데이트

  # --version 또는 -v 플래그가 입력되면 버전 정보 출력 후 종료
  if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "asdf:update version $VERSION"
    return 0 # 성공적으로 함수 종료
  fi

  # ─── 1. 설정 (색상, 로그, 화면 레이아웃) ─────────────────────
  # 🎨 향상된 색상 팔레트
  local reset=$'\e[0m'; local bold=$'\e[1m'; local dim=$'\e[2m'
  local green=$'\e[38;5;46m'; local red=$'\e[38;5;196m'; local yellow=$'\e[38;5;226m'
  local blue=$'\e[38;5;39m'; local cyan=$'\e[38;5;51m'; local magenta=$'\e[38;5;201m'
  local purple=$'\e[38;5;141m'; local orange=$'\e[38;5;208m'; local pink=$'\e[38;5;205m'

  # 🎯 진행 바 스타일
  local BAR_FILLED=$'●'
  local BAR_EMPTY=$'○'
  local BAR_BORDER_LEFT='▌'
  local BAR_BORDER_RIGHT='▐'

  # 로그 파일 생성 (일관성을 위해 절대 경로 사용)
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local log_dir="${HOME}/.zsh.d/logs"; mkdir -p "$log_dir"
  local log_file="$log_dir/asdf_update_$timestamp.log"

  # 화면 레이아웃 상수
  local HEADER_LINES=5
  local MESSAGE_LINE=7
  local MAX_MESSAGES=15
  local PROGRESS_BAR_LINE=25
  local CURRENT_MESSAGE_LINE=$MESSAGE_LINE
  
  # 진행 단계 동적 계산
  local plugins; plugins=($(asdf plugin list))
  local total_plugins=${#plugins[@]}
  local current_main_step=0
  
  # 동적 단계 정의 (플러그인 업데이트 + 개별 도구 업데이트)
  local -a main_step_names=("🔌 플러그인 업데이트")
  local -a main_step_weights=(20)
  
  # 개별 플러그인 단계 추가 (80%를 플러그인 수로 분할)
  local tool_weight=$((80 / (total_plugins > 0 ? total_plugins : 1)))
  for plugin in "${plugins[@]}"; do
    main_step_names+=("🔧 $plugin 도구 업데이트")
    main_step_weights+=($tool_weight)
  done

  # ─── 2. 화면 제어 및 UI 함수 ────────────────────────────────
  # 화면 제어 함수
  clear_screen() { clear; }
  hide_cursor() { printf "\e[?25l"; }
  show_cursor() { printf "\e[?25h"; }
  move_to_line() { printf "\e[${1};0H"; }
  clear_from_cursor() { printf "\e[0J"; }
  clear_line() { printf "\e[2K"; }
  
  # 스크립트 종료 시 커서 복원 및 정리
  cleanup() {
    show_cursor
    move_to_line $((PROGRESS_BAR_LINE + 2))
  }
  
  # 통일된 제목 박스 생성 함수  
  create_title_box() {
    local title="$1"
    local box_width=52  # 한글+아이콘 완벽 계산된 고정 박스 크기
    
    # 실제 터미널 표시 너비 계산
    local str_len=${#title}
    local emoji_count=$(echo "$title" | grep -oE '[🔄🐳🍺]' | wc -l | tr -d ' ')
    local hangul_count=$(echo "$title" | grep -oE '[가-힣]' | wc -l | tr -d ' ')
    local display_width=$((str_len + emoji_count + hangul_count))
    
    # 박스 내부 여백 계산 (실제 표시 너비 기준)
    local inner_padding=$((box_width - display_width - 2))
    local left_padding=$((inner_padding / 2 + 2))
    local right_padding=$((inner_padding - left_padding + 2))
    
    # 수평선 생성 (박스 크기 기준)
    local horizontal_line=""
    for ((i=0; i<box_width; i++)); do
      horizontal_line+="═"
    done
    
    # 제목 라인 생성 (실제 표시 기준 패딩)
    local title_line="║"
    for ((i=0; i<left_padding; i++)); do title_line+=" "; done
    title_line+="$title"
    for ((i=0; i<right_padding; i++)); do title_line+=" "; done
    title_line+="║"
    
    echo -e "${bold}${cyan}╔${horizontal_line}╗${reset}"
    echo -e "${bold}${cyan}${title_line}${reset}"
    echo -e "${bold}${cyan}╚${horizontal_line}╝${reset}"
  }

  # 헤더 출력
  print_header() {
    move_to_line 1
    clear_from_cursor
    create_title_box "🔄 asdf-vm 업데이트 by TechJuiceLab v${VERSION}"
    echo -e "${dim}📁 로그 파일: ${log_file}${reset}"
    echo
  }

  # 메시지 출력
  add_message() {
    local color=$1
    local message=$2
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
    if [ $CURRENT_MESSAGE_LINE -gt $((MESSAGE_LINE + MAX_MESSAGES)) ]; then
      move_to_line $MESSAGE_LINE
      clear_from_cursor
      CURRENT_MESSAGE_LINE=$MESSAGE_LINE
    fi
    move_to_line $CURRENT_MESSAGE_LINE
    clear_line
    echo -e "${color}${message}${reset}"
    CURRENT_MESSAGE_LINE=$((CURRENT_MESSAGE_LINE + 1))
  }
  echo_info() { add_message "$cyan" "ℹ️  $1"; }
  echo_success() { add_message "$green" "✅ $1"; }
  echo_warn() { add_message "$orange" "⚠️  $1"; }
  echo_error() { add_message "$red$bold" "❌ $1"; }

  # 진행률 업데이트
  update_progress() {
    local step=$1
    local prog=$2
    local cum=0
    # zsh 배열은 1-based 인덱싱
    for ((i=1;i<=step;i++)); do
      cum=$((cum+main_step_weights[i]))
    done
    local contrib=$((main_step_weights[step+1]*prog/100))
    CURRENT_PCT=$((cum+contrib))
    ((CURRENT_PCT > 100)) && CURRENT_PCT=100
    draw_progress_bar
  }

  set_current_step() {
    current_main_step=$1
    update_progress $1 0
  }

  # 명령어 실행 (출력은 로그 파일로, 성공/실패만 반환)
  run_and_log() {
    local cmd="$1"
    echo -e "\nCOMMAND: $cmd" >> "$log_file"
    eval "$cmd" >> "$log_file" 2>&1
    return $?
  }

  # 진행 바 그리기
  local CURRENT_PCT=0
  draw_progress_bar() {
    local pct=$CURRENT_PCT
    local name="${main_step_names[$((current_main_step + 1))]}"
    local len=40
    ((pct > 100)) && pct=100
    local fill=$((len*pct/100))
    local emp=$((len-fill))
    local bar_filled="" bar_empty=""
    for ((i=0; i<fill; i++)); do bar_filled+="${BAR_FILLED}"; done
    for ((i=0; i<emp; i++)); do bar_empty+="${BAR_EMPTY}"; done
    local progress_color="${cyan}"
    ((pct >= 100)) && progress_color="${green}"
    move_to_line $PROGRESS_BAR_LINE
    clear_line
    clear_from_cursor
    printf "${bold}${purple}⚡ 전체 진행:${reset} ${BAR_BORDER_LEFT}${progress_color}%s${reset}${dim}%s${reset}${BAR_BORDER_RIGHT} ${bold}${green}%3d%%${reset} ${dim}|${reset} %s\n" \
      "$bar_filled" "$bar_empty" "$pct" "$name"
  }

  # ─── 3. 메인 로직 ──────────────────────────────────────
  main() {
    # 함수 실행 중단(Ctrl+C) 시에도 cleanup 함수가 실행되도록 trap 설정
    trap cleanup EXIT

    clear_screen; hide_cursor; print_header
    update_progress 0 0

    # asdf 수동 업데이트 확인
    echo_warn "이 스크립트는 '플러그인'과 '도구'만 업데이트합니다."
    echo_warn "asdf '자체'는 먼저 수동으로 업데이트해주세요. (예: brew upgrade asdf)"
    move_to_line $CURRENT_MESSAGE_LINE
    printf "asdf 자체 업데이트를 완료하셨습니까? (Y/n): "
    read ans

    # 기본값을 Y로 설정 (빈 입력 또는 Y/y는 실행, n/N만 종료)
    if [[ "$ans" =~ ^[nN]$ ]]; then
      echo_error "스크립트를 종료합니다. asdf를 먼저 업데이트해주세요."
      return 1 # 함수 실패 종료
    fi
    echo # 줄바꿈

    CURRENT_MESSAGE_LINE=$MESSAGE_LINE
    move_to_line $MESSAGE_LINE; clear_from_cursor

    echo_info "asdf 플러그인 및 도구 업데이트를 시작합니다..."

    # 1. 모든 플러그인 업데이트 (Step 0)
    set_current_step 0
    echo_info "▶️ 모든 플러그인 업데이트 중..."
    if run_and_log "asdf plugin update --all"; then
      echo_success "  - 모든 플러그인이 최신 버전입니다."
    else
      echo_error "  - 일부 플러그인 업데이트에 실패했습니다. 로그를 확인하세요."
    fi
    update_progress $current_main_step 100
    sleep 1

    # 2. 각 도구 업데이트 (Step 1-N)
    local plugin_index=1
    for plugin in "${plugins[@]}"; do
      set_current_step $plugin_index
      echo_info "▶️ '${plugin}' 확인 중..."

      local current_version; current_version=$(asdf current "$plugin" 2>/dev/null | awk '{print $2}')

      if [[ -z "$current_version" || "$current_version" == "system" || "$current_version" == "Version" ]]; then
        echo_warn "  - '$plugin'에 설정된 버전이 없거나 잘못되었습니다. 건너뜁니다."
      else
        local latest_version; latest_version=$(asdf latest "$plugin")
        if [[ "$current_version" == "$latest_version" ]]; then
          echo_success "  - '$plugin'은(는) 이미 최신 버전($current_version)입니다."
        else
          echo_info "  - '$plugin' 업데이트 필요: ${current_version} -> ${latest_version}"
          echo_info "  - 설치를 시작합니다... (자세한 내용은 로그 파일 참조)"
          if run_and_log "asdf install '$plugin' '$latest_version'"; then
            echo_info "  - 버전을 설정합니다..."
            if run_and_log "asdf set '$plugin' '$latest_version'"; then
              echo_success "  - '$plugin'이(가) ${latest_version} 버전으로 업데이트되었습니다."
            else
              echo_error "  - '$plugin' v${latest_version} 설정에 실패했습니다."
            fi
          else
            echo_error "  - '$plugin' v${latest_version} 설치에 실패했습니다."
          fi
        fi
      fi
      update_progress $current_main_step 100
      plugin_index=$((plugin_index + 1))
      sleep 0.5
    done
    
    # 완료 시 진행률 업데이트 및 유지
    CURRENT_PCT=100
    draw_progress_bar
    move_to_line $((PROGRESS_BAR_LINE + 2))
    echo_success "🎊 asdf-vm 업데이트 완료!"
    echo_info "자세한 로그는 다음 파일에서 확인하세요: $log_file"
  }

  # ─── 4. 스크립트 실행 ───────────────────────────────────
  # asdf 명령어가 없으면 함수 종료
  if ! command -v asdf &>/dev/null; then
    echo -e "${red}${bold}🔥 asdf가 설치되어 있지 않습니다. 스크립트를 종료합니다.${reset}"
    return 1
  fi
  
  # 함수가 호출되면 main 함수를 실행
  main
}
