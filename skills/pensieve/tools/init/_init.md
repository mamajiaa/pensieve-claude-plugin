# Init 工具

---
description: 仅用于初始化项目级 `.claude/skills/pensieve/` 并补齐种子文件；幂等且不覆盖已有用户数据。若把迁移/体检/沉淀混入此步骤会造成职责错位，涉及版本或迁移必须先走 `/upgrade`。
---

你是 Init 工具。你的职责是初始化项目级用户数据目录，确保新项目开箱可用且依赖自包含（可脱离插件运行）。

## Tool Contract

### Use when

- 新项目首次接入 Pensieve
- `.claude/skills/pensieve/` 不存在或缺少基础目录
- 需要补齐初始种子（maxims / review pipeline / review knowledge）

### Do not use when

- 用户要求更新插件版本或确认版本状态（应转 `/upgrade`）
- 需要迁移历史目录或清理旧副本（应转 `/upgrade`）
- 需要做合规判定与分级（应转 `/doctor`）
- 需要沉淀经验或改进流程（应转 `self-improve`）

### Required inputs

- `<SYSTEM_SKILL_ROOT>`（由 `CLAUDE_PLUGIN_ROOT` 推导：`$CLAUDE_PLUGIN_ROOT/skills/pensieve`）
- 项目根路径（当前仓库）
- 已完成 `/upgrade` 的版本检查前置（或已明确当前版本状态）
- 初始化脚本：`<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh`
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh`

### Output contract

- 输出初始化结果（目标目录 + 种子文件状态）
- 明确说明“不会覆盖已有用户文件”
- 若发现历史旧路径，提示用户下一步运行 `/upgrade`
- 明确说明 review pipeline 默认依赖项目内 `.claude/skills/pensieve/knowledge/`
- 明确回报项目级 `SKILL.md` 更新结果（路由 + graph）

### Failure fallback

- 脚本执行失败：输出失败原因与重试命令，不做隐式兜底
- 缺少 `<SYSTEM_SKILL_ROOT>`：先提示重启/检查插件注入，再停止执行
- 版本状态未知：先提示运行 `/upgrade` 完成版本检查前置，再继续 init

### Negative examples

- “项目里有旧版 `skills/pensieve/`，顺手帮我迁移” -> 不应继续 init，转 `/upgrade`
- “先给我 PASS/FAIL 体检结论” -> 不属于 init，转 `/doctor`

## 执行步骤

1. 检查 `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh` 是否存在。
2. 运行：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

3. 核验最小结果：
   - `.claude/skills/pensieve/{maxims,decisions,knowledge,pipelines,loop}` 已存在
   - `.claude/skills/pensieve/pipelines/run-when-reviewing-code.md` 已存在
   - `.claude/skills/pensieve/pipelines/run-when-committing.md` 已存在
   - `.claude/skills/pensieve/knowledge/taste-review/content.md` 已存在
4. 核验项目级 SKILL：
   - `.claude/skills/pensieve/SKILL.md` 已创建/更新
   - 文件内包含自动生成标记（请勿手改）与 graph 段落
5. 若扫描到历史目录（如 `skills/pensieve/` 或 `.claude/pensieve/`），追加提醒：请运行 `/upgrade` 处理迁移与清理。

## 约束

- 仅做初始化与种子化，不做迁移清理。
- 不覆盖已有用户文件。
- 不输出 `/doctor` 风格的合规分级结论。
