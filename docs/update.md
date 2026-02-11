# 更新指南

## 插件更新（Marketplace）

如果你通过 Marketplace 安装：

```bash
claude plugin marketplace update kingkongshot/Pensieve
claude plugin update pensieve@kingkongshot-marketplace --scope user
```

然后重启 Claude Code 使更新生效。

> 如果你是项目级安装，请把 `--scope user` 改为 `--scope project`。

如果你是通过 `.claude/settings.json` URL 安装，重启 Claude Code 即可拉取更新。

---

## 系统 Skills

系统提示词（tools/scripts/system knowledge）随插件打包，并跟随插件更新。

---

## 更新后流程

重启 Claude Code 后，输入 `loop` 验证更新是否生效。

**升级后强制自检（必须）：**
每次升级后必须运行一次 `/doctor` 做基于 README 的体检。
在 doctor 跑完前，升级视为未完成。

然后：
- 即使存在历史脏数据，也优先先执行 `/upgrade`
- 如果 doctor 报告迁移/结构问题，运行 `/upgrade` 后再次执行 `/doctor`
- 如果 doctor 通过，按需再执行 `/selfimprove` 沉淀经验

推荐顺序：
1. 升级插件并重启 Claude Code
2. 运行一次 `/doctor`（必须）
3. 若 doctor 报错，运行 `/upgrade` 后再跑 `/doctor`
4. 需要沉淀经验时再运行 `/selfimprove`

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
