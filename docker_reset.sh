#!/bin/zsh
# 파일 경로: ~/.zsh.d/docker_reset.sh
# 설명: Docker의 모든 컨테이너, 이미지, 볼륨, 네트워크를 초기화합니다.

# ──────────────────────────────────────────────────────────
# docker:reset | Docker Factory Reset
# ──────────────────────────────────────────────────────────
docker:reset() {
  local VERSION="${SCRIPT_VERSIONS[docker_reset]:-1.3.1}"

  # ─── 공유 라이브러리 로드 ────────────
  local lib_dir="${0:A:h}/lib"
  source "${lib_dir}/ui-framework.zsh" || { echo "ERROR: ui-framework.zsh 로드 실패"; return 1; }
  source "${lib_dir}/helpers.zsh" || { echo "ERROR: helpers.zsh 로드 실패"; return 1; }

  # --version 또는 -v 플래그가 입력되면 버전 정보 출력 후 종료
  if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "docker:reset version $VERSION"
    return 0
  elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << 'EOF'
사용법: docker:reset [옵션]

옵션:
  --help, -h      이 도움말을 표시합니다
  --version, -v   버전 정보를 표시합니다

설명:
  Docker 컨테이너, 이미지, 볼륨, 네트워크를 완전히 초기화합니다.
  ⚠️  이 작업은 되돌릴 수 없습니다.
EOF
    return 0
  fi

  # ─── 로그 초기화 ────────────────────
  ui_init_log_file "docker_reset" || return 1

  # ─── 진행 단계 정의 ────────────────
  ui_main_step_names=("🚀 초기화" "⏸️ 컨테이너 종료" "🗑️ 컨테이너 삭제" "📦 이미지 삭제" "💾 볼륨 삭제" "🌐 네트워크 삭제" "🧹 캐시 정리" "✅ 검증")
  ui_main_step_weights=(5 10 15 20 20 10 15 5)

  # ─── 메시지 정의 ─────────────────
  local MSG_TITLE="Docker Factory Reset by TechJuiceLab v${VERSION}"
  local MSG_WARNING="🚨 이 스크립트는 Docker의 모든 데이터를 완전히 삭제합니다!"
  local MSG_COMPLETE="🎉 Docker Factory Reset 완료!"

  # ─── 강화된 삭제 작업 (재시도 + 에러 처리) ──────────────────
  delete_with_progress() {
    local -a ids failed_ids
    local cmd=$2
    local act=$3
    local max_retries=3

    while IFS= read -r l; do [[ -n "$l" ]] && ids+=("$l"); done <<< "$1"
    if (( ${#ids[@]} == 0 )); then
      ui_echo_success "  - $act 대상 없음"
      ui_update_progress $UI_CURRENT_MAIN_STEP 100
      return
    fi

    ui_echo_info "▶️ $act (${#ids[@]})"
    local total=${#ids[@]}

    # 첫 번째 시도
    for ((i=1; i<=total; i++)); do
      if ! ui_log_cmd $cmd "${ids[i]}"; then
        failed_ids+=("${ids[i]}")
        ui_echo_warn "    - ${ids[i]} 삭제 실패, 재시도 예정"
      fi
      ui_update_progress $UI_CURRENT_MAIN_STEP $((100*i/total))
      sleep 0.05
    done

    # 실패한 항목 재시도
    for ((retry=1; retry<=max_retries && ${#failed_ids[@]}>0; retry++)); do
      if (( ${#failed_ids[@]} > 0 )); then
        ui_echo_info "    - 재시도 ${retry}/${max_retries} (${#failed_ids[@]}개)"
        local temp_failed=()
        for failed_id in "${failed_ids[@]}"; do
          sleep 0.5  # Docker daemon 안정화 대기
          if ! ui_log_cmd $cmd "$failed_id"; then
            temp_failed+=("$failed_id")
          else
            ui_echo_info "    - $failed_id 재시도 성공 ✅"
          fi
        done
        failed_ids=("${temp_failed[@]}")
      fi
    done

    if (( ${#failed_ids[@]} > 0 )); then
      ui_echo_warn "  - $act 부분 완료 (${#failed_ids[@]}개 실패)"
      ui_echo_warn "    실패 목록: ${failed_ids[*]}"
    else
      ui_echo_success "  - $act 완료"
    fi
  }

  # ─── 메인 리셋 로직 ───────────────
  run_docker_reset() {
    ui_set_current_step 0; ui_echo_info "▶️ 초기화"; ui_update_progress $UI_CURRENT_MAIN_STEP 100; ui_echo_success "  - 초기화 완료"
    ui_set_current_step 1; delete_with_progress "$(docker ps -q)" "docker stop" "컨테이너 종료"
    ui_set_current_step 2; delete_with_progress "$(docker ps -aq)" "docker rm -f" "컨테이너 삭제"
    ui_set_current_step 3; delete_with_progress "$(docker images -q)" "docker rmi -f" "이미지 삭제"
    ui_set_current_step 4; delete_with_progress "$(docker volume ls -q)" "docker volume rm -f" "볼륨 삭제"
    ui_set_current_step 5; delete_with_progress "$(docker network ls --filter type=custom -q)" "docker network rm" "네트워크 삭제"

    # Step 6: 캐시 정리
    ui_set_current_step 6; ui_echo_info "▶️ 캐시 정리"
    ui_log_cmd docker system prune -af --volumes
    ui_update_progress $UI_CURRENT_MAIN_STEP 50

    ui_echo_info "    - BuildKit 캐시 정리"
    ui_log_cmd sh -c "docker builder prune --all --force 2>/dev/null || true"
    ui_update_progress $UI_CURRENT_MAIN_STEP 70

    ui_echo_info "    - Buildx 캐시 정리"
    ui_log_cmd sh -c "docker buildx prune --all --force 2>/dev/null || true"
    ui_update_progress $UI_CURRENT_MAIN_STEP 85

    ui_echo_info "    - Docker Desktop 빌더 재설정"
    ui_log_cmd sh -c "docker buildx rm --all-inactive --force 2>/dev/null || true"
    ui_log_cmd sh -c "docker buildx create --use --bootstrap 2>/dev/null || true"
    ui_update_progress $UI_CURRENT_MAIN_STEP 100
    ui_echo_success "  - 전체 캐시 & 빌더 재설정 완료"

    # Step 7: 검증 & 강제 정리
    ui_set_current_step 7; ui_echo_info "▶️ 검증 & 강제 정리"
    local containers=$(docker ps -aq | wc -l)
    local images=$(docker images -q | wc -l)
    local volumes=$(docker volume ls -q | wc -l)
    local networks=$(docker network ls --filter type=custom -q | wc -l)

    ui_log_cmd echo "Initial verification: containers=$containers, images=$images, volumes=$volumes, networks=$networks"
    ui_update_progress $UI_CURRENT_MAIN_STEP 30

    # 남은 리소스가 있으면 강제 정리 수행
    if (( containers > 0 || images > 0 || volumes > 0 || networks > 0 )); then
      ui_echo_warn "  - 남은 리소스 감지, 강제 정리 수행"

      if (( containers > 0 )); then
        ui_echo_info "    - 남은 컨테이너 강제 정리 ($containers개)"
        ui_log_cmd sh -c "docker rm -f \$(docker ps -aq) 2>/dev/null || true"
      fi
      ui_update_progress $UI_CURRENT_MAIN_STEP 50

      if (( volumes > 0 )); then
        ui_echo_info "    - 남은 볼륨 강제 정리 ($volumes개)"
        ui_log_cmd sh -c "docker volume rm -f \$(docker volume ls -q) 2>/dev/null || true"
      fi
      ui_update_progress $UI_CURRENT_MAIN_STEP 70

      if (( networks > 0 )); then
        ui_echo_info "    - 남은 네트워크 강제 정리 ($networks개)"
        ui_log_cmd sh -c "docker network rm \$(docker network ls --filter type=custom -q) 2>/dev/null || true"
      fi
      ui_update_progress $UI_CURRENT_MAIN_STEP 85
    fi

    # 시스템 전체 정리
    ui_log_cmd docker system prune -af --volumes
    ui_update_progress $UI_CURRENT_MAIN_STEP 95

    # 최종 검증 - 결과를 변수에 저장하여 중복 호출 방지
    local final_containers=$(docker ps -aq | wc -l)
    local final_images=$(docker images -q | wc -l)
    local final_volumes=$(docker volume ls -q | wc -l)
    local final_networks=$(docker network ls --filter type=custom -q | wc -l)

    ui_log_cmd echo "Final verification: containers=$final_containers, images=$final_images, volumes=$final_volumes, networks=$final_networks"
    ui_update_progress $UI_CURRENT_MAIN_STEP 100

    if (( final_containers == 0 && final_images == 0 && final_volumes == 0 && final_networks == 0 )); then
      ui_echo_success "  - 완전 정리 검증 ✅ (모든 리소스 삭제 완료)"
      ui_echo_info "  - Docker Desktop GUI 빌드 히스토리 완전 초기화를 위해서는"
      ui_echo_info "    Docker Desktop 재시작을 권장합니다."
    else
      ui_echo_warn "  - 부분 정리 완료 ⚠️ (컨테이너:$final_containers, 이미지:$final_images, 볼륨:$final_volumes, 네트워크:$final_networks)"
    fi
  }

  # ─── 사용자 확인 ──────────────────
  confirm_prompt() {
    ui_echo_warn "$MSG_WARNING"
    if ! ui_confirm "진행하시겠습니까?"; then
      ui_echo_error "취소되었습니다."
      return 1
    fi
    return 0
  }

  # ─── 메인 실행 함수 ───────────────
  main() {
    ui_check_dependency "docker" "Docker" || return 1

    ui_setup_traps
    ui_clear_screen
    ui_hide_cursor
    ui_print_header "$MSG_TITLE"
    ui_update_progress 0 0

    if confirm_prompt; then
      echo
      run_docker_reset
      UI_CURRENT_PCT=100
      ui_draw_progress_bar
      ui_move_to_line $((PROGRESS_BAR_LINE + 2))
      ui_echo_success "$MSG_COMPLETE"
      ui_echo_info "자세한 로그는 다음 파일에서 확인하세요: $UI_LOG_FILE"
    fi
  }

  main
}
