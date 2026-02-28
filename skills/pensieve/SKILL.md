---
name: pensieve
description: 项目经验沉淀与工作流路由系统。将开发中的知识、决策、准则、流程自动归档到项目级知识库，并提供初始化、升级、体检、复盘、任务循环五个工具。当用户提到 init/初始化、upgrade/迁移/版本、doctor/体检/检查、self-improve/沉淀/复盘、loop/循环执行，或涉及项目知识管理、经验归档、开发流程规范化时使用此 skill。即使用户未直接提及 Pensieve，只要意图涉及"把这次经验记下来""检查一下数据结构""帮我拆解这个复杂任务"等场景，也应考虑加载。
---

# Pensieve

将用户请求路由到正确的工具。路由时先理解意图，不确定就先确认——误判路由比多问一句代价更高。

## 意图判断

1. **显式意图优先**：用户明确说了工具名或触发词，直接路由。
2. **会话阶段推断**（未显式指定时）：
   - 新项目 / 空白上下文 → 候选 `init`
   - 版本 / 兼容 / 迁移不确定 → 候选 `upgrade`
   - 开发完成 / 复盘信号 → 候选 `self-improve`
   - 复杂任务需拆解 → 候选 `loop`
3. **不确定时先确认**：错误的自动路由会浪费用户时间，一句话确认成本很低。

<example>
User: "帮我初始化 pensieve"
Route: tools/init/_init.md
</example>

<example>
User: "检查一下数据有没有问题"
Route: tools/doctor/_doctor.md
</example>

<example>
User: "版本好像不对，帮我升级"
Route: tools/upgrade/_upgrade.md
</example>

<example>
User: "这次开发的经验沉淀一下"
Route: tools/self-improve/_self-improve.md
</example>

<example>
User: "这个需求比较复杂，用 loop 跑"
Route: tools/loop/_loop.md
</example>

<example>
User: "执行 run-when-reviewing-code pipeline"
Route: tools/loop/_loop.md
</example>

## 全局规则（摘要）

1. **Upgrade 优先**：版本/兼容/迁移问题先走 `/upgrade`，因为结构不对齐时其他工具的输出不可信。
2. **先确认再执行**：用户未显式下达时先确认——错误执行的回滚成本远高于一次确认。
3. **链接保持连通**：`decision/pipeline` 至少一条 `[[...]]` 链接（`基于/导致/相关`），这样知识网络才能被图谱追踪。
4. **先读规范再写数据**：创建/检查用户数据前先读对应 README，避免格式偏离后需要返工修复。

> 完整规则见 `references/shared-rules.md`

## 工具执行协议

执行任一工具前，读取其 `## Tool Contract` 段落。Tool Contract 描述了工具的适用场景、所需输入、输出格式和失败处理方式——跳过这一步容易导致输入不完整或输出格式不一致。

> 工具边界与重定向见 `references/tool-boundaries.md`

## 路由表

| 意图 | 入口 | 触发词 |
|------|------|--------|
| 初始化 | `tools/init/_init.md` | init, 初始化 |
| 版本升级 | `tools/upgrade/_upgrade.md` | upgrade, 迁移, 版本 |
| 体检 | `tools/doctor/_doctor.md` | doctor, 体检, 检查格式 |
| 沉淀经验 | `tools/self-improve/_self-improve.md` | self-improve, 沉淀, 复盘 |
| 循环执行 | `tools/loop/_loop.md` | loop, 循环执行, 执行 pipeline |

## 路由失败回退

1. **意图不明确**：返回候选路由并要求用户确认——猜错工具比多问一句代价更高。
2. **工具入口不可读**：停止并报告缺失路径。用"相近工具"替代往往导致输出格式不对，后续更难修复。
3. **输入不完整**：先补齐再执行。缺少输入就开跑会产生不完整的输出，用户还得重跑一遍。

---

`<SYSTEM_SKILL_ROOT>` 由 SessionStart hook 注入；用户数据路径固定为 `<project>/.claude/skills/pensieve/`。
