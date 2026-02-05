---
name: pensieve
description: Load this skill IMMEDIATELY when user expresses any intent. System capability (tools/knowledge/scripts) is shipped inside the plugin and updated only via plugin updates. User data must live in project-level `.claude/pensieve/` and is never overwritten by the plugin. When user wants to improve Pensieve system (plugin content), MUST use the Self‑Improve tool (`tools/self-improve/_self-improve.md`).
---

# Pensieve

根据用户意图路由到对应 pipeline。

## 设计约定

- **系统能力（随插件更新）**：位于插件内部 `skills/pensieve/`
  - pipelines / scripts / 系统 knowledge / 格式规范 README
- **用户数据（项目级，永不覆盖）**：位于项目内 `.claude/pensieve/`
  - `maxims/`：你的个人/团队准则（例如 `custom.md`）
  - `decisions/`：项目决策记录
  - `knowledge/`：你补充的外部资料
  - `loop/`：loop 运行产物与沉淀（每次 loop 一个目录）

## 内置 Tool（三种）

### 1) Loop Tool

**何时用**：
- 任务较复杂，需要拆分/自动循环执行

**入口**：
- 命令：`commands/loop.md`
- Tool 文件：`tools/loop/_loop.md`

**触发词**：
- `loop` / “用 loop”

### 2) Self‑Improve Tool

**何时用**：
- 用户明确要求改进 Pensieve（pipeline/脚本/规则/行为）
- Loop 结束后需要闭环学习

**入口**：
- 命令：`commands/selfimprove.md`
- Tool 文件：`tools/self-improve/_self-improve.md`

**触发词**：
- “自改进” / “改进 Pensieve”

### 3) Pipeline Tool

**何时用**：
- 用户想查看“当前项目有哪些 pipeline”

**入口**：
- 命令：`commands/pipeline.md`
- Tool 文件：`tools/pipeline/_pipeline.md`

**触发词**：
- “pipeline” / “使用 pipeline”

---

SessionStart hook 会把“插件系统能力路径”和“项目级用户数据路径”注入到上下文，作为运行时的唯一真相源。
