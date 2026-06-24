#!/usr/bin/env bash
# secret-guard — PreToolUse hook
# Blocks high-confidence PLAINTEXT secrets in Edit/Write/MultiEdit content and in
# Bash commands (e.g. `git commit`, `echo KEY=... > .env`) before they hit disk or git.
#
# Contract:
#   - exit 2  => BLOCK the tool call; stderr is shown to Claude as the reason.
#   - exit 0  => allow.
#   - Fails OPEN: on any internal/parse error it exits 0 so it never wedges normal work.
#
# It scans the RAW hook payload (stdin JSON) so it needs no jq/python and does not
# depend on the exact tool_input field layout.

set -uo pipefail

INPUT="$(cat 2>/dev/null)" || exit 0
[ -z "${INPUT:-}" ] && exit 0

# Neutralize legitimate references so they never trip the scanner:
#   op:// secret references, ${ENV_VARS}/$ENV_VARS, and obvious placeholders.
SCAN="$INPUT"
SCAN="$(printf '%s' "$SCAN" | sed -E 's@op://[^"[:space:]]+@OP_REF@g' 2>/dev/null)" || SCAN="$INPUT"
SCAN="$(printf '%s' "$SCAN" | sed -E 's/\$\{?[A-Za-z_][A-Za-z0-9_]*\}?/ENV_VAR/g' 2>/dev/null)" || true
# (We deliberately do NOT strip "example"/"your-"/"xxx" substrings: the patterns below
#  are already high-confidence and won't match generic placeholders, and substring
#  stripping was neutering real keys that happen to contain those words, e.g. AKIA…EXAMPLE.)

# High-confidence secret patterns (kept tight to minimize false positives).
PATTERNS='(sk-ant-[A-Za-z0-9_-]{20,})'
PATTERNS="$PATTERNS"'|(sk-(proj-)?[A-Za-z0-9_-]{32,})'
PATTERNS="$PATTERNS"'|(gh[pousr]_[A-Za-z0-9]{36,})'
PATTERNS="$PATTERNS"'|(github_pat_[A-Za-z0-9_]{60,})'
PATTERNS="$PATTERNS"'|(AKIA[0-9A-Z]{16})'
PATTERNS="$PATTERNS"'|(AIza[0-9A-Za-z_-]{35})'
PATTERNS="$PATTERNS"'|(xox[baprs]-[0-9A-Za-z-]{10,})'
PATTERNS="$PATTERNS"'|(sk_live_[0-9A-Za-z]{24,})'
PATTERNS="$PATTERNS"'|(rk_live_[0-9A-Za-z]{24,})'
PATTERNS="$PATTERNS"'|(glpat-[A-Za-z0-9_-]{20,})'
PATTERNS="$PATTERNS"'|(-----BEGIN [A-Z ]*PRIVATE KEY-----)'

MATCH="$(printf '%s' "$SCAN" | grep -oE "$PATTERNS" 2>/dev/null | head -1 || true)"
[ -z "${MATCH:-}" ] && exit 0

# Redact for the message (show only a short prefix).
REDACTED="$(printf '%s' "$MATCH" | sed -E 's/(.{6}).*/\1…/' 2>/dev/null || echo '***')"

cat >&2 <<EOF
🔒 secret-guard blocked this action — it contains a high-confidence plaintext secret ("$REDACTED").

Never write secrets to disk or pass them on the command line. Instead:
  • Store the secret in 1Password (vault: AI Automation) and reference it as:  op://AI Automation/<item>/<field>
  • Run the app with secrets injected at runtime:        op run --env-file=.env -- <command>
  • Materialize one-offs from a template:                op inject -i .env.tpl -o .env
  • Keep real .env files gitignored.

If this is a genuine false positive, tell the user — do not work around the guard by encoding/splitting the secret.
See the "op-secrets" skill (this plugin) for the full 1Password workflow.
EOF
exit 2
