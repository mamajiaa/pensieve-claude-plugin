> [!TIP]
>
> Don't want to read docs? After installation, tell Claude: `use loop to finish this task`.

<div align="center">

# Pensieve

**Turn every intervention into an automation opportunity.**

[![GitHub Stars](https://img.shields.io/github/stars/kingkongshot/Pensieve?color=ffcb47&labelColor=black&style=flat-square)](https://github.com/kingkongshot/Pensieve/stargazers)
[![License](https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square)](LICENSE)

[Chinese README](https://github.com/mamajiaa/pensieve-claude-plugin/blob/zh/README.md)

</div>

## For Users Looking for the Linus Prompt

That methodology is still here and now delivered as an executable system:

- Linus-style engineering principles are embedded as default execution rules
- Core capabilities are mounted on the Claude Code runtime chain (`skills / hooks / task / agent`)
- Code review is shipped as `run-when-reviewing-code` pipeline + knowledge

You get a full engineering package: prompting, workflow, and execution mechanics together.

## What You Get Immediately

- **Stronger breakthrough ability**: stubborn bugs move toward root-cause fixes
- **Higher code quality**: cleaner, verifiable, maintainable output
- **Harder code review**: the `run-when-reviewing-code` pipeline enforces a consistent standard
- **More stable long sessions**: on-demand loading keeps context lean
- **Less manual babysitting**: `/loop` splits, runs, and auto-continues tasks

## 30-Second Start

1. Install the plugin
2. Initialize `.claude/pensieve/`
3. Restart Claude Code
4. Type `loop`

Quick path (automation-first):

Share this README link or full text with your model and give this instruction:

`Complete Pensieve installation and initialization based on this README, then report the result.`

The model can execute installation, initialization, and verification steps automatically.

- [Installation Guide](docs/installation.md)
- [Update Guide](docs/update.md)
- [Init Tool](skills/pensieve/tools/init/_init.md)
- [Upgrade Tool](skills/pensieve/tools/upgrade/_upgrade.md)
- [Uninstall Section](docs/installation.md#uninstall)

## Why This Stays Reliable

### 1. Default principles drive execution

The system defaults prioritize root-cause repair, branch simplification, complexity control, and quality thresholds.

### 2. Context is loaded on demand

Each phase loads only what it needs: maxims for execution, review pipeline/knowledge for auditing, upgrade tool for migration.

### 3. Built on Claude Code native capabilities

- **Skills**: route intent to the right tool
- **Hooks**: SessionStart injects routes, Stop handles auto-continue
- **Task**: task state drives execution rhythm
- **Agent**: main window decomposes work, sub-agents execute

This design gives two direct benefits:

- **Lighter architecture**: native execution chain reduces wrapper complexity and maintenance overhead
- **Upgrade compounding**: Pensieve gains from Claude Code native improvements over time

## Minimal Commands to Learn

- `/init`: initialize project-level `.claude/pensieve/` (first-time setup for new projects, includes review knowledge seed)
- `/loop`: split complex work and execute in auto-loop mode
- `/doctor`: run README-driven user-data health checks
- `/pipeline`: list and invoke project pipelines
- `/selfimprove`: turn lessons into system-level improvements
- `/upgrade`: version update pre-check + legacy migration (highest priority; run `/doctor` after migration)

## Best Fit Scenarios

- Stubborn bugs that keep recurring
- High-standard code review workflows
- Long-running, complex project iterations
- Teams that want to encode personal craft into default process

## What Belongs in the Pensieve?

**Maxim**: should pass all checks. Still valid across projects? across languages? across domains? useful for future unknown problems?

**Decision**: keep it if any one of these is true. Would deleting it cause repeat mistakes? Would it help make a better choice in 3 months? Could you teach it as a reusable pattern?

**Pipeline**: any task shape that appears repeatedly. Make it runnable first, then refine.

## How Memory Evolves

```text
Temporary decisions in Loop -> filtered -> Decision
Repeated similar Decisions -> distilled -> Maxim
External knowledge + project practice -> Decision
Decisions guide -> Pipeline improvement
```

Like memory revealing truth, what you store helps Claude understand your intent.

## Community

<img src="./QRCode.png" alt="WeChat group QR code" width="200">

## License

MIT
