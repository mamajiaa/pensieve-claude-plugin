---
description: 用于提交或复盘时自动沉淀可复用结论（knowledge/decision/maxim/pipeline），默认直接写入用户数据。跳过会丢失团队经验并重复踩坑；迁移与合规判定不在本工具职责内。
---

# 自改进（Auto Self-Improve）

> 工具边界见 `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | 共享规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

将经验与模式沉淀到 Pensieve 四类用户数据中：`maxim / decision / pipeline / knowledge`。

## Tool Contract

### Use when

- 提交 pipeline（`run-when-committing.md`）调用（自动触发）
- loop 完成后的收尾沉淀
- 用户明确要求"沉淀、记录、复盘、规范化"

### Required inputs

- 会话上下文（探索、决策、调试记录）
- `git diff --cached`（即将提交的变更）
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh`
- 目标类型对应 README（见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` § 规范来源）

### Output contract

- 直接写入，不等待用户确认
- 写入后输出简短摘要：写入路径 + 沉淀类型
- 链接规则按 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` § 语义链接规则
- 探索型问题包含"探索减负检查项"（见下文）
- 写入后同步项目级 `SKILL.md`，并维护项目根 `MEMORY.md` 的 Pensieve 引导块
- 质量门禁由调用方（pipeline）负责

### Failure fallback

- 发现结构性问题（旧路径并行/目录缺失/格式大面积不符）：跳过沉淀，建议后续运行 `doctor`——在结构不稳定时写入的数据位置可能不对
- 无法一次判断分类：按三层拆分（IS → `knowledge`，WANT → `decision`，MUST → `maxim`）

### Negative examples

- "顺手把旧目录也迁了" → 迁移涉及路径清理和数据合并，self-improve 没有这些能力，转 `upgrade`
- "先给我 PASS/FAIL 体检结论" → 合规判定需要读取完整规范并运行快检，转 `doctor`

---

## 语义分层分配

先判定语义层，再决定写入类型。三层对应不同的稳定性和强制力：

1. **knowledge（IS）**：系统事实、现状、边界、机制——"是这样"。最易更新，随系统变化而变化。
2. **decision（WANT）**：项目偏好、策略取舍、目标方向——"我想这样"。反映当前阶段的选择。
3. **maxim（MUST）**：跨项目的硬约束与底线——"必须这样"。变动最少，影响最广。

设计考量：
- 用语义而非"knowledge 优先"来分配，因为错误分类会导致约束力度不匹配（本该是 MUST 的写成了 knowledge，后续容易被忽略）。
- 同一洞察可同时拆分写入多层——一次调试可能同时产出事实（knowledge）、偏好（decision）和底线（maxim）。
- `pipeline` 仅表达 HOW（执行顺序与验证闭环），不替代 IS/WANT/MUST。

### Pipeline 门禁

新建 pipeline 前确认以下条件都满足，否则用其他类型更合适：

- 同类任务在多个会话/loop 中重复出现——一次性操作不值得编排
- 执行顺序会显著影响结果（步骤不可随意交换）——顺序无关的检查用 checklist 即可
- 每步都有可验证完成标准——"感觉完成"无法被自动化

---

## 核心原则

- **自动沉淀**：由 pipeline 触发时直接执行——等待确认会打断提交流程
- **先读后写**：创建任何文件前先读对应 README——格式偏离后修复成本高于一次预读
- **分类稳定**：只使用 `maxim / decision / pipeline / knowledge`——新增分类会破坏现有工具链
- **结论优先**：标题与第一句话能独立表达结论——浏览图谱时只看标题就能获取核心信息
- **准则单文件**：每条 `maxim` 独立文件——便于引用和组合
- **流程只做编排**：`pipeline` 只保留 task 编排与验证；理论背景外链——混入大段知识会让执行步骤难以辨认
- **目标是减探索**：沉淀应让"下一次从症状到定位"的路径更短

---

## 探索减负知识模型

当问题属于"需要探索代码库才能回答"时，若内容属于 IS（事实层），`knowledge` 应覆盖：

1. **状态转换**：某动作触发后，数据和视图如何变化
2. **症状 → 根因 → 定位**：看到什么现象，去哪里查，为什么
3. **边界与所有权**：谁有写权限、谁只能调用、跨模块如何流转
4. **不存在/已移除**：哪些能力不在当前系统，避免重复误判
5. **反模式与禁区**：看起来可行但会失败的路径及原因

### 探索减负检查项（探索型问题适用）

这些检查项确保沉淀的知识真正减少后续探索时间：

- 至少 1 条"症状 → 根因 → 定位"映射——这是探索减负的核心价值
- 至少 1 条"边界与所有权"约束——避免下次在错误模块中搜索
- 至少 1 条"反模式/不要做什么"——避免下次走同样的弯路
- 给出可验证信号（日志、测试、运行结果、可观测行为之一）——让下次验证有具体依据

---

## Phase 1: 提取与分类

**目标**：从会话上下文 + diff 中提取洞察并确定分类。

**行动**：
1. 提取核心洞察（可以是多条）
2. 为每条洞察判定语义层：IS → `knowledge`，WANT → `decision`，MUST → `maxim`
3. 同一洞察含多层时拆分写入，不混写
4. 判断是否需要 `pipeline`（HOW）：仅当满足门禁时新建

**路径规则**：
- `maxim`：`.claude/skills/pensieve/maxims/{one-sentence-conclusion}.md`
- `decision`：`.claude/skills/pensieve/decisions/{date}-{conclusion}.md`
- `pipeline`：`.claude/skills/pensieve/pipelines/run-when-*.md`
- `knowledge`：`.claude/skills/pensieve/knowledge/{name}/content.md`

---

## Phase 2: 读取规范 + 写入

**目标**：按规范写入并保持知识网络连通。

**行动**：
1. 读取目标 README（按分类选择对应 `<SYSTEM_SKILL_ROOT>/{type}/README.md`）
2. 生成内容（遵循 README 格式规范）：
   - 结论式标题 + 一句话结论
   - 核心内容与关键文件
   - 按类型补链接（`<SYSTEM_SKILL_ROOT>/references/shared-rules.md` § 语义链接规则）
3. 类型特定要求：
   - `decision`：包含"探索减负三项"（下次少问什么 / 下次少查什么 / 失效条件）——让决策的上下文在未来可追溯
   - 探索型 `knowledge`：包含探索减负检查项
   - `pipeline`：自检"不影响 task 编排的段落是否已外链"
4. 写入目标路径
5. 在关联文档补反向链接（若需要）
6. 维护项目级 SKILL：
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event self-improve --note "auto-improve: {file1,file2,...}"
   ```
7. 输出简短摘要（写入路径 + 沉淀类型）
