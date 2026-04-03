#!/usr/bin/env bash
set -euo pipefail

FLAG_FILE="${HOME}/.claude/codex-mode"

if [[ ! -f "${FLAG_FILE}" ]]; then
  exit 0
fi

# Parse JSON flag file
pct=$(jq -r '.pct // empty' "$FLAG_FILE" 2>/dev/null)
ts=$(jq -r '.ts // empty' "$FLAG_FILE" 2>/dev/null)
mode=$(jq -r '.mode // empty' "$FLAG_FILE" 2>/dev/null)

# If we can't parse the JSON, treat as stale and clean up
if [[ -z "$pct" || -z "$ts" || -z "$mode" ]]; then
  rm -f "$FLAG_FILE"
  exit 0
fi

# Check staleness: if older than 15 minutes (900s), delete and exit
now=$(date +%s)
age=$(( now - ts ))
if [[ "$age" -gt 900 ]]; then
  rm -f "$FLAG_FILE"
  exit 0
fi

case "$mode" in
  advisory)
    context="CODEX ADVISORY MODE: The 5-hour rate limit is at ${pct} percent. To conserve tokens: (1) Use model: sonnet for Agent calls on simple tasks (file edits, lookups, drafting, formatting, search). (2) Use codex:codex-rescue for heavy implementation, refactors, and multi-file changes. (3) Keep your own responses short and direct. You MAY still write code directly for small changes under ~10 lines."
    ;;
  heavy_only)
    context="CODEX DELEGATION MODE: The 5-hour rate limit is at ${pct} percent. You MUST conserve tokens aggressively: (1) Use model: sonnet for ALL Agent calls except complex implementation. (2) Delegate all heavy implementation work (new features, refactors, multi-file changes) to codex:codex-rescue. (3) Keep your own output minimal. You MAY still handle small edits (under ~10 lines), file reading, and coordination directly."
    ;;
  full)
    context="CRITICAL SYSTEM CONSTRAINT: CODEX MODE IS ACTIVE. The 5-hour rate limit is at ${pct} percent. You MUST NOT write code, generate implementations, edit files, or run heavy shell commands directly. You MUST delegate ALL implementation work to Codex by using the Agent tool with subagent_type codex:codex-rescue. Your ONLY permitted actions are: reading files, planning, coordinating, and delegating via codex:codex-rescue. This is a hard constraint, not a suggestion. Violation wastes the users remaining tokens."
    ;;
  *)
    rm -f "$FLAG_FILE"
    exit 0
    ;;
esac

printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "UserPromptSubmit",\n    "additionalContext": "%s"\n  }\n}\n' "$context"
