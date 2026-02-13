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

Do not proceed with `/upgrade` until the update failure is resolved.

---

## System Skills

System prompts (tools/scripts/system knowledge) are packaged inside the plugin and update with the plugin.

---

## After Updating

Restart Claude Code and say `loop` to verify the update.

**Version check pre-requisite (required)**:
Before running `/upgrade` or `/doctor`, complete "plugin update + restart" per this file first.
If already on the latest version, proceed to the next step.

**Upgrade core logic (version-first)**:
- `/upgrade` first syncs to the latest version structure definitions (from GitHub/Marketplace)
- Then runs structural diff gate (old path parallel / directory & naming drift / plugin key drift)
- If no diff: `/upgrade` should no-op — no per-file migration
- If diff found: execute minimal structural migration
- Review dependency should be project-internalized: pipeline references `.claude/pensieve/knowledge/...`, not `<SYSTEM_SKILL_ROOT>/knowledge/...`
- Final judgment is always delegated to `/doctor` for "what still needs adjusting in local data structure"

Then:
- Even with dirty legacy data, run `/upgrade` first (do not treat `/doctor` as a pre-upgrade gate)
- Run `/doctor` once after every upgrade/migration (required)
- If doctor reports migration/structure issues, run `/upgrade` then rerun `/doctor`
- If doctor passes, run `/selfimprove` as needed

Recommended order:
1. Check and update the plugin (or confirm already on latest version), then restart Claude Code
2. Run `/upgrade` (structural diff first; no-op if no diff)
3. Run `/doctor` once (required)
4. If doctor reports issues, continue `/upgrade` then rerun `/doctor`
5. Run `/selfimprove` only when you want to capture reusable improvements

If you are guiding the user, remind them they only need a few commands:
- `/loop`
- `/doctor`
- `/selfimprove`
- `/pipeline`
- `/upgrade`

---

## Preserved User Data

Project user data in `.claude/pensieve/` is never overwritten by plugin updates:

| Directory | Content |
|------|------|
| `.claude/pensieve/maxims/` | Custom maxims |
| `.claude/pensieve/decisions/` | Decisions |
| `.claude/pensieve/knowledge/` | Custom knowledge |
| `.claude/pensieve/pipelines/` | Project pipelines |
| `.claude/pensieve/loop/` | Loop history |
