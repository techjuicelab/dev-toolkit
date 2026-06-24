# Changelog

이 프로젝트의 모든 주요 변경 사항을 기록합니다.
형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따르며,
[Semantic Versioning](https://semver.org/lang/ko/)을 준수합니다.

## [2.1.1] - 2026-06-24

### Fixed
- **asdf:update** asdf 0.19.0(Go 재작성) 호환:
  - `asdf set` → `asdf set --home` 로 전역 `~/.tool-versions`에 기록 (현재 디렉터리 오염 방지)
  - `asdf current` 파싱을 헤더 + 4컬럼 출력에 대응 (`awk '$1==plugin {print $2}'`) — 매 실행마다 전체 재설치되던 문제 해결
- **docker:reset** `"docker stop"` 등 다단어 명령이 단일 토큰으로 전달되어 모든 개별 삭제가 실패(exit 127)하던 버그 수정 (`cmd` 배열화 + `"${cmd[@]}"`)
- **brew:update** cask 최신 버전 파싱이 존재하지 않는 `< ` 토큰을 잘라 쓰레기 값을 표시하던 문제 수정 (`!= ` 구분자 기준)
- **docker_reset.sh / devcontainer_setup.sh** `~/.zsh.d/lib` 폴백 누락으로 다른 디렉터리에서 실행 시 로드 실패하던 문제 수정
- **lib/config.zsh** `EMOJI` / `SCRIPT_VERSIONS`를 `typeset -gA`로 선언 (함수 내 source 시 전역에 노출되지 않던 스코프 버그)
- 대화형 `read` → `read -r` (asdf_update, ui-framework, tmux_shortcuts)

### Security
- **devcontainer:setup** `~/.claude` 전체 복사 → 안전 항목 화이트리스트 복사로 변경하여 `.credentials.json`·세션 기록·shell-snapshots 유출 방지, `.devcontainer/.gitignore` 자동 생성

### Changed
- DevContainer 베이스 이미지 `node:20` → `node:22` (node:20 EOL 2026-04-30)
- `SCRIPT_VERSIONS` 맵을 실제 스크립트 버전과 동기화 (asdf 1.4.0, brew 1.3.0)

## [2.1.0] - 2026-03-24

### Added
- tmux 세션 관리 단축 함수 (`tmux_shortcuts.sh`)
  - `tmuxn` - 세션 생성/attach (기본값: 현재 디렉토리명)
  - `tmuxl` - 세션 목록 출력
  - `tmuxa` - fzf로 세션 선택 후 attach (tmux 내부에서는 switch-client)
  - `tmuxk` - fzf로 세션 선택 후 확인 받고 kill
  - `tmuxd` - 현재 세션에서 detach
  - `tmuxr` - 세션 이름 변경 (인자 또는 fzf 선택)
  - `tmuxw` - fzf로 모든 세션의 윈도우 선택 이동
- fzf preview에서 세션 내 윈도우 목록 및 윈도우 화면 내용 표시

## [2.0.0] - 2026-03-21

### Added
- 공유 라이브러리 시스템 도입 (`lib/config.zsh`, `lib/ui-framework.zsh`, `lib/helpers.zsh`)
- 모든 스크립트에 `--help` / `-h` 플래그 지원 추가
- 로그 디렉토리 권한 사전 검사 기능
- 로그 파일 자동 로테이션 (7일 보관, 최대 30개)
- 명령어 타임아웃 처리 (`helpers_run_with_timeout`)
- 재시도 로직 (`helpers_retry`)
- 신호 처리 강화 (SIGTERM, SIGHUP 대응)
- 터미널 호환성 자동 감지 (색상 미지원 환경 대응)
- init-firewall.sh: iptables 규칙 백업/복원 메커니즘
- init-firewall.sh: 필수 명령어 사전 검사
- asdf_update.sh: 빈 플러그인 목록 처리
- asdf_update.sh: 병렬 버전 조회

### Changed
- 중복 UI 코드를 공유 라이브러리로 통합 (~480줄 중복 제거)
- `eval` 기반 명령어 실행을 배열 기반 직접 실행으로 변경 (보안 강화)
- `docker:reset` 확인 프롬프트를 재귀에서 while 루프로 변경
- 색상 변수를 `COLOR_*` 접두사로 표준화
- UI 함수를 `ui_*` 접두사로 표준화
- 헬퍼 함수를 `helpers_*` 접두사로 표준화

### Fixed
- docker_reset.sh: `draw_progress_bar()` 배열 인덱싱 버그 수정
- 미사용 변수 (`HEADER_LINES`) 제거
- devcontainer_setup.sh: 파일 복사 에러 전파 누락 수정
- init-firewall.sh: DNS 해석 실패 시 스크립트 중단 문제 수정

### Security
- `eval` 사용 제거로 명령어 인젝션 취약점 해소 (CWE-78)
- init-firewall.sh: 실패 시 iptables 규칙 자동 복원
- 로그 파일 권한 600 설정

## [1.3.1] - 2025-09-26

### Fixed
- docker:reset 안정성 개선

## [1.2.0] - 2025-09-15

### Added
- DevContainer 환경 자동화 시스템 (`devcontainer:setup`)
- SuperClaude Framework 통합
- 네트워크 보안 방화벽 설정 (init-firewall.sh)

## [1.1.0] - 2025-08-20

### Added
- 진행률 표시 시스템 (실시간 진행 바)
- 한글/이모지 터미널 표시 폭 계산
- 상세 로그 파일 생성

## [1.0.0] - 2025-08-19

### Added
- 초기 릴리스
- asdf:update - ASDF 플러그인/도구 자동 업데이트
- brew:update - Homebrew 통합 업데이트
- docker:reset - Docker 완전 초기화
