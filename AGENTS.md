# Agent Guide (Pensieve)

This repo is **Pensieve**, a Claude Code knowledge/automation system with two parts:

- **Plugin (this repo)**: provides hooks that run inside Claude Code
- **Skill (shipped inside plugin)**: provides tools/maxims/knowledge content

## Repo Structure

- `.claude-plugin/plugin.json` — plugin manifest
- `hooks/` — Claude Code hooks (executed by the plugin)
  - `inject-routes.sh` (SessionStart) — scans installed skill content and injects a “available resources” summary
  - `loop-controller.sh` (Stop) — auto-continues pending tasks in Loop mode via marker + task status
- `skills/pensieve/` — system skill shipped in the plugin (updated via plugin updates)
  - `tools/` — built-in tools (`loop/`, `self-improve/`)
    - `loop/` — loop tool markdown + scripts
    - `self-improve/` — self-improve tool markdown
  - `pipelines/` — optional user-defined workflows (e.g. `review.md`)
  - `maxims/` — system principles (`_linus.md` built-in)
  - `decisions/` — decision format docs
  - `knowledge/` — system knowledge used by tools

## User Data (Project-owned)

Project-level user data lives in `.claude/pensieve/` and is never overwritten by plugin updates:

- `.claude/pensieve/maxims/`
- `.claude/pensieve/decisions/`
- `.claude/pensieve/knowledge/`
- `.claude/pensieve/loop/`

## Conventions

- Shell scripts are **bash** and should be non-interactive.
- Prefer robust defaults: `set -euo pipefail` (where applicable), quote variables, avoid unsafe globbing.
- Hooks must fail-safe: if dependencies (e.g. `jq`) are missing, exit gracefully without breaking the session.
- Built-in tool files use `_` prefix (e.g. `tools/loop/_*.md`, `tools/self-improve/_*.md`) and are expected to be overwritten on update; user content must live in `.claude/pensieve/`.

## Local Validation

- Syntax check scripts:
  - `bash -n hooks/*.sh skills/pensieve/tools/loop/scripts/*.sh skills/pensieve/tools/loop/scripts/_lib.sh`
- Optional lint (if installed):
  - `shellcheck hooks/*.sh skills/pensieve/tools/loop/scripts/*.sh skills/pensieve/tools/loop/scripts/_lib.sh`

## Editing Guidelines

- When changing Loop behavior, keep compatibility with:
  - marker files: `/tmp/pensieve-loop-<taskListId>`
  - tasks: `~/.claude/tasks/<taskListId>/*.json` (status: `pending|in_progress|completed`)
- When changing `_self-improve.md`, keep the “ask user before writing” gates intact.
