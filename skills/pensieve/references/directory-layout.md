# Project-Level Directory Layout

For structure migration history and determination rules, see `tools/doctor/migrations/README.md` (single source of truth).

## Current Target Structure

Single active root directory: `<project>/.claude/skills/pensieve/`

```
.claude/skills/pensieve/
  maxims/      # Team principles (one file per maxim)
  decisions/   # Decision records (ADR, date-conclusion naming)
  knowledge/   # External reference knowledge (one subdirectory/content.md per topic)
  pipelines/   # Project-level pipelines (must use run-when-*.md naming)
  loop/        # Loop run artifacts (one date-slug directory per loop)
```

## Key Seed Files

Seeded by `init` during initialization (idempotent, does not overwrite existing files):

- `pipelines/run-when-reviewing-code.md` — Code review workflow
- `pipelines/run-when-committing.md` — Commit workflow
- `knowledge/taste-review/content.md` — Review knowledge base
- `maxims/*.md` — Initial principles (seeded from templates)

## Auto-Maintained Files

- `SKILL.md` — Project-level routing + graph (auto-updated by tools)
- `~/.claude/projects/<project>/memory/MEMORY.md` — Claude Code auto memory entry point (Pensieve guidance block auto-maintained)

## Legacy Paths (deprecated)

The following paths are remnants from older versions and should be cleaned up after migration:

- `<project>/skills/pensieve/` — Old mixed system + user data directory
- `<project>/.claude/pensieve/` — Early user data directory
- `<user-home>/.claude/skills/pensieve/` — Old user-level data directory (should be deleted)
- `<user-home>/.claude/pensieve/` — Earlier user-level data directory (should be deleted)
- `<project>/.claude/skills/pensieve/{_pensieve-graph.md,pensieve-graph.md,graph.md}` — Old standalone graph files (should be deleted)
