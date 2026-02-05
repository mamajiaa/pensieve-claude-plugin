> [!TIP]
>
> **Don't want to read docs? Just say `loop`.**
>
> Pensieve understands your intent. No commands to memorize, no docs to read.

<!-- <centered display area> -->

<div align="center">

# Pensieve

**Store your decisions and principles. Claude reads them to make better choices.**

[![GitHub Stars](https://img.shields.io/github/stars/mamajiaa/pensieve-claude-plugin?color=ffcb47&labelColor=black&style=flat-square)](https://github.com/mamajiaa/pensieve-claude-plugin/stargazers)
[![License](https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square)](LICENSE)

[中文文档](README.zh-cn.md)

</div>

<!-- </centered display area> -->

## Why "Pensieve"?

In Harry Potter, a Pensieve is an ancient stone basin filled with silvery liquid memories. Wizards can extract memories from their minds with a wand and store them in the basin.

**Pensieve** combines **pensive (thoughtful)** and **sieve (filter)** — it filters and organizes thoughts.

In the story, the Pensieve repeatedly becomes key to revealing truth — someone stores memories in the basin, and the viewer enters those memories, finally understanding the context and true motivations. **Without the Pensieve, the truth could never be revealed.**

---

> [!NOTE]
>
> **On Architecture Evolution**
>
> We initially put Linus Torvalds' role prompt in CLAUDE.md, keeping it always in context. **This was a mistake.**
>
> Long prompts make LLM outputs verbose and unpredictable. We discovered: **loading prompts only at specific stages makes responses more reliable.**
>
> This mirrors how the Pensieve works — memories aren't always stuffed in your head, but retrieved when needed.
>
> Now, Linus's maxims are split into `maxims/_linus.md`, loaded only during task execution. **Load on demand, not carry everywhere.**

---

## Table of Contents

- [What Problem Does It Solve](#what-problem-does-it-solve)
- [Installation](#installation)
- [Loop Mode](#loop-mode)
- [Five Types of Memory](#five-types-of-memory)
- [Built-in Maxims](#built-in-maxims)
- [Customization](#customization)
- [Architecture](#architecture)
- [Design Philosophy](#design-philosophy)
- [Community](#community)

---

## What Problem Does It Solve

**When Claude Code runs big tasks, you have to watch the screen, ready to intervene.**

That's annoying.

Pensieve's Loop mode lets you:
1. Describe the task, then walk away
2. Stop Hook detects incomplete tasks and auto-continues
3. Each task runs in an isolated subagent — main window won't blow up context
4. After completion, auto-compares initial assumptions vs actual findings — valuable deviations get recorded

**Your task will be completed. Period.**

---

## Skip Reading This Doc

### This Is the Agent Era

**Paste this doc link to Claude Code. Let it help you understand and set up.**

If you're an LLM agent, explain to the user what this project can do now.

### Commands (Recommended)

| Command | Purpose |
|---------|---------|
| `/loop` | Complex tasks: plan → split → auto-continue |
| `/pipeline` | List project pipelines (paths + descriptions) |
| `/upgrade` | Migrate user data to `.claude/pensieve/` |
| `/selfimprove` | Improve Pensieve system (pipelines/scripts/behavior) |

**Speak naturally. Pensieve will route to the right tool or pipeline.**

---

## Installation

Pensieve follows the **official Claude Code plugin structure**:

- **Plugin (system capability)**: hooks + skills, updated only via plugin updates
- **Project user data**: `.claude/pensieve/`, never overwritten by the plugin

### Quick Install

#### 1. (Recommended) Install via marketplace pinned to `zh`

```bash
claude plugin marketplace add mamajiaa/pensieve-claude-plugin#zh
claude plugin install pensieve@pensieve-claude-plugin --scope user
```

If you want to share in a team repo, install at project scope instead:

```bash
claude plugin install pensieve@pensieve-claude-plugin --scope project
```

#### 2. Add to CLAUDE.md (or AGENTS.md — choose one)

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

Or run the plugin initializer (does not overwrite existing files). The absolute path is injected at SessionStart:

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

#### 4. Restart Claude Code

Say `loop` to verify installation.

See **[Installation Guide](docs/installation.md)** for details. For updates, see **[Update Guide](docs/update.md)**.

### For LLM Agents

If you're an LLM agent, help the user:

1. Add marketplace pinned to `zh`:
   ```bash
   claude plugin marketplace add mamajiaa/pensieve-claude-plugin#zh
   ```
2. Install the plugin:
   ```bash
   claude plugin install pensieve@pensieve-claude-plugin --scope user
   ```
3. Add to `CLAUDE.md` (or `AGENTS.md`): brief Pensieve routing + Self‑Improve requirement
4. Initialize `.claude/pensieve/` (project user data)
5. Remind user to restart Claude Code

---

## Loop Mode

Pensieve's core capability. It turns Claude Code into a self-disciplined executor.

### Role Division

| Role | What It Does |
|------|--------------|
| **Main Window** | Planning: init → fill context → generate tasks → call subagent |
| **Subagent** | Execute single task: read context → do work → return |
| **Stop Hook** | Auto-loop: detect pending task → inject reinforcement → continue |

### Execution Flow

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

### Two Storage Systems

| Storage | Content | Why |
|---------|---------|-----|
| `~/.claude/tasks/<uuid>/` | Task state (JSON) | Claude Code native, for Stop Hook detection |
| `.claude/pensieve/loop/{date}-{slug}/` | Metadata + docs | Project-level tracking & learnings |

### Automation Level

Measured by "tasks completed per Loop":

| Task Count | Level |
|------------|-------|
| < 10 | Low automation (normal early on) |
| 10-50 | Medium automation |
| 100+ | Full automation (ultimate goal) |

**Goal isn't instant perfection, but gradual improvement.**

Early automation is low, but through self-improve after each Loop, questions it can answer for you keep growing.

---

## Built-in Maxims

We pre-stored 4 maxims from Linus Torvalds, creator of the Linux kernel.

These are what we consider the most valuable "character memories" to pass on. Top to bottom = priority — when conflicts arise, follow the one listed first.

### 1. "Good Taste" — Eliminate Edge Cases

> "Sometimes you can look at a problem from a different angle, rewrite it so special cases disappear, becoming normal cases."

**Classic example**: Linked list delete operation, 10 lines with if-check optimized to 4 lines without conditional branches.

- Eliminating edge cases always beats adding conditionals
- Trust upstream data fully; missing data should be provided upstream, not patched
- Good taste is intuition, built through experience

### 2. "Never Break Userspace" — User-visible Behavior Unchanged

> "We do not break user-visible behavior!"

- Any code that unexpectedly changes user-visible behavior is a bug, no matter how "theoretically correct"
- The kernel's job is to serve users, not educate them
- User-visible behavior unchanged (beyond requirements) is sacred

### 3. Pragmatism — Solve Real Problems

> "I'm a damn pragmatist."

**Classic example**: Delete 10 lines of fallback logic, throw error directly, exposing upstream data issues in tests rather than hiding them.

- Solve real problems, not imagined threats
- Expose problems proactively and directly
- Reject "theoretically perfect" but practically complex solutions like microkernels
- Code serves reality, not papers

### 4. Simplicity Obsession — 3 Levels of Indentation and You're Done

> "If you need more than 3 levels of indentation, you're screwed anyway, and should fix your program."

**Classic example**: 290-line giant function split into 4 single-responsibility functions, main function becomes 10 lines of assembly logic.

- Functions must be short and do one thing well
- Don't write compatibility, fallback, temporary, backup, or mode-specific code
- Code is documentation; naming serves reading
- Complexity is the root of all evil
- Default to no comments, unless explaining "why"

---

## Five Types of Memory

Pensieve divides memory into five types. **Different memories have different lifecycles and read timing.**

| Type | What It Is | When To Read |
|------|------------|--------------|
| **Maxims** | Your character, universal principles across projects | During task execution, as judgment basis |
| **Decisions** | Your historical choices, "why I chose this then" | When facing similar situations, avoid repeating mistakes |
| **Pipelines** | Your workflows, executable closed loops | When user triggers the corresponding flow |
| **Knowledge** | External reference material | When Pipeline needs to reference |
| **Loop** | Current task context | During execution |

### What's Worth Storing in the Pensieve?

**Maxim**: Must satisfy ALL — Still applies in different project? Different language? Different domain? Can guide unknown future problems?

**Decision**: Any ONE golden question is "yes" — Would deleting it cause mistakes? Could it lead to better choices 3 months later? Can it be taught as a pattern?

**Pipeline**: Repeating task structures. Get it working first, then refine.

### Memory Evolution

```
Temporary decisions in Loop → filtered → Decision
Multiple similar Decisions → distilled → Maxim
External knowledge + project practice → Decision
Decision guides → Pipeline improvement
```

**Just like memories in the Pensieve reveal truth, your stored memories help Claude understand your intent.**

---

## Customization

Use `/selfimprove` to capture learnings into **project-level user data**.

| Type | Location | Naming |
|------|----------|--------|
| Decision | `.claude/pensieve/decisions/` | `{date}-{conclusion}.md` |
| Maxim | `.claude/pensieve/maxims/custom.md` | Edit this file |
| Knowledge | `.claude/pensieve/knowledge/{name}/` | `content.md` |
| Pipeline | `.claude/pensieve/pipelines/` | `{name}.md` |

**Note**: System prompts (tools/scripts/system knowledge) are shipped inside the plugin and updated only via plugin updates.

---

## Architecture

Pensieve is an official Claude Code plugin:

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
        └── pipelines/         # System example pipelines (e.g. review)

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

If the agent hasn't finished what it started, the system forces it to continue. Your task will be completed. Period.

---

## Design Philosophy

### Load on Demand, Not Carry Everywhere

Long prompts make LLM outputs unpredictable. Pensieve's core idea: **load only the knowledge needed at specific stages.**

- Maxims load only during task execution
- Knowledge loads only when Pipeline needs it
- Historical Decisions referenced only when facing similar situations

This is why Linus's role prompt was split into Skill, not kept in CLAUDE.md.

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

## Community

<img src="./QRCode.png" alt="WeChat group QR code" width="200">

---

## License

MIT
