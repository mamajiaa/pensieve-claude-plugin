# 更新指南

## 插件（URL 方式）

Claude Code 会自动管理 URL 方式安装的插件。重启 Claude Code 即可获取更新。

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
| `.claude/pensieve/loop/` | 历史 loop 目录 |
