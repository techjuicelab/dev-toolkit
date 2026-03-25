#!/usr/bin/env bash
# Hook: SessionStart
# Loads recent changelog entries and git log as context for new sessions.

set -euo pipefail

# Resolve the git repo root. In worktrees, $CLAUDE_PROJECT_DIR may point to the
# original repo, so prefer git rev-parse from the current working directory.
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$REPO_ROOT" || exit 0

CHANGELOG="$REPO_ROOT/docs/CHANGELOG.md"

# Build context string
CONTEXT=""

# Recent changelog entries
if [ -f "$CHANGELOG" ]; then
  RECENT_CHANGELOG=$(tail -20 "$CHANGELOG" 2>/dev/null || true)
  if [ -n "$RECENT_CHANGELOG" ]; then
    CONTEXT="$(printf 'Recent CHANGELOG entries:\n%s\n\n' "$RECENT_CHANGELOG")"
  fi
fi

# Recent git commits
RECENT_COMMITS=$(git log --oneline -10 2>/dev/null || true)
if [ -n "$RECENT_COMMITS" ]; then
  CONTEXT="$(printf '%sRecent commits:\n%s' "$CONTEXT" "$RECENT_COMMITS")"
fi

# Output as JSON for Claude Code hook system
if [ -n "$CONTEXT" ]; then
  # Escape for JSON: try python3, then jq, then manual escape
  ESCAPED=""
  if command -v python3 &>/dev/null; then
    ESCAPED=$(printf '%s' "$CONTEXT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null) || true
  fi

  if [ -z "$ESCAPED" ] && command -v jq &>/dev/null; then
    ESCAPED=$(printf '%s' "$CONTEXT" | jq -Rs '.' 2>/dev/null) || true
  fi

  # Manual fallback: escape backslashes, quotes, and newlines
  if [ -z "$ESCAPED" ]; then
    ESCAPED=$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
    ESCAPED="\"$ESCAPED\""
  fi

  printf '{"additionalContext": %s}\n' "$ESCAPED"
fi
