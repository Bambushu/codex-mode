# codex-mode

A Claude Code plugin that automatically delegates heavy work to Codex when your 5-hour rate limit exceeds 90%.

## How it works

Claude Code only exposes rate limit data via the statusline JSON. This plugin uses a **flag file bridge**:

1. Your statusline script watches `rate_limits.five_hour.used_percentage` and writes `~/.claude/codex-mode` when usage is high
2. This plugin's `UserPromptSubmit` hook checks for that flag before each prompt
3. If the flag exists, it injects context telling Claude to route heavy work to Codex rescue agents
4. When usage drops below 90%, the statusline removes the flag and the hook goes silent

## Requirements

- Claude Code with plugin support
- The [`codex@openai-codex`](https://github.com/openai/codex-plugin-cc) plugin installed
- A statusline script that parses `five_h` from the JSON stdin

## Installation

### 1. Install the plugin

```bash
# From local directory
claude plugin add ./codex-mode

# Or clone and install
git clone https://github.com/bambushu/codex-mode.git
claude plugin add ./codex-mode
```

### 2. Add the statusline snippet

Open your `~/.claude/statusline.sh` and paste the contents of `statusline-snippet.sh` after the line where you parse `five_h` from the JSON input.

Example -- if your statusline already has:
```bash
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
```

Paste the snippet right after that block. The snippet handles float-to-int conversion and writes/clears the flag.

## Customization

Edit `CODEX_MODE_THRESHOLD=90` in your statusline to change when delegation kicks in. Lower = earlier delegation, higher = more direct work before switching.

## Files

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin manifest |
| `hooks/hooks.json` | Registers the UserPromptSubmit hook |
| `scripts/codex-mode-check.sh` | Reads flag, emits `additionalContext` |
| `statusline-snippet.sh` | Reference snippet for your statusline |
