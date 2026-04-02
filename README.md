<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=1a1a2e&color=f97316">
    <img alt="codex-mode" src="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=f5f5f5&color=f97316">
  </picture>
</p>

<p align="center">
  <strong>Auto-delegate to Codex when you're running low on Claude Code tokens.</strong>
</p>

---

This is a Claude Code plugin marketplace. See **[plugins/codex-mode](plugins/codex-mode/)** for the full plugin README, installation instructions, and source code.

### Quick install

```bash
claude plugin marketplace add https://github.com/bambushu/codex-mode
claude plugin install codex-mode@bambushu
```

Then add the [statusline snippet](plugins/codex-mode/statusline-snippet.sh) to your `~/.claude/statusline.sh`.

### What it does

When your 5-hour rate limit hits 90%, Claude automatically delegates all heavy work to Codex rescue agents instead of burning your remaining tokens.

### License

MIT
