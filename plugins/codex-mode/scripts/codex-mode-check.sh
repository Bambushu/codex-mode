#!/usr/bin/env bash
set -euo pipefail

FLAG_FILE="${HOME}/.claude/codex-mode"

if [[ ! -f "${FLAG_FILE}" ]]; then
  exit 0
fi

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "CODEX MODE ACTIVE -- 5h rate limit is above 90%. Route ALL implementation work, code generation, code edits, test-writing, refactors, and heavy processing to Codex rescue agents (codex:codex-rescue). Only do lightweight coordination, reading, planning, and delegation directly. Delegate first, preserve your own context window."
  }
}
EOF
