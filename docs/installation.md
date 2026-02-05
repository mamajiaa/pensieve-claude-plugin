# 安装指南

Pensieve 现在采用**官方插件结构**：

- **插件（系统能力）**：hooks + skills，完全由插件更新维护
- **项目级用户数据**：`.claude/pensieve/`，永不被插件更新覆盖

## 快速安装

### 1.（推荐）通过 Marketplace 安装并固定到 `zh` 分支

这种方式允许你选择分支/标签版本（例如中文开发分支 `zh`）。

添加 marketplace（固定到 `zh` 分支）：

```bash
claude plugin marketplace add mamajiaa/pensieve-claude-plugin#zh
```

安装插件（建议 project 级共享给团队）：

```bash
claude plugin install pensieve@pensieve-claude-plugin --scope user
```

> 说明：`pensieve-claude-plugin` 来自本仓库 `.claude-plugin/marketplace.json` 的 `name` 字段。

如果你希望 project 级共享给团队，把 scope 改为 `project`：

```bash
claude plugin install pensieve@pensieve-claude-plugin --scope project
```

### 2. 配置 CLAUDE.md

在项目的 `CLAUDE.md` 中添加以下内容，确保 Claude 每次对话都会加载 Pensieve：

```markdown
## Pensieve

Load pensieve skill IMMEDIATELY when user expresses any intent.

When user wants to improve Pensieve (add/modify pipelines, decisions, maxims, or any content), MUST use the Self‑Improve tool (`tools/self-improve/_self-improve.md`).
```

### 3. 初始化项目级用户数据（推荐）

用户数据目录位于：`.claude/pensieve/`（不会被插件更新覆盖）。

可选方式：

```bash
mkdir -p .claude/pensieve/{maxims,decisions,knowledge,loop}
```

或运行插件内置初始化脚本（会补齐默认文件，且不会覆盖已有文件）：

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

> `<SYSTEM_SKILL_ROOT>` 会在 SessionStart hook 注入的上下文里给出绝对路径。

### 4. 重启 Claude Code

说 `loop` 验证安装成功。

---

## 用户级安装

如果你想在所有项目中使用，把安装 scope 改为 `user`：

```bash
claude plugin install pensieve@pensieve-claude-plugin --scope user
```

---

## 面向 LLM 智能体

如果你是 LLM 智能体：只需要安装插件并初始化 `.claude/pensieve/` 用户数据目录即可（系统 Skill 已随插件提供，无需再复制 skill 目录）。

---

## 更新

详见 **[更新指南](update.md)**。

---

## 卸载

1. 卸载插件：`claude plugin uninstall pensieve@pensieve-claude-plugin --scope user`（或用 `/plugin` UI）
2. （可选）删除项目级用户数据：`rm -rf .claude/pensieve`

---

## 验证安装

安装成功后：

1. 重启 Claude Code
2. 说 `loop`，应该触发 Loop Pipeline
3. 检查 `/help` 中是否有 `pensieve` skill

> 提示：进入 loop 后，`init-loop.sh` 只会创建 loop 目录与 `_agent-prompt.md`，`_context.md` 需要在 Phase 3 由主窗口创建并填充。

---

## 常见问题

### 安装后没有反应？

1. 确认已重启 Claude Code
2. 检查 `.claude/settings.json` 配置正确
3. 用 `/plugin` 确认插件已启用

### Hook 没有触发？

1. 用 `/hooks` 确认 SessionStart/Stop hooks 已生效

### Skill 未加载？

系统 Skill 随插件提供。若仍无反应：

1. 确认已重启 Claude Code
2. 检查插件是否启用（`/plugin`）
