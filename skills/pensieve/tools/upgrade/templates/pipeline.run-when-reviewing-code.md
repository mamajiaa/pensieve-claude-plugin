---
id: run-when-reviewing-code
type: pipeline
title: 代码审查 Pipeline
status: active
created: 2026-02-11
updated: 2026-02-11
tags: [pensieve, pipeline, review]
name: run-when-reviewing-code
description: 在需要代码审查时调用。触发词：review / 代码审查 / 检查代码。

stages: [tasks]
gate: auto
---

# 代码审查 Pipeline

这个 pipeline 只负责任务编排。审查标准与深层依据统一放在 Knowledge 中，避免在本文件重复展开。

**Knowledge 参考**：`.claude/skills/pensieve/knowledge/taste-review/content.md`

**上下文链接（至少一条）**：
- 基于：[[knowledge/taste-review/content]]
- 导致：[[decisions/2026-xx-xx-review-policy]]
- 相关：[[decisions/2026-xx-xx-review-strategy]]

---

## Task Blueprint（按顺序创建任务）

### Task 1：准备审查上下文

**目标**：明确审查边界，避免漏审

**读取输入**：
1. 用户指定的文件 / 提交 / PR 范围
2. `.claude/skills/pensieve/knowledge/taste-review/content.md`

**执行步骤**：
1. 确认审查范围（文件 / 提交 / 代码片段）
2. 识别技术语言、业务约束与风险点
3. 输出待审文件清单（按优先级）

**完成标准**：范围清晰，且有可执行的待审文件列表

---

### Task 2：逐文件审查并记录证据

**目标**：基于统一标准形成逐文件结论

**读取输入**：
1. Task 1 产出的待审文件清单
2. `.claude/skills/pensieve/knowledge/taste-review/content.md`

**执行步骤**：
1. 对每个文件执行审查清单（理论与依据见 Knowledge，不在此文件复制）
2. 按严重级别记录结论：PASS / WARNING / CRITICAL
3. 对每条 WARNING/CRITICAL 标注精确代码位置
4. 记录用户可见行为变化风险（若有）

**完成标准**：每个文件都有带证据结论，且高风险问题可定位

---

### Task 3：生成可执行审查报告

**目标**：给出可落地的整改建议与优先级

**读取输入**：
1. Task 2 的审查记录

**执行步骤**：
1. 按严重级别汇总关键问题
2. 提供具体修复建议或重写方案
3. 明确指出任何用户可见行为变化与回归风险
4. 给出推荐修复顺序（先 CRITICAL，再 WARNING）

**完成标准**：报告包含完整发现、定位证据、修复建议与优先级

---

### Task 4：沉淀可复用结论（可选）

**目标**：把可复用结论沉淀到现有四类中

**读取输入**：
1. Task 3 的审查报告

**执行步骤**：
1. 若结论是项目选择，沉淀到 `decision`
2. 若结论是通用外部方法，沉淀到 `knowledge`
3. 在沉淀条目中补充 `基于/导致/相关`（至少一条，若是 decision）
4. 若无可复用结论，明确记录“无新增沉淀”

**完成标准**：沉淀结果明确（已写入或明确跳过）

---

## 执行规则（给 loop 用）

1. 命中此 pipeline 时，按 Task 1 → Task 2 → Task 3 → Task 4 的顺序创建任务。
2. 默认 1:1 映射创建，不合并、不跳步。
3. 若信息缺失，在当前 task 内补齐，不额外新建 phase。
