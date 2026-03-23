#!/bin/zsh
# 파일 경로: ~/.zsh.d/tmux_shortcuts.sh
# 설명: tmux 세션 관리를 위한 fzf 연동 단축 함수 모음

# ──────────────────────────────────────────────────────────
# tmux shortcuts | fzf 기반 tmux 세션 관리
# ──────────────────────────────────────────────────────────
#
# 사용법:
#   tmuxn [name]  - 세션 생성 또는 기존 세션에 attach (기본값: 현재 디렉토리명)
#   tmuxl         - 모든 tmux 세션 목록 출력
#   tmuxa         - fzf로 세션 선택 후 attach (tmux 내부에서는 switch)
#   tmuxk         - fzf로 세션 선택 후 확인 받고 kill
#   tmuxd         - 현재 tmux 세션에서 detach
#   tmuxr [name]  - 현재 세션 이름 변경 (기본: fzf로 선택)
#   tmuxw         - fzf로 모든 세션의 윈도우를 선택하여 이동
#
# 의존성: tmux, fzf

# 세션 생성/attach - 인자 없으면 현재 디렉토리명을 세션명으로 사용
function tmuxn {
  tmux new -As "${1:-$(basename "$PWD")}"
}

# 세션 목록 출력
function tmuxl {
  tmux ls 2>/dev/null || echo "활성 세션 없음"
}

# fzf로 세션 선택 후 attach (tmux 안에서는 switch-client로 전환)
function tmuxa {
  local target
  target=$(tmux ls 2>/dev/null | fzf --prompt="Attach session > " --preview="tmux list-windows -t {1}" --delimiter=: --with-nth=1) || return 1
  target="${target%%:*}"
  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$target"
  else
    tmux attach -t "$target"
  fi
}

# fzf로 세션 선택 후 확인 받고 kill
function tmuxk {
  local target confirm
  target=$(tmux ls 2>/dev/null | fzf --prompt="Kill session > " --preview="tmux list-windows -t {1}" --delimiter=: --with-nth=1) || return 1
  target="${target%%:*}"
  read "confirm?정말 '$target' 세션을 종료할까요? [y/N]: "
  [[ "$confirm" =~ ^[Yy]$ ]] || return 1
  tmux kill-session -t "$target"
  echo "'$target' 세션 종료됨"
}

# 현재 tmux 세션에서 detach (tmux 밖에서 실행하면 안내 메시지)
function tmuxd {
  if [ -n "$TMUX" ]; then
    tmux detach-client
  else
    echo "tmux 세션 안에 있지 않습니다."
    return 1
  fi
}

# 세션 이름 변경 - 인자가 있으면 바로 변경, 없으면 fzf로 대상 선택
function tmuxr {
  local target new_name
  if [ -n "$TMUX" ] && [ -n "$1" ]; then
    # tmux 안에서 인자를 주면 현재 세션 이름을 바로 변경
    tmux rename-session "$1"
    echo "현재 세션 → '$1'"
    return
  fi
  target=$(tmux ls 2>/dev/null | fzf --prompt="Rename session > " --preview="tmux list-windows -t {1}" --delimiter=: --with-nth=1) || return 1
  target="${target%%:*}"
  read "new_name?'$target'의 새 이름: "
  [ -z "$new_name" ] && { echo "취소됨"; return 1; }
  tmux rename-session -t "$target" "$new_name"
  echo "'$target' → '$new_name'"
}

# fzf로 모든 세션의 윈도우를 선택하여 이동
function tmuxw {
  local selected
  selected=$(tmux list-windows -a -F "#{session_name}:#{window_index} #{window_name} #{?window_active,*,}" 2>/dev/null \
    | fzf --prompt="Switch window > " --preview="tmux capture-pane -t {1} -p 2>/dev/null | head -30") || return 1
  local win="${selected%% *}"
  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$win"
  else
    tmux attach -t "$win"
  fi
}
