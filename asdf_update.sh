#!/bin/zsh
# 파일 경로: ~/.zsh.d/asdf_update.sh
# 설명: asdf-vm으로 관리되는 모든 플러그인과 도구를 최신 버전으로 업데이트합니다.

# ──────────────────────────────────────────────────────────
# asdf:update | asdf-vm 플러그인 및 도구 자동 업데이트
# ──────────────────────────────────────────────────────────
asdf:update() {
  # 스크립트 버전 정보
  local VERSION="1.4.0" # 병렬 버전 조회 추가

  # --version 또는 -v 플래그가 입력되면 버전 정보 출력 후 종료
  if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "asdf:update version $VERSION"
    return 0
  elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << 'EOF'
사용법: asdf:update [옵션]

옵션:
  --help, -h      이 도움말을 표시합니다
  --version, -v   버전 정보를 표시합니다

설명:
  ASDF로 관리되는 모든 플러그인과 도구를 최신 버전으로 업데이트합니다.
  이 스크립트는 '플러그인'과 '도구'만 업데이트합니다.
  asdf 자체는 먼저 수동으로 업데이트해주세요.
EOF
    return 0
  fi

  # ─── 공유 라이브러리 로드 ─────────────────────────────
  local LIB_DIR="${0:A:h}/lib"
  if [[ ! -d "$LIB_DIR" ]]; then
    LIB_DIR="${HOME}/.zsh.d/lib"
  fi
  source "${LIB_DIR}/ui-framework.zsh" || { echo "ERROR: ui-framework.zsh 로드 실패"; return 1; }
  source "${LIB_DIR}/helpers.zsh" || { echo "ERROR: helpers.zsh 로드 실패"; return 1; }

  # ─── 의존성 확인 ──────────────────────────────────────
  ui_check_dependency "asdf" "asdf" || return 1

  # ─── 로깅 초기화 ─────────────────────────────────────
  local log_file
  log_file=$(helpers_init_logging "asdf_update") || return 1
  UI_LOG_FILE="$log_file"

  # ─── 진행 단계 동적 계산 ──────────────────────────────
  local plugins; plugins=($(asdf plugin list 2>/dev/null))
  local total_plugins=${#plugins[@]}

  ui_main_step_names=("🔌 플러그인 업데이트")
  ui_main_step_weights=(20)

  local tool_weight=$((80 / (total_plugins > 0 ? total_plugins : 1)))
  for plugin in "${plugins[@]}"; do
    ui_main_step_names+=("🔧 $plugin 도구 업데이트")
    ui_main_step_weights+=($tool_weight)
  done

  # ─── 트랩 설정 ───────────────────────────────────────
  ui_setup_traps

  # ─── 화면 초기화 및 헤더 출력 ─────────────────────────
  ui_clear_screen; ui_hide_cursor
  ui_print_header "🔄 asdf-vm 업데이트 by TechJuiceLab v${VERSION}"
  ui_update_progress 0 0

  # asdf 수동 업데이트 확인
  ui_echo_warn "이 스크립트는 '플러그인'과 '도구'만 업데이트합니다."
  ui_echo_warn "asdf '자체'는 먼저 수동으로 업데이트해주세요. (예: brew upgrade asdf)"
  ui_move_to_line $UI_CURRENT_MESSAGE_LINE
  printf "asdf 자체 업데이트를 완료하셨습니까? (Y/n): "
  read ans

  if [[ "$ans" =~ ^[nN]$ ]]; then
    ui_echo_error "스크립트를 종료합니다. asdf를 먼저 업데이트해주세요."
    return 1
  fi
  echo # 줄바꿈

  ui_reset_message_area

  # 플러그인이 없으면 안내 메시지 출력 후 종료
  if [[ ${#plugins[@]} -eq 0 ]]; then
    ui_echo_warn "설치된 asdf 플러그인이 없습니다."
    ui_echo_info "플러그인 추가: asdf plugin add <plugin-name>"
    ui_show_cursor
    return 0
  fi

  ui_echo_info "asdf 플러그인 및 도구 업데이트를 시작합니다..."

  # ─── 1. 모든 플러그인 업데이트 (Step 0) ────────────────
  ui_set_current_step 0
  ui_echo_info "▶️ 모든 플러그인 업데이트 중..."
  if helpers_run_and_log "$log_file" asdf plugin update --all; then
    ui_echo_success "  - 모든 플러그인이 최신 버전입니다."
  else
    ui_echo_error "  - 일부 플러그인 업데이트에 실패했습니다. 로그를 확인하세요."
  fi
  ui_update_progress $UI_CURRENT_MAIN_STEP 100
  sleep 1

  # ─── 2. 병렬 최신 버전 조회 ─────────────────────────────
  ui_echo_info "플러그인 최신 버전 조회 중... (병렬 처리)"
  local tmp_dir=$(mktemp -d)
  local max_parallel=4
  local running=0

  for plugin in "${plugins[@]}"; do
    {
      local ver=$(asdf latest "$plugin" 2>/dev/null)
      echo "$ver" > "$tmp_dir/$plugin"
    } &
    ((running++))
    if (( running >= max_parallel )); then
      wait -n 2>/dev/null || wait
      ((running--))
    fi
  done
  wait  # 모든 백그라운드 작업 완료 대기
  ui_echo_success "최신 버전 조회 완료."

  # ─── 3. 각 도구 순차 업데이트 (Step 1-N) ───────────────
  local plugin_index=1
  for plugin in "${plugins[@]}"; do
    ui_set_current_step $plugin_index
    ui_echo_info "▶️ '${plugin}' 확인 중..."

    local current_version; current_version=$(asdf current "$plugin" 2>/dev/null | awk '{print $2}')

    if [[ -z "$current_version" || "$current_version" == "system" || "$current_version" == "Version" ]]; then
      ui_echo_warn "  - '$plugin'에 설정된 버전이 없거나 잘못되었습니다. 건너뜁니다."
    else
      local latest_version=""
      if [[ -f "$tmp_dir/$plugin" ]]; then
        latest_version=$(cat "$tmp_dir/$plugin")
      fi
      if [[ -z "$latest_version" ]]; then
        ui_echo_warn "  - '$plugin' 최신 버전 조회에 실패했습니다. 건너뜁니다."
      elif [[ "$current_version" == "$latest_version" ]]; then
        ui_echo_success "  - '$plugin'은(는) 이미 최신 버전($current_version)입니다."
      else
        ui_echo_info "  - '$plugin' 업데이트 필요: ${current_version} -> ${latest_version}"
        ui_echo_info "  - 설치를 시작합니다... (자세한 내용은 로그 파일 참조)"
        if helpers_run_and_log "$log_file" asdf install "$plugin" "$latest_version"; then
          ui_echo_info "  - 버전을 설정합니다..."
          if helpers_run_and_log "$log_file" asdf set "$plugin" "$latest_version"; then
            ui_echo_success "  - '$plugin'이(가) ${latest_version} 버전으로 업데이트되었습니다."
          else
            ui_echo_error "  - '$plugin' v${latest_version} 설정에 실패했습니다."
          fi
        else
          ui_echo_error "  - '$plugin' v${latest_version} 설치에 실패했습니다."
        fi
      fi
    fi
    ui_update_progress $UI_CURRENT_MAIN_STEP 100
    plugin_index=$((plugin_index + 1))
    sleep 0.5
  done

  # 임시 디렉토리 정리
  rm -rf "$tmp_dir"

  # ─── 완료 ────────────────────────────────────────────
  UI_CURRENT_PCT=100
  ui_draw_progress_bar
  ui_move_to_line $((PROGRESS_BAR_LINE + 2))
  ui_echo_success "🎊 asdf-vm 업데이트 완료!"
  ui_echo_info "자세한 로그는 다음 파일에서 확인하세요: $log_file"
}
