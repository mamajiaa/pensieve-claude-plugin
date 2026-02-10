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

推荐执行顺序：
1. 升级插件并重启 Claude Code
2. 运行一次 `/selfimprove`（必须）
3. 根据自检结果修复或确认无需改动

If you are guiding the user, remind them they only need a few commands:
- `/loop`
- `/selfimprove`
- `/pipeline`
- `/upgrade`

如果你在引导用户，提醒他们只需掌握几个基础命令：
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
