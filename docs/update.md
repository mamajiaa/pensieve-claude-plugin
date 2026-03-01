# 更新指南

## 插件更新（Marketplace）

如果你通过 Marketplace 安装：

```bash
claude plugin marketplace update kingkongshot/Pensieve
claude plugin update pensieve@kingkongshot-marketplace --scope user
```

然后重启 Claude Code 使更新生效。

如果你是在 Claude Code 会话里让模型代执行命令，`claude` 会检测嵌套会话并拦截；此时请在命令前加 `CLAUDECODE=` 清空该变量：

```bash
CLAUDECODE= claude plugin marketplace update kingkongshot/Pensieve
CLAUDECODE= claude plugin update pensieve@kingkongshot-marketplace --scope user
```

这两条命令可重复执行；如果已经是最新版本，通常不会产生变更。

> 如果你是项目级安装，请把 `--scope user` 改为 `--scope project`。

如果你是通过 `.claude/settings.json` URL 安装，重启 Claude Code 即可拉取更新。

### 更新失败兜底

如果更新命令失败（网络、权限、CLI 版本问题等），先查看 GitHub 上的最新文档再继续：

- [docs/update.md（main 分支）](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md)

在更新失败未解决前，不建议继续执行 Upgrade 工具。

---

## 系统 Skills

系统提示词（tools/scripts/system knowledge）随插件打包，并跟随插件更新。

---

## 更新后流程

重启 Claude Code 后，输入 `loop` 验证更新是否生效。

**版本检查前置（必须）**：
在执行 Upgrade 或 Doctor 前，先按本文件完成“插件更新 + 重启”。
若已是最新版本，可直接进入下一步。

**Upgrade 核心逻辑（版本优先）**：
- Upgrade 先同步最新版本结构定义（来自 GitHub/Marketplace）
- 再做完整迁移校准门禁（旧路径并行/目录与命名差异/插件键差异/关键文件内容差异）
- 若结构与关键内容都一致：Upgrade 才允许 no-op
- 若任一项不一致：执行完整迁移校准（迁移 + 关键文件内容对齐 + 旧路径清理）
- 关键文件（`run-when-*.md`、`knowledge/taste-review/content.md`）内容不一致时默认替换（先备份）
- review 依赖应项目内化：pipeline 引用 `.claude/skills/pensieve/knowledge/...`，不依赖 `<SYSTEM_SKILL_ROOT>/knowledge/...`
- 最终统一交给 Doctor 判定“还需如何调整本地数据结构”

然后：
- 即使存在历史脏数据，也优先先执行 Upgrade（不要把 Doctor 当成升级前门槛）
- 每次升级或迁移后必须运行一次 Doctor 做基于 README 的体检
- 如果 doctor 报告迁移/结构问题，运行 Upgrade 后再次执行 Doctor
- 如果 doctor 通过，按需再执行 Self-Improve 沉淀经验
- Upgrade、Doctor、Self-Improve 执行后都应维护：
  - 项目级 `.claude/skills/pensieve/SKILL.md`（固定路由 + graph）
  - 项目根 `MEMORY.md` 的 Pensieve 引导块（描述与系统 skill `description` 对齐）

推荐顺序：
1. 检查并更新插件（或确认已是最新版本），然后重启 Claude Code
2. 运行 Upgrade（完整迁移校准；仅在结构与关键内容都一致时 no-op）
3. 运行一次 Doctor（必须）
4. 若 doctor 报错，继续 Upgrade 后再跑 Doctor
5. 需要沉淀经验时再运行 Self-Improve

如果你在指导用户，提醒他们只需表达这几个意图：
- loop 执行
- doctor 体检
- self-improve 沉淀
- upgrade 迁移
- 看图谱（直接读项目级 `SKILL.md` 的 `## Graph`）

---

## 用户数据保留策略

项目级用户数据 `.claude/skills/pensieve/` 不会被插件更新覆盖：

| 目录 | 内容 |
|------|------|
| `.claude/skills/pensieve/maxims/` | 自定义准则 |
| `.claude/skills/pensieve/decisions/` | 决策记录 |
| `.claude/skills/pensieve/knowledge/` | 自定义知识 |
| `.claude/skills/pensieve/pipelines/` | 项目 pipelines |
| `.claude/skills/pensieve/loop/` | loop 历史 |
