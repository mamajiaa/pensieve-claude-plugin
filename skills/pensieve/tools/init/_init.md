---
description: 初始化项目级 `.claude/skills/pensieve/` 并补齐种子文件；随后执行一次基线探索（提交记录+实际代码），产出可沉淀候选，并基于该结果调用 review pipeline 做品味分析。幂等且不覆盖已有用户数据；涉及迁移/清理应先走 `upgrade`；完成后交由 `doctor` 复检。
---

# Init 工具

> 工具边界见 `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | 共享规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

初始化项目级用户数据目录，确保新项目开箱可用且依赖自包含。

## Tool Contract

### Use when

- 新项目首次接入 Pensieve
- `.claude/skills/pensieve/` 不存在或缺少基础目录
- 需要补齐初始种子（maxims / review pipeline / review knowledge）
- 初始化后需要快速建立项目级审查基线（热点模块 + 品味风险）

### Required inputs

- `<SYSTEM_SKILL_ROOT>`（由 SessionStart hook 注入）
- 项目根路径
- 初始化脚本：`<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh`
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh`
- 可读 Git 历史（至少可执行 `git log` 与 `git show`）
- review pipeline：`.claude/skills/pensieve/pipelines/run-when-reviewing-code.md`

### Output contract

- 输出初始化结果（目标目录 + 种子文件状态）
- 输出基线探索摘要（提交窗口、热点文件/模块、可沉淀候选清单）
- 输出 review pipeline 品味分析摘要（高风险点 + 证据 + 兼容性风险）
- 说明不会覆盖已有用户文件
- 若发现历史旧路径，提示运行 `upgrade`
- 回报项目级 `SKILL.md` 更新结果
- 说明候选仅分析，不自动写入沉淀文件
- 给出下一步：运行 `doctor`

### Failure fallback

- 脚本执行失败：输出失败原因与重试命令——隐式兜底会掩盖根因，让用户误以为初始化成功
- 缺少 `<SYSTEM_SKILL_ROOT>`：提示重启/检查插件注入，停止执行
- 版本状态未知：提示先运行 `upgrade`
- 仓库无提交记录或 Git 不可用：跳过探索与品味分析，标记 `SKIPPED`
- review pipeline 缺失：返回缺失路径并建议先重新运行 `init` 或 `upgrade`

### Negative examples

- "项目里有旧版 skills/pensieve/，顺手帮我迁移" → 迁移涉及路径清理和数据合并，init 不具备这些能力，转 `upgrade`
- "先给我 PASS/FAIL 体检结论" → init 只做初始化不做合规判定，转 `doctor`
- "把探索候选直接写入 knowledge/decision" → 写入需要遵循语义分层规范，转 `self-improve`

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
5. 若扫描到历史目录（`skills/pensieve/` 或 `.claude/pensieve/`），追加提醒：运行 `upgrade` 处理迁移与清理。
6. 执行基线探索（只读）：
   - 读取最近提交记录（默认最近 30 条，或用户指定窗口）
   - 汇总高频变更文件/模块与风险热点
   - 结合实际代码结构，产出"可沉淀候选清单"（标注建议类型：`knowledge/decision/maxim/pipeline`）
   - 每条候选附证据（提交、文件、或行为线索），没有证据的候选不够可靠
7. 基于第 6 步结果执行 review pipeline 品味分析：
   - 加载 `.claude/skills/pensieve/pipelines/run-when-reviewing-code.md`
   - 以"热点文件 + 最近关键提交"作为审查范围输入
   - 输出品味分析（复杂度热点、特殊分支、潜在破坏性改动风险）
8. 收尾输出：
   - 初始化结果
   - 可沉淀候选摘要
   - 品味分析摘要
   - 下一步：运行 `doctor`（初始化后立即体检能尽早发现种子文件的格式问题）
   - 若需落库：运行 `self-improve`

## 约束

- 初始化可附带只读探索与品味分析，但不直接落库沉淀内容——落库需要遵循语义分层规范，由 `self-improve` 负责。
- 不做迁移清理——迁移涉及路径合并和旧数据处理，由 `upgrade` 负责。
- 不覆盖已有用户文件——用户可能已经手动编辑过，覆盖会丢失修改。
- 不输出 `doctor` 风格的合规分级结论——init 的职责是"建好"，不是"判好坏"。
