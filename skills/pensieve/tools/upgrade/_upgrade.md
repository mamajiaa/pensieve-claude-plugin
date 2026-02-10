# Upgrade Tool

---
description: Guide user data upgrade to project-level `.claude/pensieve/` structure
---

You are the Upgrade Tool. Your job is to explain the ideal user data directory structure and guide migration from old layouts to the new one. You do not decide user content; you only define paths and rules.

Hard rule: clean up old plugin naming first, then migrate user data. Do not keep old and new naming in parallel.
Hard rule: after upgrade/migration, run one mandatory self-improve pass as a post-upgrade self-check.

## Target Structure (Project-Level, Never Overwritten by Plugin)

```
<project>/.claude/pensieve/
  maxims/      # user/team maxims (e.g. custom.md)
  decisions/   # decision records (ADR)
  knowledge/   # user references
  pipelines/   # project-level pipelines
  loop/        # loop artifacts (one dir per loop)
```

## Migration Principles

- Clean old plugin identifiers first: remove old install references and old keys in `settings.json` before data migration.
- Old references to clean:
  - `pensieve@Pensieve`
  - `pensieve@pensieve-claude-plugin`
- New single reference:
  - `pensieve@kingkongshot-marketplace`
- System capability stays inside the plugin: content under `<SYSTEM_SKILL_ROOT>/` is plugin-managed; do not move or overwrite it.
- Old system files are no longer needed: remove old project copies after migration (never touch plugin internals).
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
  - `maxims/custom.md` or other files without `_` prefix
  - `decisions/*.md`
  - `knowledge/*`
  - `pipelines/*.md`
  - `loop/*`

> Older versions shipped `maxims/_linus.md` and `pipelines/review.md` inside plugin/project copies. If still used, copy content into:
> - `.claude/pensieve/maxims/custom.md`
> - `.claude/pensieve/pipelines/review.md`
> Then delete old copies to avoid confusion.

### Template locations (plugin)

- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/maxims.initial.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.review.md`

### What NOT to migrate

- System files (usually `_`-prefixed):
  - `pipelines/_*.md`
  - `maxims/_*.md`
  - plugin-managed system knowledge
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

## Migration Steps (Best done by an LLM)

1. Scan and check:
   - `~/.claude/settings.json`
   - `<project>/.claude/settings.json`
2. Clean old `enabledPlugins` keys and keep/add only the new key.
3. Clean old install references:
   - uninstall `pensieve@Pensieve` if present
   - uninstall `pensieve@pensieve-claude-plugin` if present
4. Scan old locations for user content (using the rules above).
5. Create target directories:
   - `mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}`
6. Merge maxims:
   - if `.claude/pensieve/maxims/custom.md` is missing, copy from template
   - if both exist, append old content with a migration marker
7. Migrate preset pipeline (must compare content):
   - if `.claude/pensieve/pipelines/review.md` is missing, copy from template
   - if it exists, compare content:
     - same: skip
     - different: create `review.migrated.md` and add merge notes
8. Move/copy user files to target directories while preserving relative structure.
9. Resolve filename conflicts by comparing content first:
   - same: skip
   - different: append with migration marker or create `*.migrated.md`
10. Clean old system copies listed above.
11. Output a migration report (old path -> new path).
12. Mandatory post-upgrade self-check:
   - run `/selfimprove` once
   - perform one optimization pass based on the self-check result
   - treat migration as incomplete until this step is done

## Plugin Cleanup and Update Commands (In Order)

Run in this order (adjust scope as needed):

```bash
# Remove old install references (ignore if not installed)
claude plugin uninstall pensieve@Pensieve --scope user || true
claude plugin uninstall pensieve@pensieve-claude-plugin --scope user || true

# If project-scope install exists, clean it too
claude plugin uninstall pensieve@Pensieve --scope project || true
claude plugin uninstall pensieve@pensieve-claude-plugin --scope project || true

# Refresh marketplace and update new plugin reference
claude plugin marketplace update kingkongshot/Pensieve
claude plugin update pensieve@kingkongshot-marketplace --scope user
```

## Constraints

- Do not delete plugin internal system files.
- Do not modify plugin-managed system content.
- You may edit `settings.json` only for Pensieve-related `enabledPlugins` keys.
