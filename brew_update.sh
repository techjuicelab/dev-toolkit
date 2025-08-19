#!/bin/zsh
# 파일 경로: ~/.zsh.d/brew_update.sh
# 설명: Homebrew Formulae, Cask 및 Mac App Store 앱을 한번에 업데이트합니다.

# ──────────────────────────────────────────────────────────
# brew:update | Homebrew & App Store 전체 업데이트
# ──────────────────────────────────────────────────────────
brew:update() {
  # 스크립트 버전 정보
  local VERSION="1.2.0"

  # --version 또는 -v 플래그가 입력되면 버전 정보 출력 후 종료
  if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "brew:update version $VERSION"
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

  # 로그 파일 생성
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local log_dir="${HOME}/.zsh.d/logs"; mkdir -p "$log_dir"
  local log_file="$log_dir/brew_update_$timestamp.log"

  # 화면 레이아웃 상수
  local HEADER_LINES=5
  local MESSAGE_LINE=7
  local MAX_MESSAGES=15
  local PROGRESS_BAR_LINE=25
  local CURRENT_MESSAGE_LINE=$MESSAGE_LINE
  
  # 고정 단계 정의
  local current_main_step=0
  local -a main_step_names=("📚 레포지토리 갱신" "⬆️ Formulae 업그레이드" "📦 Cask 목록 확인" "🔄 Cask 업그레이드" "📱 App Store 업데이트")
  local -a main_step_weights=(15 25 10 40 10)

  # ─── 2. 화면 제어 및 UI 함수 ────────────────────────────────
  # 화면 제어 함수
  clear_screen() { clear; }
  hide_cursor() { printf "\e[?25l"; }
  show_cursor() { printf "\e[?25h"; }
  move_to_line() { printf "\e[${1};0H"; }
  clear_from_cursor() { printf "\e[0J"; }
  clear_line() { printf "\e[2K"; }
  
  cleanup() {
    show_cursor
    # 완료 후에는 진행바 다음 줄로 이동 (진행바 유지)
    move_to_line $((PROGRESS_BAR_LINE + 2))
  }

  # 통일된 제목 박스 생성 함수
  create_dynamic_box() {
    local title="$1"
    local box_width=52  # 한글+아이콘 완벽 계산된 고정 박스 크기
    
    # 실제 터미널 표시 너비 계산
    local str_len=${#title}
    local emoji_count=$(echo "$title" | grep -oE '[🔄🐳🍺]' | wc -l | tr -d ' ')
    local hangul_count=$(echo "$title" | grep -oE '[가-힣]' | wc -l | tr -d ' ')
    local display_width=$((str_len + emoji_count + hangul_count))
    
    # 박스 내부 여백 계산 (실제 표시 너비 기준)
    local inner_padding=$((box_width - display_width - 2))
    local left_padding=$((inner_padding / 2 + 3))
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
    create_dynamic_box "🍺 Homebrew 업데이트 by TechJuiceLab v${VERSION}"
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

  # 실행 확인 프롬프트
  confirm_execution() {
    echo
    echo -e "${bold}${yellow}❓ Homebrew 업데이트를 시작하시겠습니까? ${reset}${dim}(Y/n)${reset}: "
    read -r response
    case "$response" in
      [Nn]* ) 
        echo -e "${orange}⚠️  업데이트가 취소되었습니다.${reset}"
        show_cursor
        return 1
        ;;
      * ) 
        echo -e "${green}✅ 업데이트를 시작합니다...${reset}"
        return 0
        ;;
    esac
  }

  # 명령 실행 및 로깅
  log_cmd() {
    local cmd="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $cmd" >> "$log_file"
    LANG=C LC_ALL=C eval "$cmd" >> "$log_file" 2>&1
    return ${PIPESTATUS[0]}
  }

  # ─── 3. 메인 로직 ──────────────────────────────────────
  main() {
    trap cleanup EXIT
    clear_screen; hide_cursor; print_header
    
    # 실행 확인
    show_cursor
    if ! confirm_execution; then
      return 1
    fi
    hide_cursor
    
    update_progress 0 0

    # Step 0: Repository Update
    set_current_step 0
    echo_info "▶️ Homebrew 레포지토리 갱신 중..."
    if log_cmd "brew update"; then
      echo_success "  - brew update 성공"
    else
      echo_error "  - brew update 실패"
    fi
    update_progress $current_main_step 100

    # Step 1: Formulae Upgrade
    set_current_step 1
    echo_info "▶️ 일반 패키지(Formulae) 업그레이드 중..."
    if log_cmd "brew upgrade"; then
      echo_success "  - Formulae 업그레이드 완료"
    else
      echo_warn "  - Formulae 업그레이드 중 오류 발생"
    fi
    update_progress $current_main_step 100

    # Step 2: Cask List Check
    set_current_step 2
    echo_info "▶️ Cask로 설치된 앱 목록 확인 중..."
    local -a cask_list
    cask_list=($(brew list --cask))
    echo_success "  - Cask 목록 확인 완료 (${#cask_list[@]}개 앱)"
    update_progress $current_main_step 100

    # Step 3: Cask Upgrade
    set_current_step 3
    echo_info "▶️ Cask 앱 상태 점검 및 업그레이드:"
    # Cask 버전 정보 수집
    typeset -A current_versions latest_versions
    while IFS= read -r line; do
      local name=${line%% *}
      local version=${line#* }
      current_versions[$name]=$version
    done < <(brew list --cask --versions)

    while IFS= read -r line; do
      local name=${line%% *}
      local rest=${line#* }
      local newest=${rest#*< }
      latest_versions[$name]=$newest
    done < <(brew outdated --cask --verbose)

    # Cask 업그레이드 처리
    local total_casks=${#cask_list[@]}
    local cask_index=0
    for cask in "${cask_list[@]}"; do
      local current=${current_versions[$cask]:-"알 수 없음"}
      local newest=${latest_versions[$cask]:-$current}

      echo_info "  • $cask - 현재: $current, 최신: $newest"

      if [[ "$current" != "$newest" ]]; then
        echo_info "    ⇒ 업데이트 필요 (업그레이드 중...)"
        if log_cmd "brew upgrade --cask $cask"; then
          echo_success "    ✅ $cask 업그레이드 성공 (→ $newest)"
        else
          echo_warn "    ⚠️ $cask 업그레이드 실패"
        fi
      else
        echo_success "    ✅ 최신 상태 (업데이트 불필요)"
      fi
      
      cask_index=$((cask_index + 1))
      update_progress $current_main_step $((100 * cask_index / total_casks))
      sleep 0.1
    done
    update_progress $current_main_step 100

    # Step 4: App Store Update
    set_current_step 4
    echo_info "▶️ Mac App Store 앱 업그레이드 (선택 단계)"
    if command -v mas &>/dev/null; then
      if log_cmd "mas upgrade"; then
        echo_success "  - mas(App Store) 앱 업그레이드 완료"
      else
        echo_warn "  - mas(App Store) 업그레이드 실패"
      fi
    else
      echo_info "  - mas가 설치되어 있지 않아 생략합니다 (brew install mas 필요)"
    fi
    update_progress $current_main_step 100
    
    # 완료 시 진행률 업데이트 및 진행바 유지
    CURRENT_PCT=100
    draw_progress_bar

    trap - EXIT
    cleanup
    echo -e "${green}🎉 Homebrew 업데이트 완료!${reset}"
    echo -e "${cyan}ℹ️  자세한 로그는 다음 파일에서 확인하세요: ${log_file}${reset}"
  }

  # 함수가 호출되면 main 함수를 실행
  main
}
