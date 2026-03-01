# User Data Structure Migration Spec

Shared structure history, target layout, and processing rules for Doctor / Upgrade (single source of truth). Structure checks are implemented by the script `<SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh`.

## Current Target Structure (Latest, Active)

Sole target root directory: `<project>/.claude/skills/pensieve/`

Minimum directory structure:
- `maxims/`
- `decisions/`
- `knowledge/`
- `pipelines/`
- `loop/`

Critical files (should exist after initialization; Upgrade must align content):
- `pipelines/run-when-reviewing-code.md`
- `pipelines/run-when-committing.md`
- `knowledge/taste-review/content.md`

Critical file content sources (single source of truth):
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.run-when-reviewing-code.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.run-when-committing.md`
- `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

Auto-maintained files (tools are allowed to update):
- `SKILL.md`

## Legacy Structures and Processing Rules

| Legacy Structure | Status | Action |
|---|---|---|
| `<project>/skills/pensieve/` | deprecated | Migrate user data to target root, then delete old system copy |
| `<project>/.claude/pensieve/` | deprecated | Migrate user data to target root, then delete old directory |
| `<user-home>/.claude/skills/pensieve/` | deprecated | Delete (keep only project-level user data root) |
| `<user-home>/.claude/pensieve/` | deprecated | Delete (keep only project-level user data root) |
| `<project>/.claude/skills/pensieve/{_pensieve-graph.md,pensieve-graph.md,graph.md}` | deprecated | Delete (graph is only kept in `SKILL.md#Graph`) |
| `<project>/.claude/skills/pensieve/{maxims,decisions,knowledge,pipelines,loop}/{README*.md,readme*.md}` | deprecated | Delete (spec single source of truth is plugin-side `<SYSTEM_SKILL_ROOT>/*/README.md`) |
| `<project>/.claude/skills/pensieve/` | active | Sole read/write root directory |

## Migration Criteria (for Doctor/Upgrade)

Conditions that indicate a "structure migration issue":
1. A deprecated path co-exists with the active path (dual sources).
2. The active path is missing the minimum directory structure.
3. The active path is missing critical seed files.
4. Critical file content does not match the template.
5. Standalone graph files found (`_pensieve-graph*.md` / `pensieve-graph*.md` / `graph*.md`).
6. Legacy spec README copies found in project-level subdirectories (`{maxims,decisions,knowledge,pipelines,loop}/{README*.md,readme*.md}`).

Conditions that indicate "structure no-op":
1. Only the active path exists.
2. Minimum directory structure is complete.
3. Critical seed files are present and content matches templates.
4. No deprecated paths or standalone graph files exist.
5. No legacy spec README copies in project-level subdirectories.

## Critical File Content Alignment Strategy

When critical files are missing or content is inconsistent, Upgrade must perform full alignment:
1. If the target file exists, back it up as `*.bak.<timestamp>`.
2. Overwrite the target file using the template file.
3. List replaced files and backup paths in the migration report.

## Migration Content Boundaries

Allowed to migrate:
- `maxims/*.md` (excluding system `_` prefix files)
- `decisions/*.md`
- `knowledge/**`
- `pipelines/*.md`
- `loop/**`

Should not migrate:
- Plugin-internal system files (content under `<SYSTEM_SKILL_ROOT>/`)
- Templates/scripts/documentation from legacy system copies (unless clearly user data)
- Legacy spec README copies in project-level subdirectories (`{maxims,decisions,knowledge,pipelines,loop}/{README*.md,readme*.md}`)

## Maintenance Rules

1. When directory structure changes, update this file first, then update Doctor/Upgrade documentation.
2. If Doctor/Upgrade conflicts with this file, this file takes precedence.
