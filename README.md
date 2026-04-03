<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=1a1a2e&color=f97316">
    <img alt="codex-mode" src="https://img.shields.io/badge/%E2%9A%A1-codex--mode-f97316?style=for-the-badge&labelColor=f5f5f5&color=f97316">
  </picture>
</p>

<p align="center">
  <strong>Graduated Codex delegation for Claude Code: advisory at 70%, enforced at 85%, full handoff at 95%.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-v2.1.80+-blue?style=flat-square" alt="Claude Code v2.1.80+">
  <img src="https://img.shields.io/badge/version-v1.1.0-f97316?style=flat-square" alt="v1.1.0">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/requires-codex_plugin-orange?style=flat-square" alt="Requires Codex plugin">
</p>

---

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

## Quick install

```bash
claude plugin marketplace add https://github.com/bambushu/codex-mode
claude plugin install codex-mode@bambushu
```

Then add the [statusline snippet](plugins/codex-mode/statusline-snippet.sh) to your `~/.claude/statusline.sh`. See the **[full README](plugins/codex-mode/README.md)** for setup and details.

## The problem

Claude Code's Max plan gives you a 5-hour rolling usage window. Hit the limit mid-task and you're stuck waiting. **codex-mode** solves this with graduated delegation: at 70% Claude gets nudged to offload big tasks, at 85% heavy work is enforced through Codex, at 95% everything is delegated. Codex runs on its own token pool, so you keep working without interruption.

## What we learned building this

A few discoveries for anyone building Claude Code plugins:

- **Statusline JSON is the richest data source** hooks can't access
- **Flag file bridge** pattern connects statusline data to hooks via disk
- **JSON flag with TTL** prevents zombie flags from crashed sessions
- **Graduated constraint language** matches urgency to usage level
- **`hookSpecificOutput` wrapping required** for `additionalContext` injection
- **`--plugin-dir` doesn't load hooks** - must install via marketplace

Full technical writeup in the [plugin README](plugins/codex-mode/README.md).

## License

MIT - [Bambushu](https://github.com/Bambushu)
