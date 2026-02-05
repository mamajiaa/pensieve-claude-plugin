---
name: review
description: |
  代码审查 pipeline。基于 Linus Torvalds 好品味哲学、John Ousterhout 设计原则、Google Code Review 标准。

  适用场景：
  - 用户请求代码审查
  - 用户说"review"、"审查"、"检查代码"
  - 需要评估代码质量或设计决策

  示例：
  <example>
  用户: "帮我 review 这段代码"
  -> 触发此 pipeline
  </example>
  <example>
  用户: "检查一下这个 PR"
  -> 触发此 pipeline
  </example>

signals: ["review", "审查", "检查代码", "代码质量", "code review"]
stages: [tasks]
gate: auto
---

# 代码审查 Pipeline

这个 pipeline **只负责编排流程**，具体标准与原理放在 Knowledge 中。

**知识参考**：`<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

---

## Phase 0: 准备

**目标**：明确范围并加载参考

**行动**：
1. 确认审查范围（文件 / 提交 / 片段）
2. 明确语言与约束
3. 加载审查知识：`knowledge/taste-review/`

**验证**：范围明确，知识已加载

---

## Phase 1: 审查

**目标**：按清单检查并记录证据

**行动**：
1. 逐文件执行 knowledge 中的清单（不在 pipeline 里重复理论）
2. 记录结论：PASS / WARNING / CRITICAL
3. 每个 WARNING/CRITICAL 必须引用具体代码位置

**验证**：每个文件都有结论和证据

---

## Phase 2: 报告

**目标**：输出可执行的审查结论

**行动**：
1. 按严重性汇总关键问题
2. 给出可执行的修复或重写建议
3. 明确是否影响用户可见行为

**验证**：报告包含所有发现与改进建议
