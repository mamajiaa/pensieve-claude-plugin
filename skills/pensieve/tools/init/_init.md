---
description: Initialize the `.claude/skills/pensieve/` directory and seed files, perform baseline exploration and code review, and produce candidate items for retention. Idempotent; never overwrites existing data.
---

# Init Tool

> Tool boundaries: `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | Shared rules: `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

Initialize the project-level user data directory, ensuring new projects work out of the box with self-contained dependencies.

## Tool Contract

### Use when
- New project first-time setup with Pensieve
- `.claude/skills/pensieve/` does not exist or is missing base directories/seed files
- After initialization, need to quickly establish a project-level review baseline

### Failure fallback
- Script execution fails: output failure reason and retry command
- Missing `<SYSTEM_SKILL_ROOT>`: prompt restart / check plugin injection, stop execution
- Repository has no commit history or Git is unavailable: skip exploration and code review, mark `SKIPPED`

## Phase 1: Directory and seed initialization

**Goal**: Create project data directories and seed all required files.

**Actions**:
1. Verify `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh` exists.
2. Run:
```bash
bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```
3. Verify minimum results: `{maxims,decisions,knowledge,pipelines,loop}` directories exist; `pipelines/run-when-reviewing-code.md`, `pipelines/run-when-committing.md`, `knowledge/taste-review/content.md` exist.
4. Verify project-level SKILL: `.claude/skills/pensieve/SKILL.md` contains auto-generated marker and graph section; `~/.claude/projects/<project>/memory/MEMORY.md` contains Pensieve guidance block.
5. If legacy directories are detected (`skills/pensieve/` or `.claude/pensieve/`), prompt user to run `upgrade`.

## Phase 2: Baseline exploration

**Goal**: Read-only scan of Git history and code structure, producing a candidate list for retention.

**Actions**:
1. Read recent commit history (default 30 commits, or user-specified window).
2. Summarize high-frequency changed files/modules and risk hotspots.
3. Produce a candidate list (annotated with suggested type: `knowledge/decision/maxim/pipeline`), each with supporting evidence. Do not list items without evidence.

## Phase 3: Code review and wrap-up

**Goal**: Run review pipeline against hotspots, output summary and next steps.

**Actions**:
1. Load `.claude/skills/pensieve/pipelines/run-when-reviewing-code.md`, using "hotspot files + recent key commits" as the review scope.
2. Output review summary (complexity hotspots, special branches, potential breaking-change risks).
3. Wrap-up output: initialization result + candidate summary + review summary.
4. Next steps: run `doctor` to check seed file format; if retention is needed, run `self-improve`.

## Constraints

- Initialization may include read-only exploration and code review, but does not directly write retention content; that is handled by `self-improve`.
- Does not perform migration cleanup; that is handled by `upgrade`.
- Never overwrites existing user files.
- Does not output `doctor`-style compliance severity conclusions.
