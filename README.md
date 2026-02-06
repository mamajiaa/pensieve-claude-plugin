> [!TIP]
>
> **Don't want to read docs? Just say `loop`.**
>
> Pensieve understands your intent. No commands to memorize, no docs to read.

<!-- <centered display area> -->

<div align="center">

# Pensieve

**Store your decisions and principles. Claude reads them to make better choices.**

[![GitHub Stars](https://img.shields.io/github/stars/kingkongshot/Pensieve?color=ffcb47&labelColor=black&style=flat-square)](https://github.com/kingkongshot/Pensieve/stargazers)
[![License](https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square)](LICENSE)

[Chinese README](https://github.com/kingkongshot/Pensieve/blob/zh/README.md)

</div>

<!-- </centered display area> -->

## Contents

- [Pensieve](#pensieve)
- [Just Skip Reading This Readme](#just-skip-reading-this-readme)
- [It's the Age of Agents](#its-the-age-of-agents)
- [The Magic Word: `loop`](#the-magic-word-loop)
- [For Those Who Want to Read: What Pensieve Is](#for-those-who-want-to-read-what-pensieve-is)
- [Just Install It](#just-install-it)
- [Installation](#installation)
- [For Humans](#for-humans)
- [For LLM Agents](#for-llm-agents)
- [Uninstallation](#uninstallation)
- [Features](#features)
- [Loop Mode](#loop-mode)
- [Memory System](#memory-system)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Design Philosophy](#design-philosophy)
- [Why "Pensieve"?](#why-pensieve)
- [Community](#community)
- [License](#license)

---

## Just Skip Reading This Readme

### It's the Age of Agents

**Paste this doc link to Claude Code. Let it help you understand and set up.**

If you're an LLM agent, explain to the user what this project enables right now.

### The Magic Word: `loop`

Don't want to read all this? Just include `loop` in your prompt. That's it.

Pensieve will plan, split, execute, and auto-continue until completion. The agent figures out the rest.

### For Those Who Want to Read: What Pensieve Is

Pensieve is a Claude Code plugin that turns experience into leverage:

- **Decisions** are kept so you don't repeat mistakes.
- **Maxims** capture the timeless principles you want Claude to follow.
- **Loop Mode** ensures big tasks finish without babysitting.

### Just Install It

If you only do one thing, install the plugin and initialize project memory:

1. Install the plugin
2. Add a short routing note to `CLAUDE.md`
3. Create `.claude/pensieve/`
4. Restart Claude Code

If you're an agent, you can handle this end-to-end for the user.

---

## Installation

Pensieve follows the Claude Code plugin structure:

- **Plugin (system capability)**: hooks + skills, updated only via plugin updates
- **Project user data**: `.claude/pensieve/`, never overwritten by the plugin

### For Humans

#### 1. (Recommended) Install via marketplace pinned to `main`

```bash
claude plugin marketplace add kingkongshot/Pensieve#main
claude plugin install pensieve@kingkongshot-marketplace --scope user
```

If you want to share in a team repo, install at project scope instead:

```bash
claude plugin install pensieve@kingkongshot-marketplace --scope project
```

#### 2. Add to `CLAUDE.md`

```markdown
## Pensieve
Explore the project first, then decide whether to use Pensieve tools.
Use /pipeline → /loop for complex work. Use /upgrade for data migration.
When improving Pensieve, MUST use `tools/self-improve/_self-improve.md`.
```

#### 3. Initialize project user data (recommended)

```bash
mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}
```

Or run the plugin initializer (seeds initial maxims + pipeline, does not overwrite existing files). The absolute path is injected at SessionStart:

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

#### 4. Restart Claude Code

Say `loop` to verify installation.

See **[Installation Guide](docs/installation.md)** for details, **[Update Guide](docs/update.md)** for updates, and **[Uninstall](docs/installation.md#uninstall)** for removal.

### For LLM Agents

If you're an LLM agent, help the user:

1. Add marketplace pinned to `main`
2. Install the plugin
3. Add routing instructions to `CLAUDE.md`
4. Initialize `.claude/pensieve/`
5. Remind the user to restart Claude Code
6. Tell the user they only need a few commands: `/loop`, `/selfimprove`, `/pipeline`, `/upgrade`

---

## Uninstallation

To remove Pensieve:

1. Remove the plugin:
   - `claude plugin uninstall pensieve@kingkongshot-marketplace --scope user`
   - Or `--scope project` if installed at project scope
2. (Optional) Remove project memory:
   - `rm -rf .claude/pensieve`
3. Restart Claude Code

---

## Features

Pensieve is small, opinionated, and practical. It makes Claude Code smarter by giving it memory and discipline.

### Loop Mode

Pensieve's core capability. It turns Claude Code into a self-disciplined executor.

#### Role Division

| Role | What It Does |
|------|--------------|
| **Main Window** | Planning: init → fill context → generate tasks → call subagent |
| **Subagent** | Execute single task: read context → do work → return |
| **Stop Hook** | Auto-loop: detect pending task → inject reinforcement → continue |

#### Execution Flow

```
Phase 0: Simple task check
         ↓ Complex tasks go to loop
Phase 1: Create placeholder task + init-loop.sh
         ↓
Phase 2: init-loop.sh writes marker (Stop Hook activates automatically)
         ↓
Phase 3: Fill _context.md (interaction history, final consensus, understanding & assumptions)
         ↓
Phase 4: Split tasks, user confirms
         ↓
Phase 5: Subagent executes one by one, Stop Hook auto-loops
         ↓
Phase 6: Stop Hook prompts self‑improve (optional)
```

#### Two Storage Systems

| Storage | Content | Why |
|---------|---------|-----|
| `~/.claude/tasks/<uuid>/` | Task state (JSON) | Claude Code native, for Stop Hook detection |
| `.claude/pensieve/loop/{date}-{slug}/` | Metadata + docs | Project-level tracking & learnings |

#### Automation Level

Measured by "tasks completed per Loop":

| Task Count | Level |
|------------|-------|
| < 10 | Low automation (normal early on) |
| 10-50 | Medium automation |
| 100+ | Full automation (ultimate goal) |

**Goal isn't instant perfection, but gradual improvement.**

### Memory System

Pensieve divides memory into five types. **Different memories have different lifecycles and read timing.**

| Type | What It Is | When To Read |
|------|------------|--------------|
| **Maxims** | Your character, universal principles across projects | During task execution, as judgment basis |
| **Decisions** | Your historical choices, "why I chose this then" | When facing similar situations, avoid repeating mistakes |
| **Pipelines** | Your workflows, executable closed loops | When user triggers the corresponding flow |
| **Knowledge** | External reference material | When Pipeline needs to reference |
| **Loop** | Current task context | During execution |

#### What's Worth Storing in the Pensieve?

**Maxim**: Must satisfy ALL — Still applies in different project? Different language? Different domain? Can guide unknown future problems?

**Decision**: Any ONE golden question is "yes" — Would deleting it cause mistakes? Could it lead to better choices 3 months later? Can it be taught as a pattern?

**Pipeline**: Repeating task structures. Get it working first, then refine.

#### Memory Evolution

```
Temporary decisions in Loop → filtered → Decision
Multiple similar Decisions → distilled → Maxim
External knowledge + project practice → Decision
Decision guides → Pipeline improvement
```

**Just like memories in the Pensieve reveal truth, your stored memories help Claude understand your intent.**

---

## Configuration

Use `/selfimprove` to capture learnings into **project-level user data**.

| Type | Location | Naming |
|------|----------|--------|
| Decision | `.claude/pensieve/decisions/` | `{date}-{conclusion}.md` |
| Maxim | `.claude/pensieve/maxims/custom.md` | Edit this file |
| Knowledge | `.claude/pensieve/knowledge/{name}/` | `content.md` |
| Pipeline | `.claude/pensieve/pipelines/` | `{name}.md` |

**Note**: System prompts (tools/scripts/system knowledge) are shipped inside the plugin and updated only via plugin updates.

---

## Project Structure

Pensieve is a Claude Code plugin:

- **Plugin (system capability)**: hooks + skills inside the plugin directory
- **Project user data**: `.claude/pensieve/` (never overwritten)

```
pensieve/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── hooks/                    # Auto triggers
│   ├── hooks.json           # Hook config
│   ├── inject-routes.sh     # SessionStart: scan resources, inject into context
│   └── loop-controller.sh   # Stop: detect pending task, auto-continue
└── skills/
    └── pensieve/             # System skill (shipped in plugin)
        ├── SKILL.md
        ├── tools/
        │   ├── loop/
        │   ├── pipeline/
        │   ├── upgrade/
        │   └── self-improve/
        ├── maxims/
        ├── decisions/
        ├── knowledge/
        └── pipelines/         # Format docs only (no built-in pipelines)

<project>/
└── .claude/
    └── pensieve/            # Project user data (never overwritten)
        ├── maxims/
        ├── decisions/
        ├── knowledge/
        ├── pipelines/
        └── loop/
```

### Hook System

| Hook | Trigger Time | Function |
|------|--------------|----------|
| `inject-routes.sh` | SessionStart | Inject system paths + user data overview into context |
| `loop-controller.sh` | Stop | Check for pending tasks, inject reinforcement and continue if found |

**Stop Hook is the heart of Loop mode — it makes auto-looping possible.**

---

## Design Philosophy

> [!NOTE]
>
> **On Architecture Evolution**
>
> We initially kept long prompts always in context. **This was a mistake.**
>
> Long prompts make LLM outputs verbose and unpredictable. We discovered: **loading prompts only at specific stages makes responses more reliable.**
>
> This mirrors how the Pensieve works — memories aren't always stuffed in your head, but retrieved when needed.
>
> Now, maxims and pipelines are seeded into **project-level user data** and loaded only when needed. **Load on demand, not carry everywhere.**

### Load on Demand, Not Carry Everywhere

Long prompts make LLM outputs unpredictable. Pensieve's core idea: **load only the knowledge needed at specific stages.**

- Maxims load only during task execution
- Knowledge loads only when Pipeline needs it
- Historical Decisions referenced only when facing similar situations

This is why role prompts live in tools/skills, not in CLAUDE.md.

### Document Decoupling

**Each directory's README is the single source of truth.**

- Modify a module → only change that directory's README
- Other files need to reference → write links, don't copy content

Duplicated docs rot.

### Closed-Loop Verification

**Verification must be based on actual feedback, not code inference.**

| Verification Type | Actual Feedback Source |
|-------------------|------------------------|
| Compile/Build | Compiler output, build logs |
| Test | Test run results |
| Runtime | Application logs, error stacks |

Systems don't lie. Model inference does.

### Progressive Evolution

**Achieve baseline first, then refine.**

1. Baseline: Works, has basic verification
2. Tooling: Identify repetitive/error-prone steps, build tools
3. Orchestration: Adjust order to reduce backtracking

Anti-pattern: Pursuing perfection from the start, optimizing before running.

---

## Why "Pensieve"?

In Harry Potter, a Pensieve is an ancient stone basin filled with silvery liquid memories. Wizards can extract memories from their minds with a wand and store them in the basin.

**Pensieve** combines **pensive (thoughtful)** and **sieve (filter)** — it filters and organizes thoughts.

In the story, the Pensieve repeatedly becomes key to revealing truth — someone stores memories in the basin, and the viewer enters those memories, finally understanding the context and true motivations. **Without the Pensieve, the truth could never be revealed.**

---

## Community

<img src="./QRCode.png" alt="WeChat group QR code" width="200">

---

## License

MIT
