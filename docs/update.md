# Update Guide

## Plugin (Marketplace)

If you installed via Marketplace:

```bash
claude plugin marketplace update kingkongshot/Pensieve
claude plugin update pensieve@kingkongshot-marketplace --scope user
```

Then restart Claude Code to apply updates.

If you are running commands from inside a Claude Code session (model executing on your behalf), `claude` detects the nested session and blocks the command. Prefix with `CLAUDECODE=` to clear the detection variable:

```bash
CLAUDECODE= claude plugin marketplace update kingkongshot/Pensieve
CLAUDECODE= claude plugin update pensieve@kingkongshot-marketplace --scope user
```

These commands are safe to run repeatedly; if already on the latest version, they produce no changes.

> If you installed with project scope, replace `--scope user` with `--scope project`.

If you installed via `.claude/settings.json` URL, restart Claude Code to get updates.

### Update Failure Fallback

If the update command fails (network, permissions, CLI version issues, etc.), check the latest documentation on GitHub before continuing:

- [docs/update.md (main branch)](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md)

Do not proceed with the Upgrade tool until the update failure is resolved.

---

## System Skills

System prompts (tools/scripts/system knowledge) are packaged inside the plugin and update with the plugin.

---

## After Updating

Restart Claude Code and say `loop` to verify the update.

**Version check pre-requisite (required)**:
Before running the Upgrade or Doctor tools, complete "plugin update + restart" per this file first.
If already on the latest version, proceed to the next step.

**Upgrade core logic (version-first)**:
- The Upgrade tool first syncs to the latest version structure definitions (from GitHub/Marketplace)
- Then runs a full migration alignment gate (old path parallel / directory & naming drift / plugin key drift / key file content drift)
- If structure AND key file content are both consistent: Upgrade may no-op
- If ANY dimension is inconsistent: execute full migration alignment (migration + key file content alignment + old path cleanup)
- Key files (`run-when-*.md`, `knowledge/taste-review/content.md`) are replaced when content is mismatched (with backup first)
- Review dependency should be project-internalized: pipeline references `.claude/skills/pensieve/knowledge/...`, not `<SYSTEM_SKILL_ROOT>/knowledge/...`
- Final judgment is always delegated to Doctor for "what still needs adjusting in local data structure"

Then:
- Even with dirty legacy data, run the Upgrade tool first (do not treat Doctor as a pre-upgrade gate)
- Run Doctor once after every upgrade/migration (required)
- If Doctor reports migration/structure issues, run Upgrade then rerun Doctor
- If Doctor passes, run Self-Improve as needed
- After running Upgrade, Doctor, or Self-Improve, the following should be maintained:
  - Project-level `.claude/skills/pensieve/SKILL.md` (fixed routing + graph)
  - The Pensieve guidance block in Claude auto memory `~/.claude/projects/<project>/memory/MEMORY.md` (description aligned with system skill `description`)

Recommended order:
1. Check and update the plugin (or confirm already on latest version), then restart Claude Code
2. Run Upgrade (full migration alignment; no-op only if structure and key content are both consistent)
3. Run Doctor once (required)
4. If Doctor reports issues, continue with Upgrade then rerun Doctor
5. Run Self-Improve only when you want to capture reusable improvements

If you are guiding the user, remind them they only need to express these intents:
- Loop execution
- Doctor health check
- Self-Improve capture
- Upgrade migration
- View graph (read the project-level `SKILL.md` under `## Graph`)

---

## Preserved User Data

Project user data in `.claude/skills/pensieve/` is never overwritten by plugin updates:

| Directory | Content |
|------|------|
| `.claude/skills/pensieve/maxims/` | Custom maxims |
| `.claude/skills/pensieve/decisions/` | Decisions |
| `.claude/skills/pensieve/knowledge/` | Custom knowledge |
| `.claude/skills/pensieve/pipelines/` | Project pipelines |
| `.claude/skills/pensieve/loop/` | Loop history |
