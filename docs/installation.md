# 安装指南

Pensieve 使用**官方插件结构**：

- **插件（系统能力）**：hooks + skills，仅通过插件升级更新
- **项目用户数据**：`.claude/pensieve/`，永不被插件覆盖

## 快速安装

### 1.（推荐）通过 Marketplace 安装并固定到 `main`

这样可以按分支或标签安装（例如 `main`）。

添加 marketplace（固定 `main`）：

```bash
claude plugin marketplace add kingkongshot/Pensieve#main
```

安装插件（用户级）：

```bash
claude plugin install pensieve@kingkongshot-marketplace --scope user
```

> `kingkongshot-marketplace` 来自 `.claude-plugin/marketplace.json` 的 `name` 字段。

如果你希望在团队仓库共享，可按项目级安装：

```bash
claude plugin install pensieve@kingkongshot-marketplace --scope project
```

### 2. 配置 `CLAUDE.md`（推荐）

> **给 LLM 的指令**：如果你是执行安装的 agent，请**创建或更新**该文件。保持简洁，不覆盖已有内容。

在项目根目录添加（仅 `CLAUDE.md`）：

```markdown
## Pensieve

先探索项目，再决定是否使用 Pensieve 工具。

当用户需要结构化工作流时：
- 使用 `/pipeline` 列出项目 pipelines
- 先用 `/upgrade` 完成版本更新前置检查（最高优先级）
- 使用 `/init` 初始化项目级用户数据（新项目首次接入）
- 使用 `/loop` 进行拆解 + 自动循环执行
- 使用 `/upgrade` 迁移用户数据

当用户要求改进 Pensieve（pipelines/scripts/rules/behavior）时，
必须使用 Self‑Improve 工具：
`tools/self-improve/_self-improve.md`
```

### 3. 初始化项目用户数据（推荐）

项目用户数据位于 `.claude/pensieve/`（插件升级不会覆盖）。

> 必须顺序：**安装插件后先初始化，再重启 Claude Code**。  
> 未初始化就重启，AI 可能不知道项目内置准则与默认审查 pipeline 已经可用。

方式 A：

```bash
mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}
```

方式 B（推荐）：运行初始化脚本（会种子化**初始 maxims + 审查 pipeline + 审查 knowledge**，不会覆盖已有文件）：

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

> `<SYSTEM_SKILL_ROOT>` 由 SessionStart hook 注入为绝对路径。

### 4. 重启 Claude Code

初始化完成后再重启 Claude Code，然后输入 `loop` 验证安装。

---

## 历史迁移

如果你之前把系统内容复制到了项目里（例如 `skills/pensieve/`），请使用 **/upgrade** 做迁移和清理：

- 合并项目级 maxims
- 迁移预置 pipeline
- 移除历史系统副本（README 与 `_*.md`）

---

## 用户级安装

如果你希望对所有项目生效，使用用户级安装：

```bash
claude plugin install pensieve@kingkongshot-marketplace --scope user
```

---

## 给 LLM Agent 的说明

如果你是 LLM agent：
1. 安装插件
2. 初始化 `.claude/pensieve/`
3. 重启 Claude Code（不要跳过）
4. **告诉用户只需掌握几个基础命令**：
   - `/upgrade`（版本更新前置检查 + 历史迁移，最高优先级）
   - `/init`（新项目初始化）
   - `/loop`
   - `/doctor`（安装后可选体检；升级后必跑）
   - `/selfimprove`
   - `/pipeline`

说明保持简短，目标是降低用户认知负担。

---

## 更新

参见 **[更新指南](update.md)**。

---

## 卸载

1. 卸载插件：`claude plugin uninstall pensieve@kingkongshot-marketplace --scope user`（或使用 `/plugin`）
2. （可选）删除项目数据前先询问用户是否需要备份：`rm -rf .claude/pensieve`

---

## 验证安装

安装后：

1. 先运行 `/init`（或等价脚本：`<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh`）
2. 确认种子文件存在：
   - `.claude/pensieve/maxims/*.md` 至少 1 个
   - `.claude/pensieve/pipelines/run-when-reviewing-code.md`
   - `.claude/pensieve/knowledge/taste-review/content.md`
3. 重启 Claude Code
4. 输入 `loop`，应触发 Loop 工具流程
5. 通过 `/help` 确认 `pensieve` skill 已可见

> 说明：`init-loop.sh` 只会创建 loop 目录与 `_agent-prompt.md`。  
> `_context.md` 在 Phase 2 由主窗口创建并填充。

---

## 常见问题

### 安装后没有反应？

1. 确认已重启 Claude Code
2. 检查 `.claude/settings.json`
3. 使用 `/plugin` 确认插件已启用

### Hooks 没有触发？

1. 使用 `/hooks` 确认 SessionStart/Stop hooks 已启用

### Skill 没有加载？

系统 skills 随插件分发。如果仍未加载：

1. 重启 Claude Code
2. 检查插件是否启用（`/plugin`）
