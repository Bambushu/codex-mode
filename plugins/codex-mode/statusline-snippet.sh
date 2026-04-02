#!/usr/bin/env bash

# Codex Mode -- statusline bridge snippet
# Paste into your ~/.claude/statusline.sh AFTER $five_h is parsed from JSON.
# Writes a flag file that the codex-mode plugin hook reads.
# Change CODEX_MODE_THRESHOLD to adjust when delegation kicks in.

CODEX_MODE_THRESHOLD=90
CODEX_MODE_FLAG="${HOME}/.claude/codex-mode"

if [ -n "${five_h:-}" ]; then
  rate_int=${five_h%%.*}       # floor — truncate decimals, no rounding
  rate_int=${rate_int:-0}
  if [ "$rate_int" -ge "$CODEX_MODE_THRESHOLD" ] 2>/dev/null; then
    [ ! -f "$CODEX_MODE_FLAG" ] && printf '%s\n' "$rate_int" > "$CODEX_MODE_FLAG"
  else
    [ -f "$CODEX_MODE_FLAG" ] && rm -f "$CODEX_MODE_FLAG"
  fi
else
  # No rate data (parse failure / missing payload) — clear stale flag
  [ -f "$CODEX_MODE_FLAG" ] && rm -f "$CODEX_MODE_FLAG"
fi
