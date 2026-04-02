<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=1a1a2e&color=f97316">
    <img alt="codex-mode" src="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=f5f5f5&color=f97316">
  </picture>
</p>

<p align="center">
  <strong>Auto-delegate to Codex when you're running low on Claude Code tokens.</strong><br>
  A Claude Code plugin that detects when your 5-hour rate limit exceeds 90% and<br>
  forces Claude to route all heavy work through Codex rescue agents.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-v2.1.90+-blue?style=flat-square" alt="Claude Code v2.1.90+">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/requires-codex_plugin-orange?style=flat-square" alt="Requires Codex plugin">
</p>

---

## What it does

When your 5-hour usage hits 90%, Claude stops writing code directly and starts delegating everything to Codex:

```
You:     "build me a REST API with auth"

Normal:   Claude writes all the code itself (burns your remaining tokens)

Codex Mode:  Claude plans, then delegates to codex:codex-rescue
             (Codex runs on a separate token pool)
```

Claude can still read files, plan, and coordinate. It just can't write code, edit files, or run heavy commands. Smart delegation instead of a hard stop.

## How it works

```
                    ┌─────────────────────┐
                    │   Claude Code CLI    │
                    │                      │
                    │  statusline.sh runs  │
                    │  every render cycle  │
                    └──────────┬───────────┘
                               │
                    reads rate_limits.five_hour
                      .used_percentage from
                        statusline JSON
                               │
                    ┌──────────▼───────────┐
                    │   five_h >= 90% ?    │
                    └──────────┬───────────┘
                          yes/ \no
                            /   \
               ┌────────────┐   ┌──────────────┐
               │ write flag  │   │ remove flag   │
               │ ~/.claude/  │   │ if it exists  │
               │ codex-mode  │   │               │
               └──────┬──────┘   └───────────────┘
                      │
          on every UserPromptSubmit
                      │
               ┌──────▼──────┐
               │ hook checks │
               │  flag file  │
               └──────┬──────┘
                      │
              injects additionalContext
             into Claude's system prompt
                      │
               ┌──────▼──────┐
               │ Claude MUST  │
               │ delegate to  │
               │ codex:rescue │
               └──────────────┘
```

The statusline is the only place Claude Code exposes rate limit data. The **flag file bridge** pattern connects that data to the hook system.

## Requirements

- **Claude Code** v2.1.80+ (needs `rate_limits` in statusline JSON)
- **[codex plugin](https://github.com/openai/codex-plugin-cc)** installed and enabled (`codex@openai-codex`)
- A **statusline script** that parses the rate limit JSON

## Installation

### 1. Add the marketplace and install

```bash
# Add the Bambushu marketplace
claude plugin marketplace add https://github.com/bambushu/codex-mode

# Install the plugin
claude plugin install codex-mode@bambushu
```

### 2. Add the statusline snippet

Your statusline script needs to write a flag file when usage is high. If you already parse `five_h` from the statusline JSON, paste this after that line:

```bash
# Codex Mode -- flag file bridge
# Writes ~/.claude/codex-mode when 5h usage >= threshold
CODEX_MODE_THRESHOLD=90
CODEX_MODE_FLAG="${HOME}/.claude/codex-mode"

if [ -n "${five_h:-}" ]; then
  rate_int=$(printf '%.0f' "$five_h")
  if [ "$rate_int" -ge "$CODEX_MODE_THRESHOLD" ] 2>/dev/null; then
    [ ! -f "$CODEX_MODE_FLAG" ] && echo "$rate_int" > "$CODEX_MODE_FLAG"
  else
    [ -f "$CODEX_MODE_FLAG" ] && rm -f "$CODEX_MODE_FLAG"
  fi
fi
```

If you don't have a statusline script yet, you need to parse `five_h` first:

```bash
input=$(cat)
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
```

### 3. Verify

```bash
# Check the plugin is installed
claude plugin list

# Create a test flag and start a session
echo 92 > ~/.claude/codex-mode
claude
# Ask it to write code -- it should delegate to Codex
# Clean up: rm ~/.claude/codex-mode
```

## Customization

| Setting | Where | Default |
|---------|-------|---------|
| Activation threshold | `CODEX_MODE_THRESHOLD` in your statusline | `90` (percent) |

Lower the threshold to delegate earlier. Raise it to squeeze more direct work out of your session.

## Files

```
plugins/codex-mode/
  .claude-plugin/plugin.json    # Plugin manifest
  hooks/hooks.json              # UserPromptSubmit hook registration
  scripts/codex-mode-check.sh   # Flag checker, emits additionalContext
  statusline-snippet.sh         # Reference snippet for your statusline
```

## How the prompt injection works

The hook outputs `hookSpecificOutput` with `additionalContext` -- the same mechanism superpowers uses for SessionStart. The injected text uses strong constraint language ("MUST NOT", "hard constraint") because softer suggestions get overridden by other plugins.

```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "CRITICAL SYSTEM CONSTRAINT: CODEX MODE IS ACTIVE..."
  }
}
```

## License

MIT
