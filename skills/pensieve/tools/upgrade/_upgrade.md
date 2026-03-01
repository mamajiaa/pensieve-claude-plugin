---
description: Version check and migration alignment -- sync to latest version; when a new version is available, perform structure alignment and old-path cleanup; if already up-to-date, ask whether to run doctor.
---

# Upgrade Tool

> Tool boundaries: see `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | Shared rules: see `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` | Directory conventions: see `<SYSTEM_SKILL_ROOT>/references/directory-layout.md`

Sync to the latest version first and confirm version status. If already up-to-date, stop upgrade and ask the user whether to run `doctor`; only enter migration alignment when a new version is confirmed.

## Tool Contract

### Use when

- User requests plugin version update, version status check, or migration of legacy data to `.claude/skills/pensieve/`
- User has old paths / plugin-level copies / standalone graph files / legacy spec README copies that need cleanup and consolidation

### Failure fallback

- Cannot confirm update status: stop at "confirm update + restart"; do not enter migration
- Cannot pull latest version definition: refer to GitHub latest docs and suggest retry; do not enter migration
- User file conflicts cannot auto-merge: generate `*.migrated.md` and record manual merge points

## Upgrade-Specific Rules

- Clean old plugin naming first, then migrate user data
- Pull latest version structure definitions from GitHub/Marketplace first, then make local structure judgments
- Directory history and the latest target structure use `migrations/README.md` as the single source of truth
- Version check is the only hard gate: do not enter migration before confirming a new version; if no new version, only ask whether to run `doctor`
- When update commands fail, consult [GitHub docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md) before continuing

> Global upgrade-first rule: see `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

---

## Phase 1: Version Check (Only Hard Gate)

**Goal**: Confirm whether a new version exists and decide whether to enter migration.

**Actions**:
1. Execute plugin update commands per `<PLUGIN_ROOT>/docs/update.md`
2. If update fails, consult [GitHub docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md) and retry
3. New version found and update completed: restart Claude Code first, then enter Phase 2
4. Already up-to-date: output "currently on latest version," ask user whether to run `doctor`, maintain project-level SKILL and end: `bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade skipped: version up-to-date; asked whether to run doctor"`
5. Cannot confirm version status: ask user first; do not enter migration until confirmed

## Phase 2: Structure Scan and Judgment

**Goal**: Scan current structure and determine whether migration is needed.

**Actions**:
1. Execute shared structure scan:
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh --output .state/pensieve-structure-scan.pre.json
   ```
2. Read `summary.must_fix_count`, `flags.*`, `findings[]`
3. `must_fix_count = 0` -> no-op; maintain project-level SKILL then run `doctor`: `bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade no-op after new version sync (structure + critical content aligned)"`
4. `must_fix_count > 0` -> enter Phase 3

## Phase 3: Migration Alignment

**Goal**: Clean old plugin naming, migrate user data, align key files.

### 3a. Clean Old Plugin Naming

1. Fix `enabledPlugins` (two-level settings: `~/.claude/settings.json` and `<project>/.claude/settings.json`):
   - Remove `pensieve@Pensieve`, `pensieve@pensieve-claude-plugin`
   - Keep/add `pensieve@kingkongshot-marketplace: true`
2. Execute plugin cleanup commands:
   ```bash
   CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope user || true
   CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope user || true
   CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope project || true
   CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope project || true
   CLAUDECODE= claude plugin marketplace update kingkongshot/Pensieve
   CLAUDECODE= claude plugin update pensieve@kingkongshot-marketplace --scope user
   ```

### 3b. Clean Old Directories and Copies

1. Delete old installation directories:
   - `<project>/skills/pensieve/`
   - `<project>/.claude/pensieve/`
   - `<user-home>/.claude/skills/pensieve/`
   - `<user-home>/.claude/pensieve/`
2. Delete standalone graph files: `_pensieve-graph*.md`, `pensieve-graph*.md`, `graph*.md`
3. Delete project-level subdirectory legacy spec README copies:
   ```bash
   for d in maxims decisions knowledge pipelines loop; do
     find ".claude/skills/pensieve/$d" -maxdepth 1 -type f \( -iname 'readme*.md' -o -iname 'readme' \) -delete 2>/dev/null || true
   done
   ```
4. When uncertain, back up before deleting

### 3c. Migrate User-Authored Content

Target path: `.claude/skills/pensieve/` (only user data root)

1. Migrate user files: `maxims/*.md` (non-`_` prefix), `decisions/*.md`, `knowledge/*`, `pipelines/*.md`, `loop/*`
2. Do not migrate system files (`_` prefix), legacy copied directories' system READMEs/templates/scripts
3. Old `maxims/_linus.md` and `pipelines/review.md`: merge into new naming then delete old copies
4. On conflict, do minimal merge (produce `*.migrated.md` when needed)
5. Seed from templates: initial maxims and pipeline templates come from the plugin

### 3d. Align Key Files

Overwrite targets:
- `.claude/skills/pensieve/pipelines/run-when-reviewing-code.md`
- `.claude/skills/pensieve/pipelines/run-when-committing.md`
- `.claude/skills/pensieve/knowledge/taste-review/content.md`

Template sources: `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/` and `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

Handling strategy:
- Target file missing: copy directly from template
- Target file exists but content differs: back up as `*.bak.<timestamp>` first, then replace with template
- Rewrite review pipeline path references to point to `.claude/skills/pensieve/knowledge/taste-review/content.md`

## Phase 4: Verification and Report

**Goal**: Confirm migration convergence, output report, and run doctor.

**Actions**:
1. Execute post scan:
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh --output .state/pensieve-structure-scan.post.json --fail-on-drift
   ```
2. If post scan still has MUST_FIX items, declare non-convergence and stop with a diff list
3. Output migration report (old path -> new path, replaced key files, cleaned old paths)
4. Maintain project-level SKILL: `bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade migration completed after new version sync"`
5. Output project-level `SKILL.md` update result and Claude auto memory `~/.claude/projects/<project>/memory/MEMORY.md` (Pensieve guidance block) update result
6. Run `doctor`

## Constraints

- Do not delete plugin internal system files
- Do not modify plugin-managed system content
- Only edit `settings.json` for Pensieve-related `enabledPlugins` keys
- Do not output diagnosis-grade conclusions during upgrade stage (`PASS/FAIL`, `MUST_FIX/SHOULD_FIX`)
- Do not preserve standalone graph files (graph is unified in project-level `SKILL.md#Graph`)
- Do not preserve project-level subdirectory spec README copies (spec single source of truth is in plugin-side `<SYSTEM_SKILL_ROOT>/*/README.md`)

> Data boundary (system vs user): see `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`
