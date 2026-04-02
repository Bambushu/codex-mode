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
  <img src="https://img.shields.io/badge/Claude_Code-v2.1.80+-blue?style=flat-square" alt="Claude Code v2.1.80+">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/requires-codex_plugin-orange?style=flat-square" alt="Requires Codex plugin">
</p>

---

## The problem

Claude Code's Max plan gives you a 5-hour rolling usage window. When you're deep in a session and hit 90%+, you have two bad options: stop working and wait for the window to reset, or keep going and risk hitting the hard limit mid-task.

**codex-mode** adds a third option: Claude automatically shifts into a delegation mode where it plans and coordinates, but routes all heavy code generation to OpenAI's Codex - which runs on its own separate token pool. You keep working without interruption.

## What it looks like

**Before codex-mode** (at 95% usage):
```
You:     "build me a REST API with auth"
Claude:  *writes 200 lines of Express code, burns remaining tokens*
         *hits rate limit mid-response*
```

**With codex-mode** (at 95% usage):
```
You:     "build me a REST API with auth"
Claude:  "Let me delegate this to Codex."
         > codex:codex-rescue(Build Express REST API with JWT auth)
         > Done (1 tool use - 15.2k tokens - 12s)
Claude:  "Done. Here's what was created: ..."
```

Claude can still read files, plan, think, and coordinate. It just can't write code, edit files, or run heavy commands directly. Smart delegation, not a hard stop.

## The story behind this

This plugin was born out of a real problem. During a long Claude Code session I noticed the statusline showing `5h:98%` and realized I was about to hit the wall. The obvious question: "Can we make Claude hand off to Codex automatically when tokens run low?"

The catch: Claude Code's rate limit data is only exposed through the statusline JSON. Hooks (the mechanism for modifying Claude's behavior) don't have access to it. So we invented the **flag file bridge** - a pattern where the statusline acts as a sensor, writing a flag file that hooks can read.

It took several iterations to get right:

1. **First attempt**: `additionalContext` at the top level - hook fired but Claude ignored it
2. **Second attempt**: found that `hookSpecificOutput` wrapping is required (discovered by reading superpowers' source code)
3. **Third attempt**: polite suggestions ("please delegate") - Claude ignored them and wrote code anyway
4. **Final version**: hard constraint language ("MUST NOT write code") - Claude actually follows it

The whole thing is 5 files and about 30 lines of bash.

## How it works

```
  statusline.sh                        hooks system
  (runs every render)                  (runs on each prompt)
  ┌──────────────────┐                 ┌──────────────────┐
  │                  │                 │                  │
  │  reads JSON from │   flag file    │  UserPromptSubmit│
  │  Claude Code:    │   ~/.claude/   │  hook checks for │
  │                  │   codex-mode   │  the flag file   │
  │  rate_limits.    │ ──────────────>│                  │
  │  five_hour.      │   written at   │  if found:       │
  │  used_percentage │   >= 90%       │  injects system  │
  │                  │   removed at   │  constraint into │
  │                  │   < 90%        │  Claude's context│
  └──────────────────┘                 └──────────────────┘
```

The statusline is the **only** place Claude Code exposes rate limit data to user scripts. The flag file bridge connects that data to the hook system - a pattern that could be reused for other statusline-driven automations.

### Why a flag file?

Claude Code's architecture keeps statusline data and hook data in separate pipelines. The statusline script receives rich JSON (rate limits, context window, model info) but can only output display text. Hooks can modify Claude's behavior but only receive session metadata. A flag file on disk is the simplest reliable bridge between them.

## Requirements

- **Claude Code** v2.1.80+ (needs `rate_limits` in statusline JSON)
- **[codex plugin](https://github.com/openai/codex-plugin-cc)** installed and enabled
- A **custom statusline script** (`~/.claude/statusline.sh`)
- **jq** for JSON parsing in the statusline

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
# codex-mode: flag file bridge
# Writes ~/.claude/codex-mode when 5h usage >= threshold
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
  # No rate data — clear stale flag
  [ -f "$CODEX_MODE_FLAG" ] && rm -f "$CODEX_MODE_FLAG"
fi
```

If you don't have a statusline script yet, you'll need the basics first:

```bash
#!/bin/bash
input=$(cat)
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)

# Paste the codex-mode snippet here

# Display something
echo "5h:${five_h:-?}%"
```

Save as `~/.claude/statusline.sh` and add to your `settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

### 3. Verify

```bash
# Check the plugin is installed and enabled
claude plugin list

# Create a test flag manually
echo 92 > ~/.claude/codex-mode

# Start a new session and ask Claude to write code
claude
# > "write me a fizzbuzz in Python"
# Claude should delegate to codex:codex-rescue instead of writing directly

# Clean up the test flag
rm ~/.claude/codex-mode
```

## Customization

| Setting | Where | Default | Notes |
|---------|-------|---------|-------|
| Activation threshold | `CODEX_MODE_THRESHOLD` in statusline | `90` | Percentage of 5h limit |

Lower the threshold to start delegating earlier (more conservative with tokens). Raise it to keep Claude working directly as long as possible.

## Technical details

### The hookSpecificOutput format

Claude Code requires a specific JSON format for context injection. Top-level `additionalContext` is silently ignored - it must be wrapped in `hookSpecificOutput`:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Your injected context here"
  }
}
```

This is the same mechanism the [superpowers plugin](https://github.com/obra/superpowers) uses for SessionStart context injection. We discovered the correct format by reading superpowers' source code after our initial attempts with top-level `additionalContext` were silently ignored.

### Why hard constraint language?

Early versions used polite suggestions: "Route heavy work to Codex rescue agents." Claude consistently ignored these and wrote code directly, especially when other plugins (like superpowers' brainstorming skill) encouraged engagement.

The final version uses explicit constraint language: "You MUST NOT write code directly. This is a hard constraint, not a suggestion." This consistently triggers delegation behavior.

### Plugin vs settings.json

The plugin registers the `UserPromptSubmit` hook automatically. But if you prefer not to install the plugin, you can add the hook directly to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "if [ -f ~/.claude/codex-mode ]; then printf '{\\n  \"hookSpecificOutput\": {\\n    \"hookEventName\": \"UserPromptSubmit\",\\n    \"additionalContext\": \"CRITICAL SYSTEM CONSTRAINT: CODEX MODE IS ACTIVE. You MUST NOT write code or edit files directly. Delegate ALL implementation to Codex via codex:codex-rescue.\"\\n  }\\n}\\n'; fi"
          }
        ]
      }
    ]
  }
}
```

## Files

```
plugins/codex-mode/
  .claude-plugin/plugin.json    # Plugin manifest
  hooks/hooks.json              # UserPromptSubmit hook registration
  scripts/codex-mode-check.sh   # Flag checker, emits hookSpecificOutput
  statusline-snippet.sh         # Reference snippet for your statusline
  LICENSE                       # MIT
```

## What we learned building this

A few discoveries that might be useful if you're building Claude Code plugins:

1. **Statusline JSON is the richest data source** - it gets rate limits, context window usage, model info, git state, and more. Hooks only get session metadata.
2. **`--plugin-dir` doesn't load hooks** - plugins must be installed via a marketplace for hooks to register. Use `--plugin-dir` for testing skills/agents only.
3. **`additionalContext` needs `hookSpecificOutput` wrapping** - top-level `additionalContext` in hook output is silently ignored by Claude Code.
4. **Soft suggestions don't work** - Claude will override polite delegation requests. Use explicit constraint language for behavioral changes.
5. **The flag file bridge pattern is reusable** - any statusline data can be made available to hooks this way.

## Contributing

Found a bug or have an improvement? Open an issue or PR at [github.com/Bambushu/codex-mode](https://github.com/Bambushu/codex-mode).

Ideas for future versions:
- Configurable delegation target (not just Codex)
- Gradual throttling (delegate only large tasks at 80%, everything at 95%)
- 7-day rate limit support
- Visual indicator in statusline when codex-mode is active

## License

MIT - Bambushu
