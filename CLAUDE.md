# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

이 프로젝트는 macOS 개발 환경 관리를 위한 ZSH 자동화 스크립트 모음입니다. 네 가지 핵심 기능을 제공합니다:

- **ASDF 버전 매니저**: 플러그인 및 개발 도구 자동 업데이트
- **Homebrew**: Formulae, Cask, Mac App Store 앱 통합 업데이트
- **Docker**: 컨테이너, 이미지, 볼륨, 네트워크 완전 초기화
- **DevContainer**: VS Code 개발 컨테이너 환경 자동 설정
- **tmux 세션 관리**: fzf 기반 세션 생성/선택/kill/rename/윈도우 이동

## 아키텍처 특징

### 공유 라이브러리 아키텍처 (v2.0)
모든 스크립트는 `lib/` 디렉토리의 공유 라이브러리를 사용합니다:
- **config.zsh**: 색상 팔레트, 레이아웃 상수, 버전 관리, 로그 설정 통합
- **ui-framework.zsh**: 화면 제어, 박스 드로잉, 진행률 바, 메시지 출력
- **helpers.zsh**: 명령어 실행/로깅, 재시도, 타임아웃, 로그 로테이션

### 주요 특징
- **진행률 표시**: 실시간 진행 바와 단계별 가중치 기반 진행 상황
- **컬러 시스템**: 256색 팔레트 + NO_COLOR 환경 변수 지원
- **접근성**: 색상 + 텍스트 레이블([INFO], [OK], [WARN], [ERROR]) 이중 표시
- **로깅 시스템**: 타임스탬프 포함, ANSI 코드 자동 제거, 자동 로테이션
- **터미널 감지**: tput으로 크기 동적 감지, 최소 80x24 권장

### 함수 구조 패턴
각 스크립트는 동일한 구조를 따릅니다:
1. **버전/도움말**: `--version`, `--help` 플래그 처리
2. **라이브러리 로드**: `lib/ui-framework.zsh`, `lib/helpers.zsh` source
3. **초기화**: 의존성 확인, 로깅 초기화, 진행 단계 설정
4. **비즈니스 로직**: 실제 업데이트/초기화 작업
5. **정리**: 트랩을 통한 자동 커서 복원 및 터미널 상태 정리

### 한글 지원 최적화
박스 그리기와 진행률 표시에서 한글과 이모지의 터미널 표시 폭을 정확히 계산하여 UI 레이아웃의 일관성을 보장합니다.

## 개발 명령어

### 스크립트 실행
```bash
# ASDF 환경 업데이트
asdf:update

# Homebrew 전체 업데이트
brew:update

# Docker 완전 초기화
docker:reset

# DevContainer 환경 설정
devcontainer:setup

# 버전 확인
asdf:update --version
brew:update -v
docker:reset --version

# 도움말 확인
asdf:update --help
brew:update --help
docker:reset --help
devcontainer:setup --help
```

### 테스트 실행
```bash
# 전체 테스트 스위트 실행
zsh test/run_tests.zsh
```

### 설정 및 설치
```bash
# 실행 권한 부여
chmod +x ~/.zsh.d/*.sh

# ZSH 설정에 자동 로드 추가
# (README.md의 설치 가이드 참조)
source ~/.zshrc

# 함수 로드 확인
type asdf:update brew:update docker:reset devcontainer:setup
```

### 로그 관리
```bash
# 로그 파일 위치
ls ~/.zsh.d/logs/

# 최신 로그 확인
tail -f ~/.zsh.d/logs/*.log

# 로그 자동 로테이션 (7일 보관, 최대 30개)
# helpers_rotate_logs() 함수로 자동 관리됨

# 수동 정리가 필요한 경우
rm ~/.zsh.d/logs/*.log
```

## 코드 수정 시 주의사항

### UI 일관성 유지
- 모든 스크립트에서 동일한 색상 팔레트 사용 (`$COLOR_GREEN` 등, lib/config.zsh에 정의)
- `ui_create_title_box()` 함수의 박스 크기 계산 로직 보존 (lib/ui-framework.zsh)
- 진행률 업데이트는 반드시 `ui_update_progress()` 함수 사용

### 한글/이모지 처리
- 터미널 표시 폭 계산 시 한글(+1), 이모지(+1) 고려
- 박스 그리기에서 `display_width` 계산 로직 유지
- 진행률 바와 메시지에서 문자열 길이 정확히 계산

### 로깅 규칙
- 모든 명령어 실행은 `helpers_run_and_log()` 또는 `ui_log_cmd()` 함수 사용
- 로그 파일명 형식: `{스크립트명}_{YYYYMMDD_HHMMSS}.log`
- 타임스탬프 포함 메시지 로깅

### 오류 처리
- 외부 명령어 의존성 확인 (asdf, brew, docker)
- 사용자 확인 프롬프트에서 기본값을 안전한 옵션으로 설정
- 스크립트 중단 시 `ui_cleanup()` + `ui_setup_traps()`로 커서 복원

### 버전 관리
- 각 스크립트의 `VERSION` 변수 업데이트
- `--version` 또는 `-v` 플래그 지원 유지
- 기능 변경 시 버전 증가 규칙 적용

### 공유 라이브러리 수정
- `lib/config.zsh` 수정 시 모든 스크립트에 영향을 미침
- `lib/ui-framework.zsh` 수정 후 `zsh test/run_tests.zsh`로 검증
- 개인 설정은 `lib/config.local.zsh`에 오버라이드 (git 미추적)
- 새 COLOR_* 변수 추가 시 config.zsh에 정의

## 의존성 요구사항

- **Zsh**: 배열 인덱싱이 1-based임에 주의
- **ASDF**: `asdf:update` 스크립트 실행 시 필요
- **Homebrew**: `brew:update` 스크립트 실행 시 필요
- **Docker**: `docker:reset` 스크립트 실행 시 필요
- **mas**: Mac App Store 업데이트용 (선택사항)
- **tmux**: tmux 세션 관리 단축 함수 사용 시 필요
- **fzf**: tmux 단축 함수의 대화형 선택 UI 사용 시 필요

## 보안 고려사항

### 로그 파일 보안
- 로그 파일은 chmod 600으로 생성됩니다 (소유자만 읽기/쓰기)
- 로그 디렉토리는 사용자 홈 디렉토리 내에 위치합니다
- 민감한 정보(패스워드, 토큰)가 로그에 기록되지 않도록 주의하세요

### 명령어 실행
- 모든 스크립트에서 eval 사용을 제거하고 배열 기반 직접 실행을 사용합니다
- 외부 명령어는 타임아웃이 적용됩니다

### DevContainer 보안
- init-firewall.sh는 아웃바운드 네트워크를 허용 목록 기반으로 제한합니다
- iptables 규칙 변경 전 자동 백업이 수행됩니다
- 원격 스크립트는 다운로드 후 실행 방식을 사용합니다

## 테스트 시나리오

새로운 기능이나 수정사항 개발 시 다음을 확인하세요:

1. **UI 렌더링**: 다양한 터미널 크기에서 박스와 진행률 바 정상 표시
2. **한글 처리**: 한글이 포함된 메시지에서 레이아웃 깨짐 없음
3. **진행률 정확성**: 각 단계별 가중치와 전체 진행률 계산 정확성
4. **로그 무결성**: 모든 작업이 로그 파일에 기록되고 읽기 가능한 형태
5. **오류 복구**: 외부 명령어 실패 시 스크립트 안정성
6. **중단 처리**: Ctrl+C로 중단 시 cleanup 함수 정상 실행

### 자동화 테스트
```bash
# 전체 테스트 스위트 (85개 테스트)
zsh test/run_tests.zsh

# 개별 테스트 파일
# - test/test_config.zsh: 설정 변수 검증
# - test/test_helpers.zsh: 헬퍼 함수 검증
# - test/test_ui.zsh: UI 프레임워크 검증
```
