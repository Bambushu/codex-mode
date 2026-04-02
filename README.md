<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=1a1a2e&color=f97316">
    <img alt="codex-mode" src="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=f5f5f5&color=f97316">
  </picture>
</p>

<p align="center">
  <strong>Auto-delegate to Codex when you're running low on Claude Code tokens.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-v2.1.80+-blue?style=flat-square" alt="Claude Code v2.1.80+">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/requires-codex_plugin-orange?style=flat-square" alt="Requires Codex plugin">
</p>

---

## The problem

Claude Code's Max plan gives you a 5-hour rolling usage window. Hit the limit mid-task and you're stuck waiting. **codex-mode** solves this by detecting when you're at 90%+ and automatically making Claude delegate heavy work to Codex - which runs on its own token pool. You keep working without interruption.

## Quick install

```bash
claude plugin marketplace add https://github.com/bambushu/codex-mode
claude plugin install codex-mode@bambushu
```

Then add the [statusline snippet](plugins/codex-mode/statusline-snippet.sh) to your `~/.claude/statusline.sh`. See the **[full README](plugins/codex-mode/)** for detailed setup, the story behind it, and technical docs.

## What it looks like

```
You:     "build me a REST API with auth"

Without codex-mode:  Claude writes all the code itself (burns remaining tokens)

With codex-mode:     Claude plans, then delegates to codex:codex-rescue
                     (Codex uses a separate token pool - your Claude tokens are preserved)
```

## What we learned building this

A few discoveries for anyone building Claude Code plugins:

- **Statusline JSON is the richest data source** hooks can't access
- **Flag file bridge** pattern connects statusline data to hooks via disk
- **`hookSpecificOutput` wrapping required** for `additionalContext` injection
- **Hard constraint language needed** - polite suggestions get ignored
- **`--plugin-dir` doesn't load hooks** - must install via marketplace

Full technical writeup in the [plugin README](plugins/codex-mode/).

## License

MIT - [Bambushu](https://github.com/Bambushu)
