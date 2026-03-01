# Installation Guide

Pensieve uses the **official plugin structure**:

- **Plugin (system capability)**: skills + hooks (graph auto-sync enabled by default), updated only via plugin updates
- **Project user data**: `.claude/skills/pensieve/`, never overwritten by the plugin

## Quick Install

### 1. (Recommended) Install via Marketplace pinned to `main`

This lets you pick a branch or tag (e.g., the `main` branch).

Add the marketplace (pinned to `main`):

```bash
claude plugin marketplace add kingkongshot/Pensieve#main
```

Install the plugin (user scope):

```bash
claude plugin install pensieve@kingkongshot-marketplace --scope user
```

> `kingkongshot-marketplace` comes from the `name` field in `.claude-plugin/marketplace.json`.

If you want to share in a team repo, install at project scope:

```bash
claude plugin install pensieve@kingkongshot-marketplace --scope project
```

### 2. Configure `CLAUDE.md` (recommended)

> **Instruction to LLMs**: If you are the agent doing installation, **create or update** this file. Keep it short and do not overwrite existing content.

Add this to the project root (`CLAUDE.md` only):

```markdown
## Pensieve

Explore the project first, then decide whether to use Pensieve tools.

When the user needs a structured workflow:
- Run the Upgrade tool first for version update pre-check (highest priority)
- Use the Init tool to initialize project-level user data and generate an initial exploration + taste baseline (first-time setup)
- Use the Loop tool for split + auto-loop execution
- Use the Upgrade tool to migrate user data
- View the graph by reading the project-level `SKILL.md` under `## Graph`

When the user asks to improve Pensieve (pipelines/scripts/rules/behavior),
you MUST use the Self-Improve tool:
`tools/self-improve/_self-improve.md`
```

### 3. Initialize project user data (recommended)

Project user data lives at `.claude/skills/pensieve/` (never overwritten by plugin updates).

> Required order: **install plugin -> initialize user data -> restart Claude Code**.
> If you restart before initialization, the model may not see seeded maxims, the default review pipeline, and review knowledge.

Option A:

```bash
mkdir -p .claude/skills/pensieve/{maxims,decisions,knowledge,pipelines,loop}
```

Option B (recommended): run the initializer (seeds **initial maxims + review pipeline + review knowledge**, never overwrites existing files):

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

> `<SYSTEM_SKILL_ROOT>` can be derived from `CLAUDE_PLUGIN_ROOT`: `$CLAUDE_PLUGIN_ROOT/skills/pensieve`.
> The init script automatically maintains the project-level `SKILL.md`: writes fixed routing + latest graph (auto-generated, do not edit manually).
> It also maintains Claude auto memory: the Pensieve guidance block in `~/.claude/projects/<project>/memory/MEMORY.md` (description aligned with system skill `description`, guiding priority use of the `pensieve` skill).
> Note: The script only handles "directories + seeds + SKILL sync". The additional "commit history/code exploration + review pipeline taste analysis" is performed by the Init tool and does not run automatically in the script.

### 4. Restart Claude Code

Restart Claude Code only after initialization is complete, then say "use loop to complete a small task" to verify installation.

---

## Legacy Migration

If you previously copied system content into the project (e.g., `skills/pensieve/`), use the **Upgrade tool** to migrate and clean:

- Merge project-level maxims
- Align key modules and file locations (including `run-when-*.md`, `knowledge/taste-review/content.md`)
- Replace key file content when mismatched (with backup first)
- Remove legacy system copies and old directories (README and `_*.md`, deprecated paths)

---

## User Scope Install

If you want this in all projects, use user scope:

```bash
claude plugin install pensieve@kingkongshot-marketplace --scope user
```

---

## For LLM Agents

If you are an LLM agent:
1. Install the plugin
2. Initialize `.claude/skills/pensieve/`
3. Explore the project based on commit history and code, then produce an initial taste analysis using the review pipeline
4. Restart Claude Code (do not skip)
5. **Tell the user they only need to express a few basic intents**:
   - Upgrade or migrate (Upgrade)
   - Initialize (Init)
   - Split and execute (Loop)
   - Health check (Doctor -- required after init; required after upgrade)
   - Capture improvements (Self-Improve)
   - View graph (read the project-level `SKILL.md` under `## Graph`)

Keep the explanation short; the goal is to reduce user cognitive load.

---

## Updates

See **[Update Guide](update.md)**.

---

## Uninstall

1. Uninstall plugin: `claude plugin uninstall pensieve@kingkongshot-marketplace --scope user` (or use `/plugin`)
2. (Optional) Before deleting project data, ask the user whether they need a backup: `rm -rf .claude/skills/pensieve`

---

## Verify Installation

After installation:

1. Run the Init tool (or the equivalent script: `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh`)
2. Confirm seeded files exist:
   - at least one file under `.claude/skills/pensieve/maxims/*.md`
   - `.claude/skills/pensieve/pipelines/run-when-reviewing-code.md`
   - `.claude/skills/pensieve/pipelines/run-when-committing.md`
   - `.claude/skills/pensieve/knowledge/taste-review/content.md`
   - `.claude/skills/pensieve/SKILL.md` exists
   - `SKILL.md` contains auto-generated markers and a graph section
   - `~/.claude/projects/<project>/memory/MEMORY.md` exists and contains a Pensieve guidance block (aligned with the system skill `description`)
3. If you ran the full Init tool flow, confirm the output includes:
   - A commit history and code hotspot exploration summary
   - A list of candidate items for potential capture (candidates only, not auto-written)
   - A taste analysis summary based on the review pipeline
4. Restart Claude Code
5. Say "use loop to complete a small task" -- it should trigger the Loop tool workflow
6. Check `/help` for the `pensieve` skill

> Note: `init-loop.sh` only creates the loop directory and `_agent-prompt.md`.
> `_context.md` is created and filled in Phase 2 by the main window.

---

## FAQ

### Nothing happens after install?

1. Confirm Claude Code is restarted
2. Check `.claude/settings.json`
3. Use `/plugin` to verify the plugin is enabled

### Hooks not firing?

There are currently two hooks:
- `SessionStart`: Checks the session marker under the project directory (`<project>/.state/pensieve-session-marker.json`, which records version / init status / doctor self-check version). Injects a prompt only when the state is not satisfied, and provides the marker absolute path; the main window updates it by running `pensieve-session-marker.sh --mode record --event ...` after the fix is complete. The first `record` call automatically creates `<project>/.state/.gitignore` (ignoring runtime files inside `.state`).
- `PostToolUse`: After editing user data, automatically syncs the `SKILL.md` graph and maintains the Pensieve guidance block in Claude auto memory `~/.claude/projects/<project>/memory/MEMORY.md` (loop does not depend on hooks).

### Skill not loading?

System skills ship inside the plugin. If it still doesn't load:

1. Restart Claude Code
2. Check plugin is enabled (`/plugin`)
