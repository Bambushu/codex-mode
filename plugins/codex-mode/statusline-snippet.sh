#!/usr/bin/env bash

# Codex Mode v1.1.0 — statusline bridge snippet
# Paste into your ~/.claude/statusline.sh AFTER parsing $five_h and $session_name from JSON.
# Writes a JSON flag file that the codex-mode plugin hook reads.
#
# Requires these variables to already be set:
#   five_h       — from: jq -r '.rate_limits.five_hour.used_percentage // empty'
#   session_name — from: jq -r '.session_name // empty'

# ── Flag file bridge with graduated tiers ────────────────────────────────────
flag="$HOME/.claude/codex-mode"

if [ -n "${five_h:-}" ]; then
  rate_int=${five_h%%.*}       # floor — truncate decimals, no rounding
  rate_int=${rate_int:-0}
  # Write flag at >= 70% with graduated delegation tiers
  if [ "$rate_int" -ge 70 ] 2>/dev/null; then
    mode="advisory"
    if [ "$rate_int" -ge 95 ] 2>/dev/null; then
      mode="full"
    elif [ "$rate_int" -ge 85 ] 2>/dev/null; then
      mode="heavy_only"
    fi
    printf '{"pct":%d,"ts":%d,"session":"%s","mode":"%s"}\n' \
      "$rate_int" "$(date +%s)" "${session_name:-}" "$mode" > "$flag"
  else
    [ -f "$flag" ] && rm -f "$flag"
  fi
fi

# ── Optional: CDX badge for your statusline ──────────────────────────────────
# Reads the flag file and sets $codex_str to a short badge.
# Add to your statusline parts array: [ -n "$codex_str" ] && parts+=("${codex_str}")

codex_str=""
if [ -f "$flag" ]; then
  codex_mode=$(jq -r '.mode // empty' "$flag" 2>/dev/null)
  case "$codex_mode" in
    advisory)   codex_str="CDX:adv" ;;
    heavy_only) codex_str="CDX:dlg" ;;
    full)       codex_str="CDX:full" ;;
  esac
fi
