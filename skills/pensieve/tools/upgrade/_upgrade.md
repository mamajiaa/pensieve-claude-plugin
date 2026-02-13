# Upgrade Tool

---
description: Sync to latest version structure definitions first, then migrate user data as needed (no-op if no diff)
---

You are the Upgrade Tool. Your job is to sync to the latest version first, then determine whether migration is needed based on the latest directory structure. Only execute migration when structural diff exists; otherwise output no-op and hand off to `/doctor` for local data judgment.

## Tool Contract

### Use when

- User requests a plugin version update or version status check
- User needs to migrate legacy data into `.claude/pensieve/`
- Old path parallelism exists and needs consolidation to a single source of truth
- User needs to clean old plugin naming and switch to the new reference

### Do not use when

- New project first-time setup that only needs `.claude/pensieve/` creation (route to `/init`)
- User only wants compliance status and severity grading (route to `/doctor`)
- User only wants to capture learnings or create new workflows (route to `/selfimprove`)
- User only wants to view available pipelines (route to `/pipeline`)

### Required inputs

- Latest version source (prefer GitHub / Marketplace; synced to local plugin after update)
- Version status (whether update + restart per `<PLUGIN_ROOT>/docs/update.md` is completed)
- Both settings paths:
  - `~/.claude/settings.json`
  - `<project>/.claude/settings.json`
- Current local structure (old paths and `.claude/pensieve/` directory state)

### Output contract

- Must output "structural comparison conclusion" (whether structural diff exists)
- If diff: output migration report (old path -> new path, including conflict handling)
- If no diff: explicitly output no-op (no migration needed)
- Do not output `PASS/FAIL` or `MUST_FIX/SHOULD_FIX`
- Regardless of migration outcome, always recommend next step: `/doctor`

### Failure fallback

- Update status cannot be confirmed: stop at "confirm update + restart" — do not enter migration
- Cannot pull latest version definitions: check GitHub latest docs first and suggest retry — do not enter migration
- File conflicts cannot auto-merge: generate `*.migrated.md` and record manual merge points

### Negative examples

- "Run doctor first, then decide whether to upgrade" -> conflicts with upgrade-first rule
- "Also give me PASS/FAIL during migration" -> crosses into doctor territory

Hard rule: clean up old plugin naming first, then migrate user data. Do not keep old and new naming in parallel.
Hard rule: version update pre-check is owned by Upgrade and is the highest priority gate.
Hard rule: sync latest version structure definitions from GitHub/Marketplace first, then perform local structural judgment.
Hard rule: if "no new version + no local structural diff", go straight to no-op — do not enter per-file migration.
Hard rule: after upgrade/migration, run one mandatory doctor check.
Hard rule: do not treat "run doctor before upgrade" as a gate; default flow is upgrade-first.
Hard rule: before entering migration, check plugin docs `<PLUGIN_ROOT>/docs/update.md`; if a new plugin version exists (or cannot confirm), update plugin and restart Claude Code first.
Hard rule: if update command fails, check the latest GitHub update docs ([docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md)) before continuing; do not enter migration in a failure state.

## Responsibility Boundary (Upgrade vs Doctor)

- Upgrade first handles **version update and latest structure definition sync**, then executes migration actions as needed.
- Upgrade only performs structural actions (create/copy/rename/clean/minimal merge) — no per-file semantic review.
- Upgrade should not output `PASS/FAIL` or `MUST_FIX/SHOULD_FIX` diagnosis.
- Compliance judgment and "what still needs adjusting in local data structure" is owned by `/doctor`; Upgrade only reports what was done.

## Version Check Pre-Requisite (Before Migration)

Before any migration action, sync to the latest version structure definitions:

1. Run plugin update commands per `<PLUGIN_ROOT>/docs/update.md` (pulls latest from GitHub/Marketplace).
2. If local docs are unavailable or update fails, check the latest GitHub update docs ([docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md)) and retry.
3. After running update commands:
   - New version found and updated: must restart Claude Code first, then resume `/upgrade`.
   - Already on latest (no changes): proceed directly with `/upgrade`.
4. If version status cannot be confirmed, ask the user whether "update + restart" is completed; do not enter structural judgment or migration until confirmed.

## Target Structure (Project-Level, Never Overwritten by Plugin)

```
<project>/.claude/pensieve/
  maxims/      # user/team maxims (one maxim per file)
  decisions/   # decision records (ADR)
  knowledge/   # user references
  pipelines/   # project-level pipelines
  loop/        # loop artifacts (one dir per loop)
```

## Structural Diff Gate (Judge Before Migrating)

Perform structural comparison first — no per-file deep reads:

1. Whether old path parallels exist (e.g., `skills/pensieve/`, `.claude/skills/pensieve/`).
2. Whether `.claude/pensieve/` is missing critical directories or naming (e.g., `run-when-*.md`).
3. Whether `enabledPlugins` has old key parallels or is missing the new key.
4. Whether the review pipeline still references plugin-internal knowledge paths (`<SYSTEM_SKILL_ROOT>/knowledge/...`).

Judgment rules:
- **No structural diff**: output no-op (no migration needed), then proceed to `/doctor`.
- **Structural diff found**: execute minimal migration actions, then proceed to `/doctor`.

## Migration Principles

- Clean old plugin identifiers first: remove old install references and old keys in `settings.json` before data migration.
- Old references to clean:
  - `pensieve@Pensieve`
  - `pensieve@pensieve-claude-plugin`
- New single reference:
  - `pensieve@kingkongshot-marketplace`
- System capability stays inside the plugin: content under `<SYSTEM_SKILL_ROOT>/` is plugin-managed; do not move or overwrite it.
- Old system files are no longer needed: remove old project copies after migration (never touch plugin internals).
- No-diff means no migration: if the structural gate passes, go straight to no-op — no per-file deliberation.
- Review dependency internalization: `.claude/pensieve/pipelines/run-when-reviewing-code.md` should reference `.claude/pensieve/knowledge/taste-review/content.md`, not plugin paths.
- User data is project-level: migrate only user-authored content into `.claude/pensieve/`.
- Do not overwrite user data: if target files exist, keep them; suffix or merge as needed.
- Preserve structure: keep subdirectory hierarchy and filenames as much as possible.
- Seed initial content from templates: initial maxims and pipeline templates are copied from plugin templates.
- If versions diverge: read both versions first, then follow directory README rules for merge/migration.

## Common Old Locations for User Data

May exist in:

- `skills/pensieve/` or its subdirectories in the project repo
- user-created `maxims/`, `decisions/`, `knowledge/`, `pipelines/`, `loop/` folders

### What to migrate

- User-authored files (non-system):
  - `maxims/*.md` (non-`_` files)
  - `decisions/*.md`
  - `knowledge/*`
  - `pipelines/*.md`
  - `loop/*`

> Older versions shipped `maxims/_linus.md` and `pipelines/review.md` inside plugin/project copies. If still used, copy content into:
> - `.claude/pensieve/maxims/{your-maxim}.md`
> - `.claude/pensieve/pipelines/run-when-reviewing-code.md`
> Then delete old copies to avoid confusion.

### Template locations (plugin)

- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/maxims/*.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.run-when-reviewing-code.md`
- `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md` (project knowledge seed source)

### What NOT to migrate

- System files (usually `_`-prefixed):
  - `pipelines/_*.md`
  - `maxims/_*.md`
  - system README/templates/scripts in old copied locations

## Clean Up Old System Files (Project Only)

After migration, delete old system copies inside the project to avoid confusion:

- `<project>/skills/pensieve/`
- `<project>/.claude/skills/pensieve/`
- old system `README.md` and `_*.md` prompt files

If unsure whether something is a system copy, back it up before deleting.

## Clean Up Old Plugin Naming (Must Run First)

Before migrating user data, check these files:

- user scope: `~/.claude/settings.json`
- project scope: `<project>/.claude/settings.json`

In `enabledPlugins`:

- remove `pensieve@Pensieve`
- remove `pensieve@pensieve-claude-plugin`
- keep/add `pensieve@kingkongshot-marketplace: true`

If multiple keys exist, do not keep compatibility keys. Leave only the new key.

## Migration Steps (Best done by an LLM, execution-focused)

1. Run "Version Check Pre-Requisite (Before Migration)" to ensure latest version structure definitions are synced.
2. Run "Structural Diff Gate" (old path parallel / directory missing / naming drift / plugin key drift).
3. If no structural diff:
   - Output no-op: `No migration needed`
   - Proceed directly to `/doctor` for local data structure judgment
   - End upgrade
4. If structural diff exists, enter migration:
   - Fix `enabledPlugins` (remove old keys, keep new key)
   - Clean old install references (if present)
   - Execute minimal structural migration (directory creation, naming normalization, old copy cleanup)
   - If `.claude/pensieve/knowledge/taste-review/content.md` is missing, seed from plugin knowledge
   - Rewrite review pipeline references from `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md` to `.claude/pensieve/knowledge/taste-review/content.md`
   - Only do minimal merge on conflicts (produce `*.migrated.md` when needed)
5. Output migration report (structural diff -> actions taken -> results).
6. Mandatory post-migration `/doctor` run:
   - Doctor issues `PASS/FAIL` and specific "what still needs adjusting" list
   - Upgrade does not do additional per-file semantic repair at this stage

## Plugin Cleanup and Update Commands (In Order)

When running `claude` commands from inside a Claude Code session (model executing on your behalf), prefix with `CLAUDECODE=` to clear the nested session detection variable.

```bash
# Remove old install references (ignore if not installed)
CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope user || true
CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope user || true

# If project-scope install exists, clean it too
CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope project || true
CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope project || true

# Refresh marketplace and update new plugin reference
CLAUDECODE= claude plugin marketplace update kingkongshot/Pensieve
CLAUDECODE= claude plugin update pensieve@kingkongshot-marketplace --scope user
```

## Constraints

- Do not delete plugin internal system files.
- Do not modify plugin-managed system content.
- You may edit `settings.json` only for Pensieve-related `enabledPlugins` keys.
- Do not output diagnosis-grade conclusions in upgrade stage (`MUST_FIX/SHOULD_FIX`).
