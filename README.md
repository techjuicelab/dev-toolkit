# 🚀 ZSH 개발 환경 자동화 도구

개발 환경 관리를 위한 자동화된 업데이트 및 초기화 스크립트 모음입니다.

## 📋 프로젝트 개요

이 프로젝트는 macOS 개발 환경에서 다양한 도구들을 효율적으로 관리하기 위한 스크립트들을 포함합니다:

- **ASDF 버전 매니저** 자동 업데이트
- **Homebrew** 전체 업데이트
- **Docker** 완전 초기화

모든 스크립트는 실시간 진행률 표시, 컬러풀한 UI, 그리고 상세한 로깅 기능을 제공합니다.

## 📂 프로젝트 구조

```
~/.zsh.d/
├── asdf_update.sh      # ASDF 플러그인 및 도구 업데이트
├── brew_update.sh      # Homebrew 전체 업데이트
├── docker_reset.sh     # Docker 완전 초기화
├── logs/              # 실행 로그 저장 디렉토리
├── .gitignore         # Git 제외 파일 설정
└── README.md          # 이 파일
```

## ⚙️ 설치 및 설정

### 1. 디렉토리 설정
```bash
# ~/.zsh.d 디렉토리 생성 및 이동
mkdir -p ~/.zsh.d && cd ~/.zsh.d
```

### 2. 스크립트 파일 생성
스크립트 파일들을 생성하거나 복사한 후, 실행 권한을 부여하세요:

```bash
# 모든 스크립트에 실행 권한 부여
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
type asdf:update brew:update docker:reset
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
```

**기능:**
- 플러그인 자동 업데이트
- 설치된 모든 도구의 최신 버전 확인 및 업데이트
- 실시간 진행률 표시
- 상세한 로그 기록

### Homebrew 업데이트 (`brew:update`)
Homebrew Formulae, Cask, Mac App Store 앱을 한번에 업데이트합니다.

```bash
# 전체 Homebrew 환경 업데이트
brew:update

# 버전 확인
brew:update --version
# 또는
brew:update -v
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
```

**기능:**
- 실행 중인 모든 컨테이너 정지 및 삭제
- 모든 이미지, 볼륨, 네트워크 삭제
- 빌드 캐시 정리
- 시스템 정리 및 최적화

## 📊 로그 시스템

모든 스크립트는 실행 시 상세한 로그를 생성합니다:

```
~/.zsh.d/logs/
├── asdf_update_20240819_143022.log
├── brew_update_20240819_143155.log
└── docker_reset_20240819_143300.log
```

로그 파일에는 다음 정보가 포함됩니다:
- 실행 시간 및 소요 시간
- 각 단계별 진행 상황
- 오류 및 경고 메시지
- 업데이트된 항목들의 상세 정보

## 🎨 UI 특징

- **실시간 진행률 바**: 각 작업의 진행 상황을 시각적으로 표시
- **컬러풀한 출력**: 상태별로 다른 색상을 사용하여 가독성 향상
- **단계별 안내**: 현재 수행 중인 작업을 명확하게 표시
- **통계 정보**: 업데이트된 항목 수, 소요 시간 등 요약 정보 제공

## 🔧 필수 요구사항

- **macOS**: macOS 환경에서 동작
- **Zsh**: Zsh 셸 환경
- **ASDF**: 버전 매니저 (asdf:update 사용시)
- **Homebrew**: 패키지 매니저 (brew:update 사용시)
- **Docker**: 컨테이너 플랫폼 (docker:reset 사용시)

## 🛡️ 주의사항

- `docker:reset`은 모든 Docker 데이터를 삭제하므로 신중하게 사용하세요
- 업데이트 작업은 인터넷 연결이 필요합니다
- 로그 파일은 자동으로 누적되므로 주기적으로 정리해주세요

## 📝 버전 정보

현재 모든 스크립트는 **v1.2.0**입니다.

---

**개발환경**: macOS + Zsh + Oh My Zsh + Powerlevel10k  
**작성자**: TechJuiceLab  
**최종 업데이트**: 2024-08-19