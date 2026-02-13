# Init Tool

---
description: Initialize project-level `.claude/pensieve/` user data directory and seed base files (idempotent, never overwrites existing files)
---

You are the Init tool. Your job is to initialize the project-level user data directory, ensuring new projects work out of the box with self-contained dependencies (can run without the plugin).

## Tool Contract

### Use when

- New project first-time setup with Pensieve
- `.claude/pensieve/` does not exist or is missing base directories
- Need to seed initial files (maxims / review pipeline / review knowledge)

### Do not use when

- User requests a plugin version update or version status check (route to `/upgrade`)
- Need to migrate legacy directories or clean old copies (route to `/upgrade`)
- Need compliance judgment and severity grading (route to `/doctor`)
- Need to capture learnings or improve workflows (route to `/selfimprove`)

### Required inputs

- `<SYSTEM_SKILL_ROOT>` (injected by SessionStart)
- Project root path (current repository)
- Completed `/upgrade` version pre-check (or confirmed current version status)
- Initializer script: `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh`

### Output contract

- Output initialization result (target directory + seed file status)
- Explicitly state "will not overwrite existing user files"
- If legacy old paths are found, prompt user to run `/upgrade` next
- Explicitly state that the review pipeline defaults to referencing project-level `.claude/pensieve/knowledge/`

### Failure fallback

- Script execution fails: output failure reason and retry command — no silent fallback
- Missing `<SYSTEM_SKILL_ROOT>`: prompt restart / check plugin injection, then stop execution
- Version status unknown: prompt to run `/upgrade` for version pre-check before continuing init

### Negative examples

- "There's an old `skills/pensieve/` in the project, migrate it for me" -> do not continue init, route to `/upgrade`
- "Give me a PASS/FAIL health check first" -> not init's job, route to `/doctor`

## Execution Steps

1. Verify `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh` exists.
2. Run:

```bash
bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

3. Verify minimum results:
   - `.claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}` exist
   - `.claude/pensieve/pipelines/run-when-reviewing-code.md` exists
   - `.claude/pensieve/knowledge/taste-review/content.md` exists
4. If legacy directories are detected (e.g., `skills/pensieve/` or `.claude/skills/pensieve/`), append reminder: please run `/upgrade` to handle migration and cleanup.

## Constraints

- Only initialize and seed; do not perform migration or cleanup.
- Never overwrite existing user files.
- Do not output `/doctor`-style compliance severity conclusions.
