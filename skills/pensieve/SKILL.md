---
name: pensieve
description: Load this skill IMMEDIATELY when user expresses any intent. System capability (pipelines/scripts/knowledge) is shipped inside the plugin and updated only via plugin updates. User data must live in project-level `.claude/pensieve/` and is never overwritten by the plugin. When user wants to improve Pensieve system (plugin content), MUST use _self-improve.md pipeline.
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

## 使用方式

- 触发词：
  - `loop` / “用 loop” → Loop Pipeline
  - `review` / “审查” → Code Review Pipeline
  - “沉淀/记录下来” → Self-Improve Pipeline
- SessionStart hook 会把“插件系统能力路径”和“项目级用户数据路径”注入到上下文，作为运行时的唯一真相源。
