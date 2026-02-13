# 更新指南

## 插件更新（Marketplace）

如果你通过 Marketplace 安装：

```bash
claude plugin marketplace update kingkongshot/Pensieve
claude plugin update pensieve@kingkongshot-marketplace --scope user
```

然后重启 Claude Code 使更新生效。

这两条命令可重复执行；如果已经是最新版本，通常不会产生变更。

> 如果你是项目级安装，请把 `--scope user` 改为 `--scope project`。

如果你是通过 `.claude/settings.json` URL 安装，重启 Claude Code 即可拉取更新。

### 更新失败兜底

如果更新命令失败（网络、权限、CLI 版本问题等），先查看 GitHub 上的最新文档再继续：

- [docs/update.md（main 分支）](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md)

在更新失败未解决前，不建议继续执行 `/upgrade`。

---

## 系统 Skills

系统提示词（tools/scripts/system knowledge）随插件打包，并跟随插件更新。

---

## 更新后流程

重启 Claude Code 后，输入 `loop` 验证更新是否生效。

**版本检查前置（必须）**：
在执行 `/upgrade` 或 `/doctor` 前，先按本文件完成“插件更新 + 重启”。
若已是最新版本，可直接进入下一步。

**Upgrade 核心逻辑（版本优先）**：
- `/upgrade` 先同步最新版本结构定义（来自 GitHub/Marketplace）
- 再做结构差异门禁（旧路径并行/目录与命名差异/插件键差异）
- 若无差异：`/upgrade` 应 no-op，不做逐文件迁移
- 若有差异：执行最小结构迁移
- review 依赖应项目内化：pipeline 引用 `.claude/pensieve/knowledge/...`，不依赖 `<SYSTEM_SKILL_ROOT>/knowledge/...`
- 最终统一交给 `/doctor` 判定“还需如何调整本地数据结构”

然后：
- 即使存在历史脏数据，也优先先执行 `/upgrade`（不要把 `/doctor` 当成升级前门槛）
- 每次升级/迁移后必须运行一次 `/doctor` 做基于 README 的体检
- 如果 doctor 报告迁移/结构问题，运行 `/upgrade` 后再次执行 `/doctor`
- 如果 doctor 通过，按需再执行 `/selfimprove` 沉淀经验

推荐顺序：
1. 检查并更新插件（或确认已是最新版本），然后重启 Claude Code
2. 运行 `/upgrade`（先结构判定；若无差异则 no-op）
3. 运行一次 `/doctor`（必须）
4. 若 doctor 报错，继续 `/upgrade` 后再跑 `/doctor`
5. 需要沉淀经验时再运行 `/selfimprove`

如果你在指导用户，提醒他们只需掌握几个命令：
- `/loop`
- `/doctor`
- `/selfimprove`
- `/pipeline`
- `/upgrade`

---

## 用户数据保留策略

项目级用户数据 `.claude/pensieve/` 不会被插件更新覆盖：

| 目录 | 内容 |
|------|------|
| `.claude/pensieve/maxims/` | 自定义准则 |
| `.claude/pensieve/decisions/` | 决策记录 |
| `.claude/pensieve/knowledge/` | 自定义知识 |
| `.claude/pensieve/pipelines/` | 项目 pipelines |
| `.claude/pensieve/loop/` | loop 历史 |
