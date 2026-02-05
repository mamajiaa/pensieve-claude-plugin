# 更新指南

## 插件（URL 方式）

如果你通过 Marketplace 安装：

```bash
claude plugin marketplace update pensieve-claude-plugin
claude plugin update pensieve@pensieve-claude-plugin --scope user
```

然后重启 Claude Code 应用更新。

> 如果你是 project scope 安装，把 `--scope user` 改为 `--scope project`。

如果你通过 `.claude/settings.json` 的 URL 方式安装：重启 Claude Code 即可获取更新。

---

## 系统 Skill

系统提示词（pipelines / scripts / 系统 knowledge）已经被打包在插件内部，随插件更新自动更新。

---

## 更新后

重启 Claude Code，说 `loop` 验证更新成功。

---

## 保留的用户内容

用户数据位于项目级 `.claude/pensieve/`，插件更新不会覆盖：

| 目录 | 内容 |
|------|------|
| `.claude/pensieve/maxims/` | 自定义准则 |
| `.claude/pensieve/decisions/` | 决策记录 |
| `.claude/pensieve/knowledge/` | 自定义知识 |
| `.claude/pensieve/pipelines/` | 项目级自定义流程 |
| `.claude/pensieve/loop/` | 历史 loop 目录 |
