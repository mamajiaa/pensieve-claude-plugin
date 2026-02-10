# Update Guide

## Plugin (Marketplace)

If you installed via Marketplace:

```bash
claude plugin marketplace update kingkongshot/Pensieve
claude plugin update pensieve@kingkongshot-marketplace --scope user
```

Then restart Claude Code to apply updates.

> If you installed with project scope, replace `--scope user` with `--scope project`.

If you installed via `.claude/settings.json` URL, restart Claude Code to get updates.

---

## System Skills

System prompts (tools/scripts/system knowledge) are packaged inside the plugin and update with the plugin.

---

## After Updating

Restart Claude Code and say `loop` to verify the update.

**Mandatory post-upgrade self-check (required):**
Run `/selfimprove` once after every upgrade to perform one self-check and optimization pass.
Treat the upgrade as incomplete until this self-check run is done.

Recommended order:
1. Upgrade plugin and restart Claude Code
2. Run `/selfimprove` once (required)
3. Apply fixes from the self-check result, or confirm no changes are needed

If you are guiding the user, remind them they only need a few commands:
- `/loop`
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
