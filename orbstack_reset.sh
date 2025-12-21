#!/bin/zsh
# 파일 경로: ~/.zsh.d/orbstack_reset.sh
# 설명: OrbStack의 모든 컨테이너, 이미지, 볼륨, 네트워크를 초기화합니다.

# ──────────────────────────────────────────────────────────
# orbstack:reset | OrbStack Factory Reset
# ──────────────────────────────────────────────────────────
orbstack:reset() {
  # 스크립트 버전 정보
  local VERSION="1.0.1"

  # --version 또는 -v 플래그가 입력되면 버전 정보 출력 후 종료
  if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "orbstack:reset version $VERSION"
    return 0 # 성공적으로 함수 종료
  fi

  # 🎨 향상된 색상 팔레트 ─────────
  local reset=$'\e[0m'; local bold=$'\e[1m'; local dim=$'\e[2m'
  local green=$'\e[38;5;46m'; local red=$'\e[38;5;196m'; local yellow=$'\e[38;5;226m'
  local blue=$'\e[38;5;39m'; local cyan=$'\e[38;5;51m'; local magenta=$'\e[38;5;201m'
  local purple=$'\e[38;5;141m'; local orange=$'\e[38;5;208m'; local pink=$'\e[38;5;205m'

  # 🎯 진행 바 스타일 ────────────
  local BAR_FILLED=$'●'
  local BAR_EMPTY=$'○'
  local BAR_BORDER_LEFT='▌'
  local BAR_BORDER_RIGHT='▐'

  # ─── 로그 파일 생성 ────────────────
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local log_dir="${HOME}/.zsh.d/logs"; mkdir -p "$log_dir"
  local log_file="$log_dir/orbstack_reset_$timestamp.log"

  # ─── 화면 제어 함수 ─────────────
  clear_screen() { clear; }
  hide_cursor() { printf "\e[?25l"; }
  show_cursor() { printf "\e[?25h"; }
  move_to_line() { printf "\e[${1};0H"; }
  clear_from_cursor() { printf "\e[0J"; }
  clear_line() { printf "\e[2K"; }

  # ─── 화면 레이아웃 상수 ───────────
  local HEADER_LINES=5
  local MESSAGE_LINE=7
  local MAX_MESSAGES=15
  local PROGRESS_BAR_LINE=25
  local CURRENT_MESSAGE_LINE=$MESSAGE_LINE

  # ─── 진행 단계 정의 ────────────────
  local current_main_step=0
  local -a main_step_names=("🚀 초기화" "⏸️ 컨테이너 종료" "🗑️ 컨테이너 삭제" "📦 이미지 삭제" "💾 볼륨 삭제" "🌐 네트워크 삭제" "🧹 캐시 정리" "✅ 검증")
  local -a main_step_weights=(5 10 15 20 20 10 15 5)

  # ─── 메시지 정의 ─────────────────
  local MSG_TITLE="OrbStack Factory Reset by TechJuiceLab v${VERSION}"
  local MSG_WARNING="🚨 이 스크립트는 OrbStack의 모든 데이터를 완전히 삭제합니다!"
  local MSG_PROMPT="진행하시겠습니까? (Y/n): "
  local MSG_CANCELED="취소되었습니다."
  local MSG_COMPLETE="🎉 OrbStack Factory Reset 완료!"
  local MSG_LOG_FILE="로그 파일:"
  local MSG_OVERALL_PROGRESS="전체 진행 상황:"
  local MSG_CURRENT_STAGE="현재 단계"

  # ─── 통일된 제목 박스 함수 ──────────
  print_title_box() {
    local title="$1"
    local box_width=56  # OrbStack 제목에 맞게 조정

    # 실제 터미널 표시 너비 계산
    local str_len=${#title}
    local emoji_count=$(echo "$title" | grep -oE '[🔄🐳🍺🚀]' | wc -l | tr -d ' ')
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

  # ─── 헤더 출력 ───────────────────
  print_header() {
    move_to_line 1
    clear_from_cursor
    print_title_box "$MSG_TITLE"
    echo -e "${dim}📁 로그 파일: ${log_file}${reset}"
    echo
  }

  # ─── 메시지 출력 ───────────────────
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

  # ─── 진행 바 그리기 ───────────────
  local CURRENT_PCT=0
  draw_progress_bar() {
    local pct=$CURRENT_PCT
    local name="${main_step_names[$current_main_step]}"
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
    printf "${bold}${purple}⚡ 전체 진행:${reset} ${BAR_BORDER_LEFT}${progress_color}%s${reset}${dim}%s${reset}${BAR_BORDER_RIGHT} ${bold}${green}%3d%%${reset} ${dim}|${reset} %s\n" \
      "$bar_filled" "$bar_empty" "$pct" "$name"
  }

  # ─── 진행률 업데이트 ─────────────
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

  # ─── 명령 실행 및 로깅 ───────────
  log_cmd() {
    local cmd="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $cmd" >> "$log_file"
    LANG=C LC_ALL=C eval "$cmd" >> "$log_file" 2>&1
    return ${PIPESTATUS[0]}
  }

  # ─── 강화된 삭제 작업 (재시도 + 에러 처리) ──────────────────
  delete_with_progress() {
    local -a ids failed_ids
    local cmd=$2
    local act=$3
    local max_retries=3

    while IFS= read -r l; do [[ -n "$l" ]] && ids+=("$l"); done <<< "$1"
    if (( ${#ids[@]} == 0 )); then
      echo_success "  - $act 대상 없음"
      update_progress $current_main_step 100
      return
    fi

    echo_info "▶️ $act (${#ids[@]})"
    local total=${#ids[@]}

    # 첫 번째 시도
    for ((i=1; i<=total; i++)); do
      if ! log_cmd "$cmd ${ids[i]}"; then
        failed_ids+=("${ids[i]}")
        echo_warn "    - ${ids[i]} 삭제 실패, 재시도 예정"
      fi
      update_progress $current_main_step $((100*i/total))
      sleep 0.05
    done

    # 실패한 항목 재시도
    for ((retry=1; retry<=max_retries && ${#failed_ids[@]}>0; retry++)); do
      if (( ${#failed_ids[@]} > 0 )); then
        echo_info "    - 재시도 ${retry}/${max_retries} (${#failed_ids[@]}개)"
        local temp_failed=()
        for failed_id in "${failed_ids[@]}"; do
          sleep 0.5  # Docker daemon 안정화 대기
          if ! log_cmd "$cmd $failed_id"; then
            temp_failed+=("$failed_id")
          else
            echo_info "    - $failed_id 재시도 성공 ✅"
          fi
        done
        failed_ids=("${temp_failed[@]}")
      fi
    done

    if (( ${#failed_ids[@]} > 0 )); then
      echo_warn "  - $act 부분 완료 (${#failed_ids[@]}개 실패)"
      echo_warn "    실패 목록: ${failed_ids[*]}"
    else
      echo_success "  - $act 완료"
    fi
  }

  # ─── 메인 리셋 로직 ───────────────
  run_orbstack_reset() {
    set_current_step 0; echo_info "▶️ 초기화"; update_progress $current_main_step 100; echo_success "  - 초기화 완료"
    set_current_step 1; delete_with_progress "$(docker ps -q)" "docker stop" "컨테이너 종료"
    set_current_step 2; delete_with_progress "$(docker ps -aq)" "docker rm -f" "컨테이너 삭제"
    set_current_step 3; delete_with_progress "$(docker images -q)" "docker rmi -f" "이미지 삭제"
    set_current_step 4; delete_with_progress "$(docker volume ls -q)" "docker volume rm -f" "볼륨 삭제"
    set_current_step 5; delete_with_progress "$(docker network ls --filter type=custom -q)" "docker network rm" "네트워크 삭제"
    set_current_step 6; echo_info "▶️ 캐시 정리"

    # 시스템 캐시 정리
    echo_info "    - 시스템 캐시 정리"
    log_cmd "docker system prune -af --volumes"
    update_progress $current_main_step 30

    # BuildKit 캐시 정리 (OrbStack은 기본적으로 BuildKit 사용)
    echo_info "    - BuildKit 캐시 정리"
    log_cmd "docker builder prune --all --force 2>/dev/null || true"
    update_progress $current_main_step 60

    # Buildx 캐시 정리 (OrbStack도 buildx 지원)
    echo_info "    - Buildx 캐시 정리"
    log_cmd "docker buildx prune --all --force 2>/dev/null || true"
    update_progress $current_main_step 90

    # 주의: OrbStack은 자동으로 캐시를 관리하므로 빌더 재설정 불필요
    update_progress $current_main_step 100
    echo_success "  - 전체 캐시 정리 완료"

    set_current_step 7; echo_info "▶️ 검증 & 강제 정리"
    local containers=$(docker ps -aq | wc -l)
    local images=$(docker images -q | wc -l)
    local volumes=$(docker volume ls -q | wc -l)
    local networks=$(docker network ls --filter type=custom -q | wc -l)

    log_cmd "echo 'Initial verification: containers=$containers, images=$images, volumes=$volumes, networks=$networks'"
    update_progress $current_main_step 30

    # 남은 리소스가 있으면 강제 정리 수행
    if (( containers > 0 || images > 0 || volumes > 0 || networks > 0 )); then
      echo_warn "  - 남은 리소스 감지, 강제 정리 수행"

      # 남은 컨테이너 강제 정리
      if (( containers > 0 )); then
        echo_info "    - 남은 컨테이너 강제 정리 ($containers개)"
        log_cmd "docker rm -f \$(docker ps -aq) 2>/dev/null || true"
      fi
      update_progress $current_main_step 50

      # 남은 볼륨 강제 정리
      if (( volumes > 0 )); then
        echo_info "    - 남은 볼륨 강제 정리 ($volumes개)"
        log_cmd "docker volume rm -f \$(docker volume ls -q) 2>/dev/null || true"
      fi
      update_progress $current_main_step 70

      # 남은 네트워크 강제 정리
      if (( networks > 0 )); then
        echo_info "    - 남은 네트워크 강제 정리 ($networks개)"
        log_cmd "docker network rm \$(docker network ls --filter type=custom -q) 2>/dev/null || true"
      fi
      update_progress $current_main_step 85
    fi

    # 시스템 전체 정리
    log_cmd "docker system prune -af --volumes"
    update_progress $current_main_step 95

    # 최종 검증
    local final_containers=$(docker ps -aq | wc -l)
    local final_images=$(docker images -q | wc -l)
    local final_volumes=$(docker volume ls -q | wc -l)
    local final_networks=$(docker network ls --filter type=custom -q | wc -l)

    log_cmd "echo 'Final verification: containers=$final_containers, images=$final_images, volumes=$final_volumes, networks=$final_networks'"
    update_progress $current_main_step 100

    if (( final_containers == 0 && final_images == 0 && final_volumes == 0 && final_networks == 0 )); then
      echo_success "  - 완전 정리 검증 ✅ (모든 리소스 삭제 완료)"
      echo_info "  - OrbStack 완전 초기화를 위해서는"
      echo_info "    'orb restart docker' 명령어로 재시작을 권장합니다."
    else
      echo_warn "  - 부분 정리 완료 ⚠️ (컨테이너:$final_containers, 이미지:$final_images, 볼륨:$final_volumes, 네트워크:$final_networks)"
      echo_info "  - 남은 리소스 정리를 위해 'orb restart docker' 실행을 권장합니다."
    fi
  }

  # ─── 사용자 확인 (개선된 버전) ─────
  confirm_prompt() {
    echo_warn "$MSG_WARNING"
    move_to_line $((CURRENT_MESSAGE_LINE + 1))

    local ans
    printf "${cyan}${MSG_PROMPT}${reset}"
    read ans

    # 빈 입력(엔터만) 또는 Y/y는 실행
    if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
      return 0
    # n/N만 취소
    elif [[ "$ans" =~ ^[Nn]$ ]]; then
      echo_error "$MSG_CANCELED"
      return 1
    else
      # 잘못된 입력시 다시 묻기
      echo_warn "잘못된 입력입니다. Y 또는 n을 입력하세요."
      return $(confirm_prompt)
    fi
  }

  set_current_step() {
    current_main_step=$1
    update_progress $1 0
  }

  cleanup() {
    show_cursor
    # 완료 메시지 후 적절한 위치로 커서 이동
    move_to_line $((PROGRESS_BAR_LINE + 5))
  }

  # ─── 메인 실행 함수 ───────────────
  main() {
    # Docker 명령어가 없으면 함수 종료
    if ! command -v docker &>/dev/null; then
      echo_error "Docker 또는 OrbStack이 설치되어 있지 않습니다."
      echo_info "OrbStack 설치: https://orbstack.dev"
      return 1
    fi

    # OrbStack 감지
    if command -v orbctl &>/dev/null; then
      log_cmd "echo 'OrbStack detected: $(orbctl version 2>/dev/null || echo unknown)'"
    fi

    # 트랩 설정 (스크립트 종료 시 커서 복원)
    trap cleanup EXIT

    clear_screen
    hide_cursor
    print_header
    update_progress 0 0

    if confirm_prompt; then
      echo # 줄바꿈
      run_orbstack_reset
      # 완료 시 진행률 업데이트 및 유지
      CURRENT_PCT=100
      draw_progress_bar
      move_to_line $((PROGRESS_BAR_LINE + 2))
      echo_success "$MSG_COMPLETE"
      echo_info "자세한 로그는 다음 파일에서 확인하세요: $log_file"
    fi
  }

  # 함수가 호출되면 main 함수를 실행
  main
}
