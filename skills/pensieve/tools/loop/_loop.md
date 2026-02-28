---
description: 仅在任务复杂且必须拆成多个可验证子任务时使用；主窗口负责编排、子代理逐任务执行。若目标未确认或任务很小仍开 loop，会引入不必要流程成本并放大上下文噪音。触发词：loop / use loop / loop mode / 循环执行。
---

# Loop 工具

> 工具边界见 `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | 共享规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

将复杂工作拆成可执行原子任务，在 Task 系统中按顺序推进。主窗口只做编排，每次仅分派一个子任务给子代理执行。

## 核心原则

- **上下文隔离**：每个任务在子代理中运行，避免主窗口上下文爆炸
- **原子任务**：每个任务可独立执行、可独立验证
- **干净交接**：子代理执行一个任务后返回；主窗口继续分派下一个

## Tool Contract

### Use when

- 任务复杂，需要拆解为多个可验证子任务
- 需要长流程持续推进（主窗口按任务状态续跑）
- 需要隔离上下文，避免主窗口持续膨胀

### Required inputs

- 已确认的目标/范围/约束（Phase 2 确认后再进入 Phase 3，因为目标不清晰时生成的任务大概率需要返工）
- `<SYSTEM_SKILL_ROOT>` 与 `<USER_DATA_ROOT>` 路径
- `LOOP_DIR`（由 `init-loop.sh` 输出）

### Output contract

- Phase 2 先输出上下文摘要并获得确认——确认步骤确保任务拆解基于共识，而非假设
- Phase 3 在 Claude Task 系统中直接创建真实任务（不是只输出 markdown/list）——Task 系统提供状态追踪和子代理分派
- 执行期每次只推进一个任务，子代理完成后立即返回

### Failure fallback

- `init-loop.sh` 失败：停止推进并返回错误与修复建议——没有 LOOP_DIR 的任务无法正确隔离上下文
- `Task` 系统异常：停止推进并输出恢复建议（重试/缩小任务/手动收尾）
- 无法满足"单任务可执行"粒度：继续拆分或补充上下文——强行开跑粒度过粗的任务会导致子代理频繁提问，失去上下文隔离的意义

### Negative examples

- "改 1 个文案文件，顺便 loop" → 1-2 个文件的修改直接完成更快，loop 的初始化和编排开销反而拖慢进度
- "还没确认需求，先建 10 个任务" → 需求未确认时生成的任务大概率与最终目标不匹配，返工成本高于先花一分钟确认

---

## Phase 0: 简单任务检查

评估任务复杂度。满足以下全部条件时，**建议直接完成**：
- 只涉及 1-2 个文件
- 范围清晰，无需探索
- 一个任务即可完成

> 这个任务看起来比较简单，直接完成会更快。要现在做还是用 loop？

用户选直接完成 → 不开 loop。用户坚持 → 继续 Phase 1。

---

## Phase 1: 初始化

**目标**：在拆分任务前准备好 loop 目录

```
bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh <slug>
```

**slug**：简短英文标识（如 `snake-game`、`auth-module`）。

不要用 `run_in_background: true` 运行——后续步骤立刻需要 `LOOP_DIR` 路径。

脚本输出（记住 `LOOP_DIR`）：
```
LOOP_DIR=.claude/skills/pensieve/loop/2026-01-27-login
```

---

## Phase 2: 捕获上下文

**目标**：在生成任务前记录会话上下文

1. 创建 `LOOP_DIR/_context.md`：

```markdown
# 会话上下文

## 前置上下文

### 交互历史
| 轮次 | 模型尝试 | 用户反馈 |
|------|----------|----------|
| 1 | ... | ... |

### 最终共识
- 目标: XXX
- 范围: YYY
- 约束: ZZZ

### 理解与假设
- 预期涉及的模块
- 预期实现方式
- 预期难点

### 文档引用
| 类型 | 路径 |
|------|------|
| 需求文档 | 无 / 路径 |
| 设计文档 | 无 / 路径 |
| 计划文档 | 无 / 路径 |

### 上下文链接（可选）
- 基于：[[前置决策或知识]]
- 导致：[[后续决策、流程或文档]]
- 相关：[[相关主题]]
```

2. **向用户展示上下文摘要并确认后再继续**

3. **按需创建需求/设计文档**：

   | 条件 | 需要 | 模板 |
   |------|------|------|
   | 需求不清晰（目标/范围/约束未确认） | 需求文档 | `loop/REQUIREMENTS.template.md` |
   | 实现方式不明显 | 设计文档 | `loop/DESIGN.template.md` |

   仅上述两个条件触发文档创建——不必要的文档只会增加噪音，不会帮助任务生成。

4. 如果 loop 可能产出 `decision` 或 `pipeline`，预填上下文链接。

> 链接规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` § 语义链接规则

---

## Phase 3: 生成任务

**目标**：将工作拆解为原子化、可执行的任务

Phase 2 的用户确认是前置条件——基于未确认上下文生成的任务大概率与最终目标不匹配。

### 先加载准则

读取所有项目准则 `<USER_DATA_ROOT>/maxims/*.md`，用准则约束任务边界和验收标准。在生成任务前加载准则，确保约束从一开始就嵌入验收标准，而不是事后补丁。

### 获取可用流程

读取 `<USER_DATA_ROOT>/pipelines/` 下所有 `*.md` 文件。如果存在相关 pipeline，读取并检查是否包含任务蓝图。

**蓝图检测**：包含 `## Task Blueprint` 或有序的 `### Task 1/2/3...` 标题。

蓝图处理：
- 有蓝图 → 1:1 按序映射为运行时任务。合并/拆分/重排蓝图步骤会破坏预定义序列的意义。
- 无蓝图 → 正常拆分任务。

### 任务粒度标准

**核心检验：子代理能否不提问就执行完？**

每个任务需要：
- 指定要创建或修改的文件/组件
- 包含具体的构建/修改/测试操作

### 操作步骤

1. 读取项目准则，提取约束
2. 检查相关 pipeline 是否有蓝图
3. 有蓝图 → 1:1 映射；否则按粒度标准拆分
4. 确保验收标准与准则对齐
5. 在 Claude Task 系统中创建任务（Phase 2 确认后）
6. markdown checklist 不等于任务创建——只有在 Task 系统中创建的才算数
7. 展示简要快照（task id + 主题），然后创建/运行第一个任务

---

## Phase 4: 主窗口续跑

第一个任务创建后，主窗口获取下一个待处理任务，每次分派一个子代理，直到所有任务完成。

不依赖 hooks 或后台绑定进程——主窗口主动轮询任务状态更可靠。

---

## Phase 5: 执行任务

**目标**：通过隔离的子代理逐个执行任务

1. 为第一个待处理任务启动通用子代理：

```
Task(
  subagent_type: "general-purpose",
  prompt: "读取 .claude/skills/pensieve/loop/{date}-{slug}/_agent-prompt.md 并执行 task_id={id}"
)
```

`_agent-prompt.md`（由 init-loop.sh 生成）包含：
- 角色定义、loop 上下文路径、准则路径、执行约束

2. 子代理：TaskGet → 执行 → 返回
3. 主窗口检查任务状态，分派下一个待处理任务

---

## Phase 6: 收尾

1. 所有任务完成 → 询问是否运行 self-improve（`tools/self-improve/_self-improve.md`）。
2. 如果 loop 产出了 `decision` 或 `pipeline`，确保输出包含链接（见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`）。

---

## Phase 选择指南

| 任务特征 | Phase 组合 |
|----------|------------|
| 范围清晰、规模小 | 直接生成任务 |
| 需要理解代码 | 计划 → 任务 |
| 需要技术设计 | 计划 → 设计 → 任务 |
| 需求不清晰 | 计划 → 需求 → 设计 → 任务 |

---

## 相关文件

- `tools/loop/README.md` — 详细文档
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh` — 初始化 loop 目录
