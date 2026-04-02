#!/usr/bin/env bash
set -euo pipefail

FLAG_FILE="${HOME}/.claude/codex-mode"

if [[ ! -f "${FLAG_FILE}" ]]; then
  exit 0
fi

printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "UserPromptSubmit",\n    "additionalContext": "CRITICAL SYSTEM CONSTRAINT: CODEX MODE IS ACTIVE. The 5-hour rate limit is above 90 percent. You MUST NOT write code, generate implementations, edit files, or run heavy shell commands directly. You MUST delegate ALL implementation work to Codex by using the Agent tool with subagent_type codex:codex-rescue. Your ONLY permitted actions are: reading files, planning, coordinating, and delegating via codex:codex-rescue. This is a hard constraint, not a suggestion. Violation wastes the users remaining tokens."\n  }\n}\n'
