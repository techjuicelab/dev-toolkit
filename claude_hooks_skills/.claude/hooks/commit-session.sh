#!/usr/bin/env bash
# Hook: Stop
# On session end: stages all changes, generates a conventional commit message
# via Claude headless mode (claude -p), commits, and logs to CHANGELOG.
# Falls back to a generic WIP message if claude -p fails.

set -euo pipefail

# Resolve the git repo root (worktree-safe)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$REPO_ROOT" || exit 0

# Stage all changes
git add -A 2>/dev/null || true

# Exit if nothing to commit
if git diff-index --quiet HEAD 2>/dev/null; then
  exit 0
fi

# Extract diff for commit message generation (truncated to 2000 lines)
DIFF=$(git diff --cached 2>/dev/null | head -2000)

# Generate commit message via Claude headless mode
COMMIT_MSG=""
if command -v claude &>/dev/null; then
  COMMIT_MSG=$(printf '%s' "$DIFF" | claude -p \
    "You are a commit message generator. Based on the following git diff, write a single commit message.
Rules:
- First line MUST start with 'WIP(scope): short summary' (max 72 chars)
- Always use 'WIP' as the type prefix, never feat/fix/refactor/etc.
- The first line (summary) must be in English
- If needed, add a blank line then bullet points for details in Korean
- Be concise and specific
- Output ONLY the commit message, nothing else

Example:
WIP(auth): add token refresh logic

- 토큰 만료 시 자동 갱신 로직 추가
- 리프레시 토큰 저장소 변경" 2>/dev/null) || true
fi

# Fallback if claude -p failed or returned empty
if [ -z "$COMMIT_MSG" ]; then
  FILE_COUNT=$(git diff --cached --name-only | wc -l)
  COMMIT_MSG="wip: update ${FILE_COUNT## } files"
fi

# Commit using -F - to safely handle special characters
printf '%s\n' "$COMMIT_MSG" | git commit -F - --no-verify 2>/dev/null || true

# Update CHANGELOG (create if missing)
CHANGELOG="$REPO_ROOT/docs/CHANGELOG.md"
if [ ! -f "$CHANGELOG" ]; then
  mkdir -p "$(dirname "$CHANGELOG")"
  cat > "$CHANGELOG" << 'TMPL'
# Changelog / 변경 이력

All notable changes to this project will be documented in this file.
이 프로젝트의 주요 변경사항을 기록합니다.

## [Unreleased] / 미출시

TMPL
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
FIRST_LINE=$(printf '%s' "$COMMIT_MSG" | head -1)

# Portable sed: try macOS first, then GNU
if grep -q '## \[Unreleased\]' "$CHANGELOG"; then
  if sed --version &>/dev/null 2>&1; then
    # GNU sed (Linux)
    sed -i "/## \[Unreleased\]/a\\- $TIMESTAMP: $FIRST_LINE" "$CHANGELOG" 2>/dev/null || true
  else
    # BSD sed (macOS)
    sed -i '' "/## \[Unreleased\]/a\\
- $TIMESTAMP: $FIRST_LINE" "$CHANGELOG" 2>/dev/null || true
  fi
fi

git add "$CHANGELOG" 2>/dev/null || true
if ! git diff-index --quiet HEAD 2>/dev/null; then
  git commit -m "docs: auto-update changelog" --no-verify 2>/dev/null || true
fi
