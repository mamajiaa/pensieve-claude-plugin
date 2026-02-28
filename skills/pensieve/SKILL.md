---
name: pensieve
description: 当用户表达任何意图时**立即加载**此 skill。系统能力（tools/knowledge/scripts）位于插件内，随插件更新维护。用户数据必须位于项目级 `.claude/skills/pensieve/`，插件不会覆盖。插件内容由插件维护，不提供用户修改路径。
---

# Pensieve

将用户请求路由到正确的工具。不猜测，不自动执行。

## 意图判断

1. **显式意图优先**：用户明确说了工具名或触发词，直接路由。
2. **会话阶段推断**（未显式指定时）：
   - 新项目 / 空白上下文 → 候选 `init`
   - 版本 / 兼容 / 迁移不确定 → 候选 `upgrade`
   - 开发完成 / 复盘信号 → 候选 `self-improve`
   - 复杂任务需拆解 → 候选 `loop`
3. **确认再执行**：未显式下达时，先一句话确认，不自动开跑。

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
User: "看看现在有哪些 pipeline"
Route: tools/pipeline/_pipeline.md
</example>

<example>
User: "执行 run-when-reviewing-code pipeline"
Route: tools/loop/_loop.md
</example>

## 全局硬规则（摘要）

1. **Upgrade 优先级最高**：版本/兼容/迁移问题先走 `/upgrade`。
2. **确认再执行**：用户未显式下达时，先确认。
3. **链接必填**：`decision/pipeline` 至少一条 `[[...]]` 链接（`基于/导致/相关`）。
4. **先读后写**：创建/检查用户数据前，先读对应格式 README。

> 完整规则见 `references/shared-rules.md`

## 工具契约执行协议

执行任一工具前，读取其 `## Tool Contract` 并逐条满足：

1. 命中 `Use when` 才继续。
2. 补齐 `Required inputs`，缺一项先补不执行。
3. 按步骤执行，严格遵循 `Output contract`。
4. 失败时按 `Failure fallback` 处理，不跳过。

> 工具边界与重定向见 `references/tool-boundaries.md`

## 路由表

| 意图 | 入口 | 触发词 |
|------|------|--------|
| 初始化 | `tools/init/_init.md` | init, 初始化 |
| 版本升级 | `tools/upgrade/_upgrade.md` | upgrade, 迁移, 版本 |
| 体检 | `tools/doctor/_doctor.md` | doctor, 体检, 检查格式 |
| 沉淀经验 | `tools/self-improve/_self-improve.md` | self-improve, 沉淀, 复盘 |
| 循环执行 | `tools/loop/_loop.md` | loop, 循环执行 |
| 查看 pipeline | `tools/pipeline/_pipeline.md` | 查看 pipeline, 图谱, 列表 |
| 执行 pipeline | `tools/loop/_loop.md` | 执行 pipeline, run-when-* |

## 路由失败回退

1. 意图不明确：返回候选路由并要求用户确认，不自动执行。
2. 工具入口不可读：停止并报告缺失路径，不用"相近工具"替代。
3. `Required inputs` 不满足：先补输入再执行，禁止盲跑。

---

`<SYSTEM_SKILL_ROOT>` 由 SessionStart hook 注入；用户数据路径固定为 `<project>/.claude/skills/pensieve/`。
