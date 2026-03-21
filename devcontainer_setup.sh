#!/bin/zsh
# 파일 경로: ~/.zsh.d/devcontainer_setup.sh
# 설명: 현재 디렉토리에 완전한 DevContainer 환경 설정을 생성합니다.

# ──────────────────────────────────────────────────────────
# devcontainer:setup | DevContainer Environment Setup
# ──────────────────────────────────────────────────────────
devcontainer:setup() {
  # 스크립트 버전 정보
  local VERSION="1.2.0"

  # 공유 라이브러리 로드
  local LIB_DIR="${0:A:h}/lib"
  source "${LIB_DIR}/ui-framework.zsh" || { echo "ERROR: ui-framework.zsh 로드 실패"; return 1; }
  source "${LIB_DIR}/helpers.zsh" || { echo "ERROR: helpers.zsh 로드 실패"; return 1; }

  # --version 또는 -v 플래그가 입력되면 버전 정보 출력 후 종료
  if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "devcontainer:setup version $VERSION"
    return 0
  elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << 'EOF'
사용법: devcontainer:setup [옵션]

옵션:
  --help, -h      이 도움말을 표시합니다
  --version, -v   버전 정보를 표시합니다

설명:
  현재 프로젝트에 DevContainer 환경을 자동 설정합니다.
  .devcontainer 폴더에 Dockerfile, devcontainer.json, 방화벽 설정 등을 생성합니다.
EOF
    return 0
  fi

  # 📁 경로 설정
  local SOURCE_TEMPLATE_DIR="$HOME/.zsh.d/.templates/devcontainer"
  local TARGET_DIR=".devcontainer"
  local CLAUDE_SOURCE_DIR="$HOME/.claude"
  local CCSTATUSLINE_SOURCE_DIR="$HOME/.config/ccstatusline"

  # 메시지 정의
  local MSG_TITLE="DevContainer Setup by TechJuiceLab v${VERSION}"
  local MSG_WARNING="🚨 현재 디렉토리에 .devcontainer 폴더를 생성합니다!"
  local MSG_CANCELED="취소되었습니다."
  local MSG_COMPLETE="🎉 DevContainer 설정 완료!"

  # ─── 디렉토리 검사 ───────────
  check_directories() {
    ui_echo_info "▶️ 환경 검사"

    if [[ ! -d "$SOURCE_TEMPLATE_DIR" ]]; then
      ui_echo_error "템플릿 디렉토리를 찾을 수 없습니다: $SOURCE_TEMPLATE_DIR"
      return 1
    fi

    if [[ ! -d "$CLAUDE_SOURCE_DIR" ]]; then
      ui_echo_error "Claude 설정 디렉토리를 찾을 수 없습니다: $CLAUDE_SOURCE_DIR"
      return 1
    fi

    if [[ -d "$TARGET_DIR" ]]; then
      ui_echo_warn "  - .devcontainer 폴더가 이미 존재합니다."
      if ! ui_confirm "덮어쓰시겠습니까?"; then
        ui_echo_error "작업이 취소되었습니다."
        return 1
      fi
      ui_echo_info "  - 기존 .devcontainer 폴더를 백업합니다..."
      mv "$TARGET_DIR" "${TARGET_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    ui_echo_success "  - 환경 검사 완료"
  }

  # ─── 기본 파일 복사 ─────────
  copy_base_files() {
    ui_echo_info "▶️  기본 파일 복사"
    if ! mkdir -p "$TARGET_DIR"; then
      ui_echo_error "  - $TARGET_DIR 생성 실패"
      return 1
    fi
    local -a files=("devcontainer.json" "Dockerfile" "init-firewall.sh")
    for file in "${files[@]}"; do
      if [[ ! -f "$SOURCE_TEMPLATE_DIR/$file" ]]; then
        ui_echo_error "  - 소스 파일 없음: $SOURCE_TEMPLATE_DIR/$file"
        return 1
      fi
      if ! cp "$SOURCE_TEMPLATE_DIR/$file" "$TARGET_DIR/"; then
        ui_echo_error "  - $file 복사 실패"
        return 1
      fi
    done
    ui_echo_success "  - 기본 파일 복사 완료"
  }

  # ─── 개인화 설정 복사 ───────
  copy_personal_settings() {
    ui_echo_info "▶️ 개인화 설정 복사"

    # Claude 설정 복사
    ui_echo_info "  - Claude 설정 복사 중..."
    cp -r "$CLAUDE_SOURCE_DIR" "$TARGET_DIR/.claude"
    ui_echo_success "    - Claude 설정 복사 완료"

    # ccstatusline 설정 복사 (있는 경우에만)
    if [[ -d "$CCSTATUSLINE_SOURCE_DIR" ]]; then
      ui_echo_info "  - ccstatusline 설정 복사 중..."
      cp -r "$CCSTATUSLINE_SOURCE_DIR" "$TARGET_DIR/ccstatusline"
      ui_echo_success "    - ccstatusline 설정 복사 완료"
    else
      ui_echo_warn "    - ccstatusline 설정을 찾을 수 없습니다. 건너뜁니다."
    fi

    # powerlevel10k 설정 복사 (있는 경우에만)
    if [[ -f "$HOME/.p10k.zsh" ]]; then
      ui_echo_info "  - powerlevel10k 설정 복사 중..."
      cp "$HOME/.p10k.zsh" "$TARGET_DIR/.p10k.zsh"
      ui_echo_success "    - powerlevel10k 설정 복사 완료"
    else
      ui_echo_warn "    - .p10k.zsh 파일을 찾을 수 없습니다. 건너뜁니다."
    fi

    ui_echo_success "  - 개인화 설정 복사 완료"
  }

  # ─── docker-zshrc 생성 ──────
  create_docker_zshrc() {
    ui_echo_info "▶️ docker-zshrc 생성"

    cat > "$TARGET_DIR/docker-zshrc" << 'EOF'
# Docker Container용 zsh 설정
# Oh My Zsh 설정
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# 플러그인 설정 (요청된 4개만)
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  fzf
)

# Oh My Zsh 로드
source $ZSH/oh-my-zsh.sh

# powerlevel10k 즉시 설정 활성화
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Claude Code 환경변수
export DEVCONTAINER=true

# 개발 도구 PATH 설정
export PATH="/usr/local/share/npm-global/bin:$HOME/.bun/bin:$PATH"

# 사용자 정의 별칭
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Claude Code 상태 표시 (ccstatusline이 있는 경우)
if [[ -f /workspace/.devcontainer/ccstatusline/settings.json ]]; then
  export CCSTATUSLINE_CONFIG_PATH="/workspace/.devcontainer/ccstatusline/settings.json"
fi

# Git 설정 확인
if ! git config --global user.name >/dev/null 2>&1; then
  echo "⚠️  Git 사용자 설정이 필요합니다:"
  echo "   git config --global user.name \"Your Name\""
  echo "   git config --global user.email \"your.email@example.com\""
fi

echo "🐳 DevContainer 환경이 준비되었습니다!"
EOF

    ui_echo_success "  - docker-zshrc 생성 완료"
  }

  # ─── Dockerfile 업데이트 ────
  update_dockerfile() {
    ui_echo_info "▶️ Dockerfile 업데이트"

    # 기존 Dockerfile에 개인화 설정 추가 (이미 설치된 요소들 제외)
    cat >> "$TARGET_DIR/Dockerfile" << 'EOF'

# === 개인화 설정 추가 ===
# 참고: zsh-in-docker(line 73-79)가 이미 설치함:
# - Oh My Zsh
# - powerlevel10k 테마 (기본값)
# - git, fzf 플러그인

# 추가 zsh 플러그인 설치 (syntax-highlighting, autosuggestions만)
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# bun 설치 (PATH는 docker-zshrc에서 설정됨)
RUN curl -fsSL https://bun.sh/install | bash

# 개인화 설정 파일 복사 (권한 동시 설정)
COPY --chown=node:node .claude /home/node/.claude
COPY --chown=node:node .p10k.zsh /home/node/.p10k.zsh
COPY --chown=node:node ccstatusline /home/node/.config/ccstatusline
COPY --chown=node:node docker-zshrc /home/node/.zshrc
EOF

    ui_echo_success "  - Dockerfile 업데이트 완료"
  }

  # ─── README 생성 ──────────
  create_readme() {
    ui_echo_info "▶️ README 생성"

    cat > "$TARGET_DIR/README.md" << 'EOF'
# DevContainer 환경 설정

이 DevContainer는 다음과 같은 개인화 설정을 포함합니다:

## 포함된 설정

### 🧠 SuperClaude Framework
- 완전한 Claude Code 확장 시스템
- 모든 persona, command, MCP 서버 설정 포함

### 🎨 Shell 환경
- Oh My Zsh + powerlevel10k 테마
- 필수 플러그인: git, zsh-syntax-highlighting, zsh-autosuggestions, fzf
- 개인화된 .p10k.zsh 설정

### 📊 모니터링
- ccstatusline: Claude Code 상태 모니터링
- 실시간 토큰 사용량, 컨텍스트 사용률 추적

### 🛠️ 개발 도구
- Node.js 20 런타임
- bun 패키지 매니저
- 네트워크 보안 설정 (allowlist 기반)

## 사용법

1. VS Code에서 "Dev Containers: Reopen in Container" 실행
2. 컨테이너가 빌드되고 모든 설정이 자동으로 적용됩니다
3. 터미널이 zsh + powerlevel10k로 설정됩니다
4. Claude Code가 SuperClaude 프레임워크와 함께 사용 가능합니다

## 생성 정보

- 생성 시간: $(date '+%Y-%m-%d %H:%M:%S')
- 생성 도구: devcontainer:setup v1.0.0
- 소스 설정: 현재 Mac 환경 (~/.claude, ~/.p10k.zsh, ~/.config/ccstatusline)
EOF

    ui_echo_success "  - README 생성 완료"
  }

  # ─── 실패 시 정리 함수 ───────
  cleanup_on_failure() {
    if [[ -d "$TARGET_DIR" && -n "$TARGET_DIR" ]]; then
      ui_echo_error "설정 중 오류 발생, 생성된 파일을 정리합니다..."
      rm -rf "$TARGET_DIR"
    fi
  }

  # ─── 메인 실행 함수 ───────────
  main() {
    clear
    ui_create_title_box "$MSG_TITLE" 54
    echo

    ui_echo_warn "$MSG_WARNING"
    if ui_confirm "진행하시겠습니까?"; then
      echo

      if check_directories && \
         copy_base_files && \
         copy_personal_settings && \
         create_docker_zshrc && \
         update_dockerfile && \
         create_readme; then

        echo
        ui_echo_success "$MSG_COMPLETE"
        ui_echo_info "📁 생성된 폴더: $(pwd)/$TARGET_DIR"
        ui_echo_info "🚀 VS Code에서 'Dev Containers: Reopen in Container'를 실행하세요"
        ui_echo_info "📖 자세한 정보: $TARGET_DIR/README.md"
      else
        cleanup_on_failure
        ui_echo_error "설정 중 오류가 발생했습니다."
        return 1
      fi
    else
      ui_echo_error "$MSG_CANCELED"
    fi
  }

  # 함수 실행
  main
}
