# 🚀 dev-toolkit

TechJuiceLab의 macOS 개발 환경 도구 모음. **두 가지를 제공하며, 각각 독립적으로 설치·사용**할 수 있습니다:

| | 무엇 | 어디에 설치 |
|---|---|---|
| **A. zsh 자동화 함수** | asdf/brew/docker/devcontainer/tmux 관리 + 1Password 키 로딩 | 셸 (`~/.zsh.d` 클론) |
| **B. Claude Code 플러그인** | worktree 머지, 시크릿 차단, 툴체인 닥터 | Claude Code (마켓플레이스) |

> B는 저장소 클론 없이 `claude plugin` 한 줄로 설치됩니다. A만, B만, 또는 둘 다 쓰셔도 됩니다.

---

## ⚡ 빠른 시작

### Claude Code 플러그인만 (클론 불필요)
```bash
claude plugin marketplace add techjuicelab/dev-toolkit
claude plugin install secret-guard@dev-toolkit
claude plugin install git-worktree@dev-toolkit
claude plugin install toolchain-doctor@dev-toolkit
# → Claude Code 재시작(새 세션)하면 활성화
```

### zsh 함수까지
```bash
git clone git@github.com:techjuicelab/dev-toolkit.git ~/.zsh.d
cat >> ~/.zshrc << 'EOF'

# dev-toolkit: ~/.zsh.d 의 모든 *.sh 로드 (함수만 정의 → 시작 비용 낮음)
if [ -d "${HOME}/.zsh.d" ]; then
  for f in "${HOME}/.zsh.d/"*.sh; do [ -r "$f" ] && source "$f"; done
  unset f
fi
EOF
exec zsh
type asdf:update brew:update tmuxn ai:load   # 로드 확인
```

---

# 🔌 B. Claude Code 플러그인

이 저장소는 **Claude Code 플러그인 마켓플레이스**입니다. 공개 저장소라 누구나 설치할 수 있습니다.

## 설치 / 다른 머신에 적용

```bash
# 1) 마켓플레이스 등록 (GitHub에서 바로 — 클론 불필요)
claude plugin marketplace add techjuicelab/dev-toolkit
#    로컬 클론이 이미 있다면:  claude plugin marketplace add ~/.zsh.d

# 2) 원하는 플러그인 설치
claude plugin install secret-guard@dev-toolkit
claude plugin install git-worktree@dev-toolkit
claude plugin install toolchain-doctor@dev-toolkit
```

- 세션 안에서는 `/plugin` 메뉴로도 가능합니다.
- **설치 후 Claude Code를 재시작**해야 활성화됩니다 (플러그인은 세션 시작 시 로드).
- 확인: `claude plugin list` → 3개 모두 `enabled`.

## 플러그인별 사용법

### 🔒 secret-guard — 시크릿 유출 차단 (자동)
**무엇**: 평문 시크릿이 디스크/깃에 들어가는 걸 *행동 시점에* 막습니다.

- **`secret-guard` 훅** (PreToolUse, 자동): Claude가 파일 쓰기/커밋/푸시 직전에 검사 → `sk-`·`sk-ant-`·`ghp_`·`github_pat_`·`AKIA…`·`AIza…`·`xox…`·`sk_live_`·`glpat-`·`-----BEGIN … PRIVATE KEY-----` 같은 고신뢰 시크릿이 있으면 **차단**하고 1Password 사용을 안내. (컨텍스트 토큰 비용 0)
- **`op-secrets` 스킬** (자동 로드): 환경변수·`.env`·시크릿 작업 시 Claude가 `op://` 참조 + `op run` 패턴을 따르도록 가르칩니다.

**예시**: Claude가 `.env`에 `OPENAI_API_KEY=sk-proj-…`를 쓰려 하면 → 차단 → 대신 `OPENAI_API_KEY=op://Dev/OpenAI/api_key` + `op run --env-file=.env -- pnpm dev` 제안.
> 별도 호출 없이 설치만 하면 동작합니다. `op://` 참조·플레이스홀더·일반 코드는 막지 않습니다.

### 🌿 git-worktree — worktree 스쿼시 머지
**무엇**: git worktree에서 작업한 브랜치를 타깃으로 squash-merge하며, diff를 읽어 Conventional Commit 메시지를 만듭니다.

**호출** (worktree 안에서):
```
/git-worktree:merge-worktree              # 기본 브랜치(main/master)로 머지
/git-worktree:merge-worktree develop      # 지정 브랜치로 머지
/git-worktree:merge-worktree main --pr    # 로컬 머지 대신 PR 생성 (gh)
```
충돌 시 중단하고 보고하며, force-push/`--no-verify`를 쓰지 않습니다. 머지 후 worktree 정리도 안내합니다.

### 🩺 toolchain-doctor — 런타임 드리프트 진단
**무엇**: 프로젝트의 도구 버전이 어긋났는지 점검합니다. 자연어로 부르면 됩니다.

- **`asdf-doctor`** (서브에이전트): "이 프로젝트 **asdf 점검**해줘" → `.tool-versions` vs 실제 설치본 + 패키지매니저(pnpm/yarn/bun) 대조 → 정확한 `asdf install`/`asdf set` 교정 명령 제시.
- **`devcontainer-parity`** (스킬): "**devcontainer가 호스트랑 맞는지** 봐줘" → 컨테이너 런타임·포트·postCreate vs 호스트 `.tool-versions` 비교 → 불일치와 수정안 제시.

## 관리
```bash
claude plugin list                          # 설치 목록/상태
claude plugin details secret-guard@dev-toolkit   # 구성요소·토큰 비용
claude plugin update <name>@dev-toolkit     # 업데이트
claude plugin uninstall <name>@dev-toolkit  # 제거
```

---

# 🐚 A. zsh 자동화 함수

`~/.zsh.d`를 클론하고 `.zshrc`에서 source하면(위 빠른 시작) 아래 함수들이 셸에 로드됩니다. 각 함수는 호출할 때만 동작해 셸 시작이 느려지지 않습니다. 모든 `*:*` 함수는 `--help` / `--version`을 지원합니다.

## `asdf:update` — asdf 도구 일괄 업데이트
asdf로 관리되는 모든 플러그인/도구를 최신으로. 병렬 버전 조회(최대 4개), 실시간 진행률, 로그 기록.
```bash
asdf:update          # 전체 업데이트
asdf:update --help
```
> **asdf 0.19.0(Go) 호환**: 전역은 `asdf set --home`으로 `~/.tool-versions`에 기록, `asdf current`의 헤더+4컬럼 파싱, 미설정(`______`) 플러그인 자동 스킵. asdf 본체는 `brew upgrade asdf`로 먼저 업데이트.

## `brew:update` — Homebrew 전체 업데이트
Formulae + Cask + (있으면) Mac App Store(`mas`)를 한 번에. 진행률/통계 표시.
```bash
brew:update
```

## `docker:reset` — Docker 완전 초기화 ⚠️
컨테이너·이미지·볼륨·네트워크·빌드 캐시를 모두 삭제(재시도·검증 포함). **되돌릴 수 없으니 신중히.**
```bash
docker:reset         # 확인 프롬프트 후 실행
```

## `devcontainer:setup` — DevContainer 환경 생성
현재 프로젝트에 `.devcontainer/`를 생성(Dockerfile/devcontainer.json/방화벽 + 개인화 설정).
```bash
cd ~/my-project && devcontainer:setup
```
- Node.js 22 + bun, Oh My Zsh + p10k, 필수 zsh 플러그인, ccstatusline, allowlist 방화벽 포함.
- 🔒 `~/.claude`는 **안전 항목만 화이트리스트 복사** + `.devcontainer/.gitignore` 자동 생성(자격증명/세션 유출 방지).
- 이후 VS Code에서 "Dev Containers: Reopen in Container".

## tmux 세션 관리 (fzf 연동)
```bash
tmuxn           # 현재 디렉토리명으로 세션 생성/attach
tmuxn proj-a    # 'proj-a' 세션 생성/attach
tmuxl           # 세션 목록
tmuxa           # fzf로 골라 attach (tmux 안에서는 switch)
tmuxk           # fzf로 골라 kill (확인)
tmuxd           # 현재 세션에서 detach
tmuxr [name]    # 세션 이름 변경 (인자 없으면 fzf 선택)
tmuxw           # fzf로 모든 세션의 윈도우 선택 후 이동
```
**의존성**: tmux, fzf. 선택 시 윈도우 목록/화면이 preview로 표시됩니다.

## 1Password AI 키 관리 (`ai:load`)
1Password "AI Automation" Vault의 API 키들을 **환경변수로 안전하게 로드**합니다 (평문 파일 없음).
```bash
ai:load        # 키 로드 (Touch ID) — Z.AI/Gemini/Notion/GitHub/Telegram/Groq/n8n/PostgreSQL 등
ai:status      # 로드 상태 (마스킹 표시)
ai:unload      # 환경변수 전부 제거
n8n:health     # n8n 서버 상태
n8n:logs       # n8n 최근 실행 로그(5건)
```

**⚠️ 먼저 `op`(1Password CLI)를 인증해야 합니다** (안 하면 빈 값만 로드):
- **1Password 데스크톱 앱이 있으면** (권장): 앱 → **Settings → Developer → "Integrate with 1Password CLI"** 체크. 이후 `op vault ls`로 확인(Touch ID).
- **앱이 없으면**: `op signin` 또는 `op account add`로 계정 로그인.

## 편의 Alias
| Alias | 설명 |
|-------|------|
| `cc` | `claude --dangerously-skip-permissions` |

---

# 📚 레퍼런스

## 로그
모든 zsh 스크립트는 `~/.zsh.d/logs/`에 타임스탬프 로그를 남깁니다. 자동 로테이션(7일 보관, 최대 30개, chmod 600). 100MB 초과 시 경고.

## UI 특징
실시간 진행률 바, 색상+텍스트 이중 표시(색맹 지원), `NO_COLOR` 지원, 터미널 크기 자동 감지, 한글/이모지 폭 계산.

## 요구사항
| 항목 | 최소 | 권장 |
|------|------|------|
| macOS | 12.0+ | 14.0+ |
| Zsh | 5.8+ | 5.9+ |
| 터미널 | UTF-8, 80x24 | 256색, 120x40 |

함수별 의존성: `asdf:update`→asdf · `brew:update`→Homebrew(+`mas` 선택) · `docker:reset`→Docker · tmux 함수→tmux+fzf · `devcontainer:setup`→VS Code+Docker · `ai:load`→1Password CLI(`op`). Claude 플러그인→Claude Code CLI.

## 문제 해결
<details>
<summary>펼치기</summary>

**`asdf:update` "asdf가 설치되어 있지 않습니다"** — `command -v asdf` 확인, `~/.zshrc`에 `export PATH="$HOME/.asdf/shims:$PATH"` 있는지 확인.

**`brew:update` 권한 오류** — `sudo chown -R $(whoami) $(brew --prefix)/*`

**`docker:reset` "Docker가 설치되어 있지 않습니다"** — `docker ps`로 데몬 실행 확인, Docker Desktop 재시작.

**`ai:load`가 빈 값/인증 오류** — `op`가 인증됐는지 확인(`op whoami`). 위 "1Password AI 키 관리" 인증 단계 참고. CLI 미설치면 `brew install --cask 1password-cli`.

**스크립트 후 커서 안 보임** — `printf "\e[?25h"` 또는 `reset`.

**UI 깨짐** — `echo $LANG`(UTF-8), `echo $TERM`(xterm-256color 권장).

**라이브러리 로드 실패** — `ls -la ~/.zsh.d/lib/` 위치 확인.
</details>

## 테스트
```bash
zsh ~/.zsh.d/test/run_tests.zsh   # 85개 (config 47 / helpers 13 / ui 25)
```
플러그인 검증: `claude plugin validate ./plugins/<name> --strict`

## 커스터마이징
`lib/config.local.zsh`(git 미추적)를 만들어 색상·진행바 스타일·로그 보관·타임아웃 등을 오버라이드. 예시: `cp lib/config.local.zsh.example lib/config.local.zsh`. `NO_COLOR` 설정 시 색상 비활성화.

## 버전
zsh: `asdf:update` 1.4.1 · `brew:update` 1.3.0 · `docker:reset` 1.3.1 · `devcontainer:setup` 1.2.0 · `tmux_shortcuts` 1.0.0 · `ai_tools` 1.0.0 · **DEV_TOOLKIT 2.2.0**
플러그인: `git-worktree` · `secret-guard` · `toolchain-doctor` 0.1.0

자세한 변경 이력은 [CHANGELOG.md](CHANGELOG.md).

---
**작성자**: TechJuiceLab · **최종 업데이트**: 2026-06-24 · macOS + Zsh + Oh My Zsh + Powerlevel10k
