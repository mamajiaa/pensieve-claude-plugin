# Agent Guide (Pensieve)

This repo is **Pensieve**, a Claude Code knowledge/automation system with two parts:

- **Plugin (this repo)**: provides hooks that run inside Claude Code
- **Skill (copied into a user/project)**: provides pipelines/maxims/knowledge content

## Repo Structure

- `.claude-plugin/plugin.json` — plugin manifest
- `hooks/` — Claude Code hooks (executed by the plugin)
  - `inject-routes.sh` (SessionStart) — scans installed skill content and injects a “available resources” summary
  - `loop-controller.sh` (Stop) — auto-continues pending tasks in Loop mode via marker + task status
- `skills/pensieve/` — system skill shipped in the plugin (updated via plugin updates)
  - `pipelines/` — executable workflows (`_loop.md`, `_self-improve.md`, `review.md`, etc.)
  - `maxims/` — system principles (`_linus.md` built-in)
  - `decisions/` — decision format docs
  - `knowledge/` — system knowledge used by pipelines
  - `loop/` — Loop documentation + templates (loop run outputs go to project data)
  - `scripts/` — loop helpers (`init-loop.sh`, `bind-loop.sh`, `end-loop.sh`)

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
- Built-in skill files use `_` prefix (e.g. `pipelines/_*.md`, `maxims/_*.md`) and are expected to be overwritten on update; user content must live in `.claude/pensieve/`.

## Local Validation

- Syntax check scripts:
  - `bash -n hooks/*.sh skills/pensieve/scripts/*.sh skills/pensieve/scripts/_lib.sh`
- Optional lint (if installed):
  - `shellcheck hooks/*.sh skills/pensieve/scripts/*.sh skills/pensieve/scripts/_lib.sh`

## Editing Guidelines

- When changing Loop behavior, keep compatibility with:
  - marker files: `/tmp/pensieve-loop-<taskListId>`
  - tasks: `~/.claude/tasks/<taskListId>/*.json` (status: `pending|in_progress|completed`)
- When changing `_self-improve.md`, keep the “ask user before writing” gates intact.
