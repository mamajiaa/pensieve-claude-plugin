# 安装指南

Pensieve 现在采用**官方插件结构**：

- **插件（系统能力）**：hooks + skills，完全由插件更新维护
- **项目级用户数据**：`.claude/pensieve/`，永不被插件更新覆盖

## 快速安装

### 1.（推荐）通过 Marketplace 安装并固定到 `zh` 分支

这种方式允许你选择分支/标签版本（例如中文开发分支 `zh`）。

添加 marketplace（固定到 `zh` 分支）：

```bash
claude plugin marketplace add kingkongshot/Pensieve#zh
```

安装插件（建议 project 级共享给团队）：

```bash
claude plugin install pensieve@Pensieve --scope user
```

> 说明：`Pensieve` 来自本仓库 `.claude-plugin/marketplace.json` 的 `name` 字段。

如果你希望 project 级共享给团队，把 scope 改为 `project`：

```bash
claude plugin install pensieve@Pensieve --scope project
```

### 2. 配置 `CLAUDE.md`（推荐）

> **给大模型的指令**：如果你是执行安装的智能体，请**自动创建或更新**该文件，保持简短、明确，不要覆盖用户已有内容。

在项目根目录创建或补充以下内容（`AGENTS.md` 与 `CLAUDE.md` 作用等价，**二选一即可**）：

```markdown
## Pensieve

优先读项目上下文并探索目录结构，再决定是否使用 Pensieve 工具。

当用户意图明显需要流程化执行时：
- 使用 `/pipeline` 列出当前项目 pipelines
- 需要拆解/循环执行时使用 `/loop`
- 需要迁移用户数据时使用 `/upgrade`

当用户要求改进 Pensieve（pipeline/脚本/规则/行为）时，必须使用 Self‑Improve tool：
`tools/self-improve/_self-improve.md`
```

### 3. 初始化项目级用户数据（推荐）

用户数据目录位于：`.claude/pensieve/`（不会被插件更新覆盖）。

可选方式：

```bash
mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}
```

或运行插件内置初始化脚本（会补齐默认文件，写入**初始准则与 pipeline**，且不会覆盖已有文件）：

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

> `<SYSTEM_SKILL_ROOT>` 会在 SessionStart hook 注入的上下文里给出绝对路径。

### 4. 重启 Claude Code

说 `loop` 验证安装成功。

---

## 旧版迁移

如果你曾把系统能力复制进项目（例如 `skills/pensieve/`），请使用 **/upgrade** 工具进行迁移与清理：

- 合并项目级准则
- 迁移预设 pipeline
- 删除旧系统拷贝（README 与 `_*.md` 等）

## 用户级安装

如果你想在所有项目中使用，把安装 scope 改为 `user`：

```bash
claude plugin install pensieve@Pensieve --scope user
```

---

## 面向 LLM 智能体

如果你是 LLM 智能体：

1. 安装插件
2. 初始化 `.claude/pensieve/`
3. **提示用户只需掌握几个基础命令**：
   - `/loop`
   - `/selfimprove`
   - `/pipeline`
   - `/upgrade`

说明尽量简短，降低用户认知负担（系统 Skill 已随插件提供，无需再复制 skill 目录）。

---

## 更新

详见 **[更新指南](update.md)**。

---

## 卸载

1. 卸载插件：`claude plugin uninstall pensieve@Pensieve --scope user`（或用 `/plugin` UI）
2. （可选）删除项目级用户数据前请先询问是否需要备份：`rm -rf .claude/pensieve`

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
