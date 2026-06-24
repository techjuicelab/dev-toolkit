# 🚀 ZSH 개발 환경 자동화 도구 v2.1

개발 환경 관리를 위한 자동화된 업데이트 및 초기화 스크립트 모음입니다.

## 📋 프로젝트 개요

이 프로젝트는 macOS 개발 환경에서 다양한 도구들을 효율적으로 관리하기 위한 스크립트들을 포함합니다:

- **ASDF 버전 매니저** 자동 업데이트
- **Homebrew** 전체 업데이트
- **Docker** 완전 초기화
- **DevContainer** 환경 설정 자동화
- **tmux 세션 관리** fzf 기반 단축 함수
- **AI/자동화 도구** 1Password 기반 API 키 관리 + n8n 유틸리티
- **Claude Code 플러그인 마켓플레이스** worktree 머지, 시크릿 차단(1Password), asdf/devcontainer 닥터

모든 스크립트는 실시간 진행률 표시, 컬러풀한 UI, 그리고 상세한 로깅 기능을 제공합니다.

## 📂 프로젝트 구조

```
~/.zsh.d/
├── asdf_update.sh         # ASDF 플러그인 및 도구 업데이트
├── brew_update.sh         # Homebrew 전체 업데이트
├── docker_reset.sh        # Docker 완전 초기화
├── devcontainer_setup.sh  # DevContainer 환경 설정 자동화
├── tmux_shortcuts.sh      # tmux 세션 관리 (fzf 연동)
├── ai_tools.sh            # AI/자동화 도구 (API 키 관리, n8n 유틸리티)
├── lib/                   # v2.0 공통 라이브러리 (UI, 설정, 헬퍼)
│   ├── config.zsh         #   공통 설정 및 상수 정의
│   ├── ui-framework.zsh   #   통합 UI 프레임워크 (진행률, 박스, 컬러)
│   └── helpers.zsh        #   공통 유틸리티 함수
├── .claude-plugin/        # Claude Code 플러그인 마켓플레이스 카탈로그
│   └── marketplace.json
├── plugins/                # 배포 플러그인 (claude plugin install)
│   ├── git-worktree/       #   worktree squash-merge 스킬
│   ├── secret-guard/       #   시크릿 차단 훅 + op-secrets(1Password) 스킬
│   └── toolchain-doctor/   #   asdf-doctor 에이전트 + devcontainer-parity 스킬
├── .templates/            # DevContainer 템플릿 파일들 (숨김 폴더)
│   └── devcontainer/
│       ├── devcontainer.json
│       ├── Dockerfile
│       └── init-firewall.sh
├── logs/                  # 실행 로그 저장 디렉토리
├── .gitignore            # Git 제외 파일 설정
├── CLAUDE.md             # Claude Code AI 어시스턴트 연동 가이드
└── README.md             # 이 파일
```

## ⚙️ 설치 및 설정

### 1. 저장소 클론
```bash
git clone git@github.com:techjuicelab/dev-toolkit.git ~/.zsh.d
```

### 2. 실행 권한 부여
```bash
chmod +x ~/.zsh.d/*.sh
```

### 3. ZSH 설정 연동

다음 명령어를 실행하여 ~/.zshrc 파일에 자동 로드 설정을 추가하세요:

```bash
# ~/.zshrc 파일에 자동 로드 설정 추가
cat >> ~/.zshrc << 'EOF'

# ~/.zsh.d/ 디렉터리에 있는 모든 .sh 파일을 한 번에 불러오기
if [ -d "${HOME}/.zsh.d" ]; then
  for f in "${HOME}/.zsh.d/"*.sh; do
    [ -r "$f" ] && source "$f"
  done
fi
EOF
```

### 4. 설정 적용 및 확인
```bash
# 설정 즉시 적용
source ~/.zshrc

# 함수가 제대로 로드되었는지 확인
type asdf:update brew:update docker:reset devcontainer:setup tmuxn tmuxa
```

### 5. 설정 확인 (선택사항)
```bash
# ~/.zshrc에 설정이 추가되었는지 확인
grep -A 5 "~/.zsh.d" ~/.zshrc

# 스크립트 파일들 확인
ls -la ~/.zsh.d/*.sh
```

## 🛠️ 사용 방법

### ASDF 업데이트 (`asdf:update`)
ASDF로 관리되는 모든 플러그인과 도구를 최신 버전으로 업데이트합니다.

```bash
# 전체 ASDF 환경 업데이트
asdf:update

# 버전 확인
asdf:update --version
# 또는
asdf:update -v

# 도움말 확인
asdf:update --help
```

**기능:**
- 플러그인 자동 업데이트
- 설치된 모든 도구의 최신 버전 확인 및 업데이트
- 병렬 버전 조회로 빠른 업데이트 (최대 4개 동시 처리)
- 실시간 진행률 표시
- 상세한 로그 기록

> **asdf 0.19.0 (Go 재작성판) 호환** — 전역 버전은 `asdf set --home`으로 `~/.tool-versions`에 기록하고,
> `asdf current`의 헤더+4컬럼 출력 파싱과 버전 미설정(`______`) 플러그인 자동 스킵을 지원합니다.
> asdf 본체는 `brew upgrade asdf`로 먼저 업데이트하세요. (예전 `asdf.sh` source 방식이 아니라
> `~/.zshrc`에서 `$HOME/.asdf/shims`를 PATH에 추가하는 방식)

### Homebrew 업데이트 (`brew:update`)
Homebrew Formulae, Cask, Mac App Store 앱을 한번에 업데이트합니다.

```bash
# 전체 Homebrew 환경 업데이트
brew:update

# 버전 확인
brew:update --version
# 또는
brew:update -v

# 도움말 확인
brew:update --help
```

**기능:**
- Homebrew 저장소 갱신
- Formulae 업그레이드
- Cask 애플리케이션 업데이트
- Mac App Store 앱 업데이트
- 실시간 진행률 및 통계 표시

### Docker 초기화 (`docker:reset`)
Docker의 모든 컨테이너, 이미지, 볼륨, 네트워크를 완전히 초기화합니다.

```bash
# Docker 완전 초기화
docker:reset

# 버전 확인
docker:reset --version
# 또는
docker:reset -v

# 도움말 확인
docker:reset --help
```

**기능:**
- 실행 중인 모든 컨테이너 정지 및 삭제
- 모든 이미지, 볼륨, 네트워크 삭제
- 빌드 캐시 정리
- 시스템 정리 및 최적화

### DevContainer 환경 설정 (`devcontainer:setup`)
현재 디렉토리에 완전한 DevContainer 환경을 자동으로 설정합니다.

```bash
# DevContainer 환경 설정
devcontainer:setup

# 버전 확인
devcontainer:setup --version
# 또는
devcontainer:setup -v

# 도움말 확인
devcontainer:setup --help
```

**기능:**
- Claude Code 개인 설정 통합 (`skills`/`commands`/`agents`/`settings.json` 등 — 자격증명·세션 기록 같은 민감 파일은 제외하고 복사)
- Oh My Zsh + Powerlevel10k 테마 자동 설정
- 필수 플러그인: git, zsh-syntax-highlighting, zsh-autosuggestions, fzf
- ccstatusline: Claude Code 상태 모니터링 시스템
- 네트워크 보안 설정 (allowlist 기반 방화벽)
- Node.js 22 + bun 패키지 매니저 환경
- 개인화된 설정 자동 적용 (Claude, Powerlevel10k 등)
- 🔒 보안: `~/.claude`는 **안전 항목만 화이트리스트 복사**하고 `.devcontainer/.gitignore`를 자동 생성하여, 자격증명/세션 기록이 git에 커밋되는 것을 방지

**포함된 설정:**
- `.devcontainer/devcontainer.json` - VS Code DevContainer 설정
- `.devcontainer/Dockerfile` - 컨테이너 이미지 빌드 파일
- `.devcontainer/init-firewall.sh` - 네트워크 보안 초기화
- `.devcontainer/.claude/` - Claude Code 설정 (안전 항목만 복사: skills/commands/agents/settings.json 등)
- `.devcontainer/.p10k.zsh` - Powerlevel10k 개인화 설정
- `.devcontainer/ccstatusline/` - Claude Code 상태 모니터링
- `.devcontainer/docker-zshrc` - 컨테이너용 zsh 설정
- `.devcontainer/README.md` - DevContainer 환경 가이드

**사용 방법:**
1. 프로젝트 루트 디렉토리에서 `devcontainer:setup` 실행
2. VS Code에서 "Dev Containers: Reopen in Container" 선택
3. 컨테이너가 빌드되고 모든 설정이 자동으로 적용됨

### tmux 세션 관리
fzf를 활용한 tmux 세션 관리 단축 함수입니다.

```bash
tmuxn           # 현재 디렉토리명으로 세션 생성/attach
tmuxn proj-a    # 'proj-a' 이름으로 세션 생성/attach
tmuxl           # 세션 목록 출력
tmuxa           # fzf로 세션 골라서 attach (tmux 안에서는 switch)
tmuxk           # fzf로 세션 골라서 kill (확인 있음)
tmuxd           # 현재 세션에서 detach
tmuxr api-v2    # 현재 세션 이름을 'api-v2'로 변경
tmuxr           # fzf로 세션 골라서 이름 변경
tmuxw           # fzf로 모든 세션의 윈도우 선택 후 이동
```

**의존성:** tmux, fzf

**fzf 미리보기:** 세션 선택 시 해당 세션의 윈도우 목록이 preview로 표시되고, `tmuxw`에서는 선택한 윈도우의 실제 화면 내용이 표시됩니다.

### AI/자동화 도구 (`ai_tools.sh`)
1Password CLI를 통해 AI 서비스 API 키를 안전하게 관리하고, n8n 서버 유틸리티를 제공합니다.

```bash
# API 키 로드 (Touch ID 인증 필요)
ai:load

# 로드 상태 확인 (키 값은 마스킹 표시)
ai:status

# 환경변수 제거
ai:unload

# n8n 서버 상태 확인
n8n:health

# n8n 최근 실행 로그 (최근 5건)
n8n:logs
```

**지원 서비스**: Z.AI, Google Gemini, Notion (API + 다수 DB), GitHub, Telegram (11개 봇), Naver Search, N2YO, Groq, n8n, PostgreSQL

**의존성**: 1Password CLI v2 (`brew install --cask 1password-cli`)

**편의 Alias:**
| Alias | 설명 |
|-------|------|
| `cc` | `claude --dangerously-skip-permissions` |

### Claude Code 플러그인 (마켓플레이스)

이 저장소는 **Claude Code 플러그인 마켓플레이스**입니다. (옛 `claude_hooks_skills/` bash 설치기 + 자동커밋 훅은 폐기되고 네이티브 플러그인 시스템으로 대체되었습니다 — 효용 평가 후 `merge-worktree`만 유지하고 나머지는 드롭, 보안/툴체인 플러그인을 신규 추가.)

**제공 플러그인:**

| 플러그인 | 구성 | 설명 |
|---|---|---|
| `git-worktree` | skill `merge-worktree` | worktree 브랜치를 타깃으로 squash-merge (`--pr` 옵션). 충돌 시 중단, force-push/hook-skip 안 함 |
| `secret-guard` | PreToolUse hook + skill `op-secrets` | 평문 시크릿(`sk-`/`ghp_`/`AKIA`/private key 등) 쓰기·커밋을 **차단**하고 1Password(`op://`) 워크플로로 유도 |
| `toolchain-doctor` | agent `asdf-doctor` + skill `devcontainer-parity` | `.tool-versions` 드리프트 진단 + devcontainer↔호스트 정합성 점검 |

**내 Claude Code에 적용 (설치):**

```bash
# 1) 이 저장소를 마켓플레이스로 추가
claude plugin marketplace add techjuicelab/dev-toolkit
#    (로컬 클론에서 바로: claude plugin marketplace add ~/.zsh.d)

# 2) 원하는 플러그인 설치
claude plugin install secret-guard@dev-toolkit
claude plugin install git-worktree@dev-toolkit
claude plugin install toolchain-doctor@dev-toolkit
```

또는 세션 안에서 `/plugin` → marketplace 추가 → 설치.

**사용법:**
- **`secret-guard`** — 설치만 하면 자동 동작(시크릿 쓰기/커밋 시도 시 차단). `op-secrets` 스킬은 환경변수·`.env`·시크릿 작업 시 자동 로드.
- **`git-worktree`** — worktree 안에서 `/git-worktree:merge-worktree [target] [--pr]` 수동 호출.
- **`toolchain-doctor`** — "이 프로젝트 asdf 점검해줘" → `asdf-doctor` 서브에이전트 / "devcontainer가 호스트랑 맞는지 봐줘" → `devcontainer-parity` 스킬.

**업데이트 / 제거:**
```bash
claude plugin update <name>@dev-toolkit
claude plugin uninstall <name>@dev-toolkit
```

## 📊 로그 시스템

모든 스크립트는 실행 시 상세한 로그를 생성합니다:

```
~/.zsh.d/logs/
├── asdf_update_20240819_143022.log
├── brew_update_20240819_143155.log
├── docker_reset_20240819_143300.log
└── devcontainer_setup_20240915_125945.log
```

로그 파일에는 다음 정보가 포함됩니다:
- 실행 시간 및 소요 시간
- 각 단계별 진행 상황
- 오류 및 경고 메시지
- 업데이트된 항목들의 상세 정보

### 로그 자동 관리
- **보관 기간**: 7일 이상 된 로그 자동 삭제
- **최대 파일 수**: 30개 초과 시 가장 오래된 파일 삭제
- **용량 경고**: 100MB 초과 시 경고 표시
- **파일 권한**: chmod 600 (소유자만 읽기/쓰기)

## 🎨 UI 특징

- **실시간 진행률 바**: 각 작업의 진행 상황을 시각적으로 표시
- **컬러풀한 출력**: 상태별로 다른 색상을 사용하여 가독성 향상
- **단계별 안내**: 현재 수행 중인 작업을 명확하게 표시
- **통계 정보**: 업데이트된 항목 수, 소요 시간 등 요약 정보 제공
- **접근성**: 색상 + 텍스트 레이블 이중 표시 (색맹 사용자 지원)
- **NO_COLOR 지원**: 색상 미지원 환경 자동 감지
- **터미널 감지**: 크기에 따른 동적 레이아웃 조정

## 🔧 필수 요구사항

- **macOS**: macOS 환경에서 동작
- **Zsh**: Zsh 셸 환경
- **Git**: 버전 관리 시스템
- **ASDF**: 버전 매니저 (asdf:update 사용시)
- **Homebrew**: 패키지 매니저 (brew:update 사용시)
- **Docker**: 컨테이너 플랫폼 (docker:reset 사용시)
- **tmux**: 터미널 멀티플렉서 (tmux 세션 관리 사용시)
- **fzf**: 퍼지 파인더 (tmux 대화형 선택 UI 사용시)
- **VS Code + Dev Containers 확장**: DevContainer 환경 사용시
- **1Password CLI** (`op`): AI/자동화 도구 API 키 관리 사용시
- **Claude Code**: hooks/skills 시스템, `cc` alias 사용시

## 📋 환경 요구사항

| 항목 | 최소 요구 | 권장 |
|------|----------|------|
| macOS | 12.0+ | 14.0+ |
| Zsh | 5.8+ | 5.9+ |
| 터미널 | UTF-8, 80x24 | 256색, 120x40 |
| LANG | UTF-8 인코딩 | ko_KR.UTF-8 |

## 🛡️ 주의사항

- `docker:reset`은 모든 Docker 데이터를 삭제하므로 신중하게 사용하세요
- `devcontainer:setup`은 현재 디렉토리에 .devcontainer 폴더를 생성하므로 프로젝트 루트에서 실행하세요
- 업데이트 작업은 인터넷 연결이 필요합니다
- 로그 파일은 자동 로테이션됩니다 (7일 보관, 최대 30개)
- DevContainer 환경은 VS Code와 Docker가 모두 설치되어 있어야 정상 작동합니다

## 🔧 문제 해결

### asdf:update 실행 시 "asdf가 설치되어 있지 않습니다" 오류
```bash
# ASDF 설치 확인
command -v asdf
# 설치: https://asdf-vm.com/guide/getting-started.html
# PATH에 asdf가 포함되어 있는지 확인
echo $PATH | grep asdf
```

### brew:update 실행 시 권한 오류
```bash
# Homebrew 디렉토리 소유권 수정
sudo chown -R $(whoami) $(brew --prefix)/*
```

### docker:reset 실행 시 "Docker가 설치되어 있지 않습니다" 오류
```bash
# Docker Desktop이 실행 중인지 확인
docker ps
# Docker Desktop 재시작: 메뉴 바에서 Docker 아이콘 → Restart
```

### 스크립트 실행 후 커서가 보이지 않을 때
```bash
# 커서 복원
printf "\e[?25h"
# 또는 터미널 리셋
reset
```

### 로그 디렉토리 권한 오류
```bash
# 로그 디렉토리 권한 확인 및 수정
ls -la ~/.zsh.d/logs/
chmod 755 ~/.zsh.d/logs/
```

### UI가 터미널에서 깨져 보일 때
```bash
# UTF-8 인코딩 확인
echo $LANG  # ko_KR.UTF-8 또는 en_US.UTF-8이어야 함
# 터미널이 256색을 지원하는지 확인
echo $TERM  # xterm-256color 권장
```

### ai:load 실행 시 "1Password CLI(op)가 설치되어 있지 않습니다" 오류
```bash
# 1Password CLI 설치
brew install --cask 1password-cli
# 설치 확인
op --version
```

### 라이브러리 로드 실패 오류
```bash
# lib/ 디렉토리 위치 확인
ls -la ~/.zsh.d/lib/
# 또는 프로젝트 디렉토리의 lib/
ls -la ./lib/
```

## 🧪 테스트

```bash
# 전체 테스트 스위트 실행 (85개 테스트)
zsh test/run_tests.zsh
```

테스트 범위:
- **config**: 색상, 상수, 이모지, 로그 설정 검증 (47개)
- **helpers**: 로깅, 재시도, 타임아웃, 로그 로테이션 검증 (13개)
- **ui**: 박스 드로잉, 진행률, 메시지, 의존성 검사 검증 (25개)

## ⚙️ 설정 커스터마이징

`lib/config.local.zsh`를 생성하여 개인 설정을 오버라이드할 수 있습니다:

```bash
# 예시 파일 복사
cp lib/config.local.zsh.example lib/config.local.zsh
```

커스터마이징 가능한 항목:
- 색상 팔레트 변경
- 진행 바 스타일 (`█░` 등)
- 로그 보관 기간 및 최대 파일 수
- 명령어 타임아웃 값
- 박스 너비, 진행률 바 위치

`NO_COLOR` 환경 변수 설정 시 색상 출력이 비활성화됩니다.

## 📝 버전 정보

**현재 스크립트 버전:**
- `asdf:update` - v1.4.1
- `brew:update` - v1.3.0
- `docker:reset` - v1.3.1
- `devcontainer:setup` - v1.2.0
- `tmux_shortcuts` - v1.0.0
- `ai_tools` - v1.0.0
- Claude 플러그인: `git-worktree`·`secret-guard`·`toolchain-doctor` - v0.1.0
- `lib/config.zsh` (DEV_TOOLKIT_VERSION) - v2.2.0

---

**개발환경**: macOS + Zsh + Oh My Zsh + Powerlevel10k
**작성자**: TechJuiceLab
**최종 업데이트**: 2026-06-24