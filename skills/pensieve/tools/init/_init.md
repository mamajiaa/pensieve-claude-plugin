# Init 工具

---
description: 仅用于初始化项目级 `.claude/skills/pensieve/` 并补齐种子文件；幂等且不覆盖已有用户数据。若把迁移/体检/沉淀混入此步骤会造成职责错位，涉及版本或迁移必须先走 `/upgrade`。
---

> 工具边界见 `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | 共享规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

初始化项目级用户数据目录，确保新项目开箱可用且依赖自包含。

## Tool Contract

### Use when

- 新项目首次接入 Pensieve
- `.claude/skills/pensieve/` 不存在或缺少基础目录
- 需要补齐初始种子（maxims / review pipeline / review knowledge）

### Required inputs

- `<SYSTEM_SKILL_ROOT>`（由 SessionStart hook 注入）
- 项目根路径
- 初始化脚本：`<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh`
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh`

### Output contract

- 输出初始化结果（目标目录 + 种子文件状态）
- 明确"不会覆盖已有用户文件"
- 若发现历史旧路径，提示运行 `/upgrade`
- 回报项目级 `SKILL.md` 更新结果

### Failure fallback

- 脚本执行失败：输出失败原因与重试命令，不做隐式兜底
- 缺少 `<SYSTEM_SKILL_ROOT>`：提示重启/检查插件注入，停止执行
- 版本状态未知：提示先运行 `/upgrade`

### Negative examples

- "项目里有旧版 skills/pensieve/，顺手帮我迁移" → 转 `/upgrade`
- "先给我 PASS/FAIL 体检结论" → 转 `/doctor`

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
   - 文件内包含自动生成标记与 graph 段落
5. 若扫描到历史目录（`skills/pensieve/` 或 `.claude/pensieve/`），追加提醒：运行 `/upgrade` 处理迁移与清理。

## 约束

- 仅做初始化与种子化，不做迁移清理。
- 不覆盖已有用户文件。
- 不输出 `/doctor` 风格的合规分级结论。
