# Installation Guide

Pensieve uses the **official plugin structure**:

- **Plugin (system capability)**: hooks + skills, updated only via plugin updates
- **Project user data**: `.claude/pensieve/`, never overwritten by the plugin

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
- Use `/pipeline` to list project pipelines
- Run `/upgrade` first for version update pre-check (highest priority)
- Use `/init` to initialize project-level user data (first-time setup)
- Use `/loop` for split + auto-loop execution
- Use `/upgrade` to migrate user data

When the user asks to improve Pensieve (pipelines/scripts/rules/behavior),
you MUST use the Self‑Improve tool:
`tools/self-improve/_self-improve.md`
```

### 3. Initialize project user data (recommended)

Project user data lives at `.claude/pensieve/` (never overwritten by plugin updates).

> Required order: **install plugin -> initialize user data -> restart Claude Code**.
> If you restart before initialization, the model may not see seeded maxims, the default review pipeline, and review knowledge.

Option A:

```bash
mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}
```

Option B (recommended): run the initializer (seeds **initial maxims + `run-when-reviewing-code` pipeline + review knowledge**, never overwrites existing files):

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

> `<SYSTEM_SKILL_ROOT>` is injected by the SessionStart hook as an absolute path.

### 4. Restart Claude Code

Restart Claude Code only after initialization is complete, then say `loop` to verify installation.

---

## Legacy Migration

If you previously copied system content into the project (e.g., `skills/pensieve/`), use **/upgrade** to migrate and clean:

- Merge project-level maxims
- Migrate preset pipeline
- Remove legacy system copies (README and `_*.md`)

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
2. Initialize `.claude/pensieve/`
3. Restart Claude Code (do not skip)
4. **Tell the user they only need a few basic commands**:
   - `/upgrade` (version update pre-check + legacy migration, highest priority)
   - `/init` (first-time project initialization)
   - `/loop`
   - `/doctor` (optional after install; mandatory after upgrade)
   - `/selfimprove`
   - `/pipeline`

Keep the explanation short; the goal is to reduce user cognitive load.

---

## Updates

See **[Update Guide](update.md)**.

---

## Uninstall

1. Uninstall plugin: `claude plugin uninstall pensieve@kingkongshot-marketplace --scope user` (or use `/plugin`)
2. (Optional) Before deleting project data, ask the user whether they need a backup: `rm -rf .claude/pensieve`

---

## Verify Installation

After installation:

1. Run `/init` (or the equivalent script: `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh`)
2. Confirm seeded files exist:
   - at least one file under `.claude/pensieve/maxims/*.md`
   - `.claude/pensieve/pipelines/run-when-reviewing-code.md`
   - `.claude/pensieve/knowledge/taste-review/content.md`
3. Restart Claude Code
4. Say `loop` — it should trigger the Loop tool workflow
5. Check `/help` for the `pensieve` skill

> Note: `init-loop.sh` only creates the loop directory and `_agent-prompt.md`.  
> `_context.md` is created and filled in Phase 2 by the main window.

---

## FAQ

### Nothing happens after install?

1. Confirm Claude Code is restarted
2. Check `.claude/settings.json`
3. Use `/plugin` to verify the plugin is enabled

### Hooks not firing?

1. Use `/hooks` to confirm SessionStart/Stop hooks are active

### Skill not loading?

System skills ship inside the plugin. If it still doesn’t load:

1. Restart Claude Code
2. Check plugin is enabled (`/plugin`)
