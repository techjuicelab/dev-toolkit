#!/bin/zsh
# 파일 경로: ~/.zsh.d/brew_update.sh
# 설명: Homebrew Formulae, Cask 및 Mac App Store 앱을 한번에 업데이트합니다.

# ──────────────────────────────────────────────────────────
# brew:update | Homebrew & App Store 전체 업데이트
# ──────────────────────────────────────────────────────────
brew:update() {
  # 스크립트 버전 정보
  local VERSION="1.3.0"

  # --version 또는 -v 플래그가 입력되면 버전 정보 출력 후 종료
  if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "brew:update version $VERSION"
    return 0
  elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << 'EOF'
사용법: brew:update [옵션]

옵션:
  --help, -h      이 도움말을 표시합니다
  --version, -v   버전 정보를 표시합니다

설명:
  Homebrew Formulae, Cask, Mac App Store 앱을 통합 업데이트합니다.
EOF
    return 0
  fi

  # ─── 공유 라이브러리 로드 ──────────────────────────────
  local LIB_DIR="${0:A:h}/lib"
  if [[ ! -d "$LIB_DIR" ]]; then
    LIB_DIR="${HOME}/.zsh.d/lib"
  fi
  source "${LIB_DIR}/ui-framework.zsh" || { echo "ERROR: ui-framework.zsh 로드 실패"; return 1; }
  source "${LIB_DIR}/helpers.zsh" || { echo "ERROR: helpers.zsh 로드 실패"; return 1; }

  # ─── 로그 초기화 ──────────────────────────────────────
  ui_init_log_file "brew_update" || return 1

  # ─── 진행 단계 정의 ───────────────────────────────────
  ui_main_step_names=("📚 레포지토리 갱신" "⬆️ Formulae 업그레이드" "📦 Cask 목록 확인" "🔄 Cask 업그레이드" "📱 App Store 업데이트")
  ui_main_step_weights=(15 25 10 40 10)

  # ─── 메인 로직 ────────────────────────────────────────
  main() {
    ui_setup_traps
    ui_clear_screen; ui_hide_cursor
    ui_print_header "${EMOJI[homebrew]} Homebrew 업데이트 by TechJuiceLab v${VERSION}"

    # 실행 확인
    ui_show_cursor
    if ! ui_confirm "❓ Homebrew 업데이트를 시작하시겠습니까?"; then
      ui_echo_warn "업데이트가 취소되었습니다."
      return 1
    fi
    ui_hide_cursor

    ui_update_progress 0 0

    # Step 0: Repository Update
    ui_set_current_step 0
    ui_echo_info "▶️ Homebrew 레포지토리 갱신 중..."
    if ui_log_cmd brew update; then
      ui_echo_success "  - brew update 성공"
    else
      ui_echo_error "  - brew update 실패"
    fi
    ui_update_progress $UI_CURRENT_MAIN_STEP 100

    # Step 1: Formulae Upgrade
    ui_set_current_step 1
    ui_echo_info "▶️ 일반 패키지(Formulae) 업그레이드 중..."
    if ui_log_cmd brew upgrade; then
      ui_echo_success "  - Formulae 업그레이드 완료"
    else
      ui_echo_warn "  - Formulae 업그레이드 중 오류 발생"
    fi
    ui_update_progress $UI_CURRENT_MAIN_STEP 100

    # Step 2: Cask List Check
    ui_set_current_step 2
    ui_echo_info "▶️ Cask로 설치된 앱 목록 확인 중..."
    local -a cask_list
    cask_list=($(brew list --cask))
    ui_echo_success "  - Cask 목록 확인 완료 (${#cask_list[@]}개 앱)"
    ui_update_progress $UI_CURRENT_MAIN_STEP 100

    # Step 3: Cask Upgrade
    ui_set_current_step 3
    ui_echo_info "▶️ Cask 앱 상태 점검 및 업그레이드:"
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

      ui_echo_info "  • $cask - 현재: $current, 최신: $newest"

      if [[ "$current" != "$newest" ]]; then
        ui_echo_info "    ⇒ 업데이트 필요 (업그레이드 중...)"
        if ui_log_cmd brew upgrade --cask "$cask"; then
          ui_echo_success "    ${EMOJI[success]} $cask 업그레이드 성공 (→ $newest)"
        else
          ui_echo_warn "    ${EMOJI[warning]} $cask 업그레이드 실패"
        fi
      else
        ui_echo_success "    ${EMOJI[success]} 최신 상태 (업데이트 불필요)"
      fi

      cask_index=$((cask_index + 1))
      ui_update_progress $UI_CURRENT_MAIN_STEP $((100 * cask_index / total_casks))
      sleep 0.1
    done
    ui_update_progress $UI_CURRENT_MAIN_STEP 100

    # Step 4: App Store Update
    ui_set_current_step 4
    ui_echo_info "▶️ Mac App Store 앱 업그레이드 (선택 단계)"
    if command -v mas &>/dev/null; then
      if ui_log_cmd mas upgrade; then
        ui_echo_success "  - mas(App Store) 앱 업그레이드 완료"
      else
        ui_echo_warn "  - mas(App Store) 업그레이드 실패"
      fi
    else
      ui_echo_info "  - mas가 설치되어 있지 않아 생략합니다 (brew install mas 필요)"
    fi
    ui_update_progress $UI_CURRENT_MAIN_STEP 100

    # 완료
    UI_CURRENT_PCT=100
    ui_draw_progress_bar

    trap - EXIT
    ui_cleanup
    echo -e "${COLOR_GREEN}🎉 Homebrew 업데이트 완료!${COLOR_RESET}"
    echo -e "${COLOR_CYAN}${EMOJI[info]}  자세한 로그는 다음 파일에서 확인하세요: ${UI_LOG_FILE}${COLOR_RESET}"
  }

  # 함수가 호출되면 main 함수를 실행
  main
}
