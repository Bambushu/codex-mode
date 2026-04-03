<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=1a1a2e&color=f97316">
    <img alt="codex-mode" src="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=f5f5f5&color=f97316">
  </picture>
</p>

<p align="center">
  <strong>Auto-delegate to Codex when you're running low on Claude Code tokens.</strong><br>
  A Claude Code plugin with graduated delegation: advisory at 70%, enforced at 85%, full at 95%.<br>
  Routes heavy work through Codex rescue agents to preserve your remaining tokens.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-v2.1.80+-blue?style=flat-square" alt="Claude Code v2.1.80+">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/requires-codex_plugin-orange?style=flat-square" alt="Requires Codex plugin">
</p>

---

## The problem

Claude Code's Max plan gives you a 5-hour rolling usage window. When you're deep in a session and burning through tokens, you have two bad options: stop working and wait for the window to reset, or keep going and risk hitting the hard limit mid-task.

**codex-mode** adds a third option: Claude gradually shifts into delegation mode as usage climbs. At 70% it gets a nudge to offload big tasks. At 85% heavy work is enforced to go through Codex. At 95% everything gets delegated. Codex runs on its own token pool, so you keep working without interruption.

## What it looks like

Your statusline shows the current tier:
```
Opus 4.6 │ ██████░░░░ 72% │ 5h:72% │ CDX:adv │ ⎇ main │ my-project
Opus 4.6 │ ████████░░ 87% │ 5h:87% │ CDX:dlg │ ⎇ main │ my-project
Opus 4.6 │ █████████░ 96% │ 5h:96% │ CDX:full │ ⎇ main │ my-project
```

**At 70% (advisory):** Claude can still write code, but gets nudged to delegate large tasks.
```
You:     "refactor the auth module"
Claude:  "This is a big refactor. Let me delegate to Codex."
         > codex:codex-rescue(Refactor auth module...)
```

**At 85% (delegation):** Heavy work must go through Codex. Small edits still allowed.
```
You:     "fix this typo on line 42"     → Claude fixes it directly
You:     "build me a REST API"          → Delegated to Codex
```

**At 95% (full):** Everything gets delegated. Claude reads, plans, and coordinates only.
```
You:     "build me a REST API with auth"
Claude:  > codex:codex-rescue(Build Express REST API with JWT auth)
         > Done (1 tool use - 15.2k tokens - 12s)
Claude:  "Done. Here's what was created: ..."
```

## How it works

```
  statusline.sh                         hooks system
  (runs every render)                   (runs on each prompt)
  ┌───────────────────┐                 ┌───────────────────┐
  │                   │                 │                   │
  │  reads JSON from  │   JSON flag    │  UserPromptSubmit │
  │  Claude Code:     │   ~/.claude/   │  hook reads flag  │
  │                   │   codex-mode   │                   │
  │  rate_limits.     │ ──────────────>│  validates:       │
  │  five_hour.       │                │  - staleness TTL  │
  │  used_percentage  │  {pct, ts,     │  - mode tier      │
  │                   │   session,     │                   │
  │  writes flag at   │   mode}        │  injects tier-    │
  │  >= 70% with tier │                │  specific context │
  │  clears at < 70%  │                │  into Claude      │
  └───────────────────┘                 └───────────────────┘
```

The flag file is a JSON object with four fields:
```json
{"pct": 87, "ts": 1743700000, "session": "my-session", "mode": "heavy_only"}
```

- **pct**: current 5h usage percentage
- **ts**: Unix timestamp (enables 15-minute staleness TTL)
- **session**: session name (for future multi-session scoping)
- **mode**: delegation tier (`advisory`, `heavy_only`, `full`)

The statusline is the **only** place Claude Code exposes rate limit data to user scripts. The flag file bridge connects that data to the hook system. The staleness TTL ensures zombie flags from crashed sessions auto-expire after 15 minutes.

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

Your statusline script needs to write a JSON flag file when usage is high. If you already parse `five_h` and `session_name` from the statusline JSON, paste this after those lines:

```bash
# codex-mode: flag file bridge with graduated tiers
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
```

If you don't have a statusline script yet, you'll need the basics first:

```bash
#!/bin/bash
input=$(cat)
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
session_name=$(echo "$input" | jq -r '.session_name // empty' 2>/dev/null)

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

# Create a test flag for each tier
printf '{"pct":72,"ts":%d,"session":"test","mode":"advisory"}\n' "$(date +%s)" > ~/.claude/codex-mode
# Start a session - Claude should mention Codex is available but still write code

printf '{"pct":88,"ts":%d,"session":"test","mode":"heavy_only"}\n' "$(date +%s)" > ~/.claude/codex-mode
# Claude should delegate big tasks but allow small edits

printf '{"pct":97,"ts":%d,"session":"test","mode":"full"}\n' "$(date +%s)" > ~/.claude/codex-mode
# Claude should delegate everything to codex:codex-rescue

# Verify the hook output directly
bash "$(claude plugin root codex-mode@bambushu 2>/dev/null || echo plugins/codex-mode)/scripts/codex-mode-check.sh" | jq .

# Clean up
rm ~/.claude/codex-mode
```

## Customization

| Tier | Range | Mode | Behavior |
|------|-------|------|----------|
| Advisory | 70-84% | `advisory` | Codex available, Claude can still write code |
| Delegation | 85-94% | `heavy_only` | Heavy work must go through Codex, small edits OK |
| Full | 95-100% | `full` | Everything delegated, Claude reads/plans only |

The thresholds are set in the statusline snippet. Adjust them to match your workflow. Want earlier delegation? Lower the numbers. Prefer to stay hands-on longer? Raise them.

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

v1.0 used a single hard constraint: "You MUST NOT write code directly." v1.1.0 uses tiered language that matches the urgency of the situation: `advisory` uses MAY/SHOULD, `heavy_only` uses MUST for big tasks, and `full` uses MUST NOT for everything. The escalation matches how you'd naturally want to conserve tokens.

### Plugin vs settings.json

The plugin registers the `UserPromptSubmit` hook automatically. The hook script reads the JSON flag, validates staleness, and emits a tier-appropriate context injection. If you prefer not to install the plugin, you can replicate this with a manual hook in `~/.claude/settings.json`, but the plugin handles the JSON parsing and tier logic for you.

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

## The story behind this

This plugin was born out of a real problem. During a long Claude Code session I noticed the statusline showing `5h:98%` and realized I was about to hit the wall. The obvious question: "Can we make Claude hand off to Codex automatically when tokens run low?"

The catch: Claude Code's rate limit data is only exposed through the statusline JSON. Hooks (the mechanism for modifying Claude's behavior) don't have access to it. So we invented the **flag file bridge** - a pattern where the statusline acts as a sensor, writing a flag file that hooks can read.

It took several iterations to get right:

1. **First attempt**: `additionalContext` at the top level - hook fired but Claude ignored it
2. **Second attempt**: found that `hookSpecificOutput` wrapping is required (discovered by reading superpowers' source code)
3. **Third attempt**: polite suggestions ("please delegate") - Claude ignored them and wrote code anyway
4. **Final version**: hard constraint language ("MUST NOT write code") - Claude actually follows it

The whole thing is 5 files and about 30 lines of bash.

## Contributing

Found a bug or have an improvement? Open an issue or PR at [github.com/Bambushu/codex-mode](https://github.com/Bambushu/codex-mode).

Ideas for future versions:
- Configurable delegation target (not just Codex)
- Multi-session scoping (session field is already in the flag, needs hook-side filtering)
- Burn-rate prediction (track usage deltas over time, trigger early if trajectory hits 100%)
- Prompt-aware task classification (score request complexity to skip delegation overhead on light questions)
- 7-day rate limit support

## License

MIT - Bambushu
