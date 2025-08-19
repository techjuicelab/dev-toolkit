# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

이 프로젝트는 macOS 개발 환경 관리를 위한 ZSH 자동화 스크립트 모음입니다. 세 가지 핵심 기능을 제공합니다:

- **ASDF 버전 매니저**: 플러그인 및 개발 도구 자동 업데이트
- **Homebrew**: Formulae, Cask, Mac App Store 앱 통합 업데이트  
- **Docker**: 컨테이너, 이미지, 볼륨, 네트워크 완전 초기화

## 아키텍처 특징

### 통합 UI 시스템
모든 스크립트는 공통된 UI 프레임워크를 사용합니다:
- **진행률 표시**: 실시간 진행 바와 단계별 진행 상황
- **컬러 시스템**: 256색 팔레트를 사용한 상태별 색상 구분
- **로깅 시스템**: 타임스탬프가 포함된 상세 로그 파일 생성
- **화면 제어**: ANSI 이스케이프 시퀀스를 이용한 동적 화면 업데이트

### 함수 구조 패턴
각 스크립트는 동일한 구조를 따릅니다:
1. **설정 섹션**: 색상, 로그, 화면 레이아웃 상수
2. **UI 함수**: 화면 제어, 메시지 출력, 진행률 업데이트
3. **비즈니스 로직**: 실제 업데이트/초기화 작업
4. **메인 실행**: 사용자 확인, 순차적 작업 실행

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

# 버전 확인
asdf:update --version
brew:update -v
docker:reset --version
```

### 설정 및 설치
```bash
# 실행 권한 부여
chmod +x ~/.zsh.d/*.sh

# ZSH 설정에 자동 로드 추가
# (README.md의 설치 가이드 참조)
source ~/.zshrc

# 함수 로드 확인
type asdf:update brew:update docker:reset
```

### 로그 관리
```bash
# 로그 파일 위치
ls ~/.zsh.d/logs/

# 최신 로그 확인
tail -f ~/.zsh.d/logs/*.log

# 로그 정리 (수동)
rm ~/.zsh.d/logs/*.log
```

## 코드 수정 시 주의사항

### UI 일관성 유지
- 모든 스크립트에서 동일한 색상 팔레트 사용
- `create_title_box()` 또는 `create_dynamic_box()` 함수의 박스 크기 계산 로직 보존
- 진행률 업데이트는 반드시 `update_progress()` 함수 사용

### 한글/이모지 처리
- 터미널 표시 폭 계산 시 한글(+1), 이모지(+1) 고려
- 박스 그리기에서 `display_width` 계산 로직 유지
- 진행률 바와 메시지에서 문자열 길이 정확히 계산

### 로깅 규칙
- 모든 명령어 실행은 `log_cmd()` 또는 `run_and_log()` 함수 사용
- 로그 파일명 형식: `{스크립트명}_{YYYYMMDD_HHMMSS}.log`
- 타임스탬프 포함 메시지 로깅

### 오류 처리
- 외부 명령어 의존성 확인 (asdf, brew, docker)
- 사용자 확인 프롬프트에서 기본값을 안전한 옵션으로 설정
- 스크립트 중단 시 `cleanup()` 함수로 커서 복원

### 버전 관리
- 각 스크립트의 `VERSION` 변수 업데이트
- `--version` 또는 `-v` 플래그 지원 유지
- 기능 변경 시 버전 증가 규칙 적용

## 의존성 요구사항

- **Zsh**: 배열 인덱싱이 1-based임에 주의
- **ASDF**: `asdf:update` 스크립트 실행 시 필요
- **Homebrew**: `brew:update` 스크립트 실행 시 필요  
- **Docker**: `docker:reset` 스크립트 실행 시 필요
- **mas**: Mac App Store 업데이트용 (선택사항)

## 테스트 시나리오

새로운 기능이나 수정사항 개발 시 다음을 확인하세요:

1. **UI 렌더링**: 다양한 터미널 크기에서 박스와 진행률 바 정상 표시
2. **한글 처리**: 한글이 포함된 메시지에서 레이아웃 깨짐 없음
3. **진행률 정확성**: 각 단계별 가중치와 전체 진행률 계산 정확성
4. **로그 무결성**: 모든 작업이 로그 파일에 기록되고 읽기 가능한 형태
5. **오류 복구**: 외부 명령어 실패 시 스크립트 안정성
6. **중단 처리**: Ctrl+C로 중단 시 cleanup 함수 정상 실행