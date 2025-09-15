#!/bin/zsh
# 파일 경로: ~/.zsh.d/devcontainer_setup.sh
# 설명: 현재 디렉토리에 완전한 DevContainer 환경 설정을 생성합니다.

# ──────────────────────────────────────────────────────────
# devcontainer:setup | DevContainer Environment Setup
# ──────────────────────────────────────────────────────────
devcontainer:setup() {
  # 스크립트 버전 정보
  local VERSION="1.2.0"

  # --version 또는 -v 플래그가 입력되면 버전 정보 출력 후 종료
  if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "devcontainer:setup version $VERSION"
    return 0
  fi

  # 🎨 색상 팔레트
  local reset=$'\e[0m'; local bold=$'\e[1m'; local dim=$'\e[2m'
  local green=$'\e[38;5;46m'; local red=$'\e[38;5;196m'; local yellow=$'\e[38;5;226m'
  local blue=$'\e[38;5;39m'; local cyan=$'\e[38;5;51m'; local magenta=$'\e[38;5;201m'
  local purple=$'\e[38;5;141m'; local orange=$'\e[38;5;208m'

  # 📁 경로 설정
  local SOURCE_TEMPLATE_DIR="$HOME/.zsh.d/.templates/devcontainer"
  local TARGET_DIR=".devcontainer"
  local CLAUDE_SOURCE_DIR="$HOME/.claude"
  local CCSTATUSLINE_SOURCE_DIR="$HOME/.config/ccstatusline"

  # 메시지 정의
  local MSG_TITLE="DevContainer Setup by TechJuiceLab v${VERSION}"
  local MSG_WARNING="🚨 현재 디렉토리에 .devcontainer 폴더를 생성합니다!"
  local MSG_PROMPT="진행하시겠습니까? (Y/n): "
  local MSG_CANCELED="취소되었습니다."
  local MSG_COMPLETE="🎉 DevContainer 설정 완료!"

  # ─── 제목 박스 함수 ──────────
  print_title_box() {
    local title="$1"
    local box_width=54

    # 실제 터미널 표시 너비 계산
    local str_len=${#title}
    local emoji_count=$(echo "$title" | grep -oE '[🐳🛠️🎯]' | wc -l | tr -d ' ')
    local hangul_count=$(echo "$title" | grep -oE '[가-힣]' | wc -l | tr -d ' ')
    local display_width=$((str_len + emoji_count + hangul_count))

    # 박스 내부 여백 계산
    local inner_padding=$((box_width - display_width - 2))
    local left_padding=$((inner_padding / 2 + 2))
    local right_padding=$((inner_padding - left_padding + 2))

    # 수평선 생성
    local horizontal_line=""
    for ((i=0; i<box_width; i++)); do
      horizontal_line+="═"
    done

    # 제목 라인 생성
    local title_line="║"
    for ((i=0; i<left_padding; i++)); do title_line+=" "; done
    title_line+="$title"
    for ((i=0; i<right_padding; i++)); do title_line+=" "; done
    title_line+="║"

    echo -e "${bold}${cyan}╔${horizontal_line}╗${reset}"
    echo -e "${bold}${cyan}${title_line}${reset}"
    echo -e "${bold}${cyan}╚${horizontal_line}╝${reset}"
  }

  # ─── 메시지 출력 함수 ───────────
  echo_info() { echo -e "${cyan}ℹ️  $1${reset}"; }
  echo_success() { echo -e "${green}✅ $1${reset}"; }
  echo_warn() { echo -e "${orange}⚠️  $1${reset}"; }
  echo_error() { echo -e "${red}❌ $1${reset}"; }

  # ─── 사용자 확인 ─────────────
  confirm_prompt() {
    echo_warn "$MSG_WARNING"
    printf "${cyan}${MSG_PROMPT}${reset}"
    local ans
    read ans

    # 빈 입력(엔터만) 또는 Y/y는 실행
    if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
      return 0
    # n/N만 취소
    elif [[ "$ans" =~ ^[Nn]$ ]]; then
      echo_error "$MSG_CANCELED"
      return 1
    else
      echo_warn "잘못된 입력입니다. Y 또는 n을 입력하세요."
      return $(confirm_prompt)
    fi
  }

  # ─── 디렉토리 검사 ───────────
  check_directories() {
    echo_info "▶️ 환경 검사"

    if [[ ! -d "$SOURCE_TEMPLATE_DIR" ]]; then
      echo_error "템플릿 디렉토리를 찾을 수 없습니다: $SOURCE_TEMPLATE_DIR"
      return 1
    fi

    if [[ ! -d "$CLAUDE_SOURCE_DIR" ]]; then
      echo_error "Claude 설정 디렉토리를 찾을 수 없습니다: $CLAUDE_SOURCE_DIR"
      return 1
    fi

    if [[ -d "$TARGET_DIR" ]]; then
      echo_warn "  - .devcontainer 폴더가 이미 존재합니다. 덮어쓰시겠습니까? (Y/n): "
      local ans
      read ans
      if [[ "$ans" =~ ^[Nn]$ ]]; then
        echo_error "작업이 취소되었습니다."
        return 1
      fi
      echo_info "  - 기존 .devcontainer 폴더를 백업합니다..."
      mv "$TARGET_DIR" "${TARGET_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    echo_success "  - 환경 검사 완료"
  }

  # ─── 기본 파일 복사 ─────────
  copy_base_files() {
    echo_info "▶️ 기본 파일 복사"

    # .devcontainer 디렉토리 생성
    mkdir -p "$TARGET_DIR"

    # 기본 템플릿 파일들 복사
    cp "$SOURCE_TEMPLATE_DIR/devcontainer.json" "$TARGET_DIR/"
    cp "$SOURCE_TEMPLATE_DIR/Dockerfile" "$TARGET_DIR/"
    cp "$SOURCE_TEMPLATE_DIR/init-firewall.sh" "$TARGET_DIR/"

    echo_success "  - 기본 파일 복사 완료"
  }

  # ─── 개인화 설정 복사 ───────
  copy_personal_settings() {
    echo_info "▶️ 개인화 설정 복사"

    # Claude 설정 복사
    echo_info "  - Claude 설정 복사 중..."
    cp -r "$CLAUDE_SOURCE_DIR" "$TARGET_DIR/.claude"
    echo_success "    - Claude 설정 복사 완료"

    # ccstatusline 설정 복사 (있는 경우에만)
    if [[ -d "$CCSTATUSLINE_SOURCE_DIR" ]]; then
      echo_info "  - ccstatusline 설정 복사 중..."
      cp -r "$CCSTATUSLINE_SOURCE_DIR" "$TARGET_DIR/ccstatusline"
      echo_success "    - ccstatusline 설정 복사 완료"
    else
      echo_warn "    - ccstatusline 설정을 찾을 수 없습니다. 건너뜁니다."
    fi

    # powerlevel10k 설정 복사 (있는 경우에만)
    if [[ -f "$HOME/.p10k.zsh" ]]; then
      echo_info "  - powerlevel10k 설정 복사 중..."
      cp "$HOME/.p10k.zsh" "$TARGET_DIR/.p10k.zsh"
      echo_success "    - powerlevel10k 설정 복사 완료"
    else
      echo_warn "    - .p10k.zsh 파일을 찾을 수 없습니다. 건너뜁니다."
    fi

    echo_success "  - 개인화 설정 복사 완료"
  }

  # ─── docker-zshrc 생성 ──────
  create_docker_zshrc() {
    echo_info "▶️ docker-zshrc 생성"

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

    echo_success "  - docker-zshrc 생성 완료"
  }

  # ─── Dockerfile 업데이트 ────
  update_dockerfile() {
    echo_info "▶️ Dockerfile 업데이트"

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

    echo_success "  - Dockerfile 업데이트 완료"
  }

  # ─── README 생성 ──────────
  create_readme() {
    echo_info "▶️ README 생성"

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

    echo_success "  - README 생성 완료"
  }

  # ─── 메인 실행 함수 ───────────
  main() {
    clear
    print_title_box "$MSG_TITLE"
    echo

    if confirm_prompt; then
      echo

      if check_directories && \
         copy_base_files && \
         copy_personal_settings && \
         create_docker_zshrc && \
         update_dockerfile && \
         create_readme; then

        echo
        echo_success "$MSG_COMPLETE"
        echo_info "📁 생성된 폴더: $(pwd)/$TARGET_DIR"
        echo_info "🚀 VS Code에서 'Dev Containers: Reopen in Container'를 실행하세요"
        echo_info "📖 자세한 정보: $TARGET_DIR/README.md"
      else
        echo_error "설정 중 오류가 발생했습니다."
        return 1
      fi
    fi
  }

  # 함수 실행
  main
}