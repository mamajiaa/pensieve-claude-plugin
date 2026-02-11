# Pipelines（流程）

可执行工作流，用于定义从输入到验证再到输出的闭环。

> 说明：内置工具已迁移到 `tools/`。插件不再内置 pipelines。初始 pipelines 在安装/迁移时种子化到 `.claude/pensieve/pipelines/`，用户可编辑。

## 目的

Pipeline 的目标是构建**可验证的执行闭环**，而不是堆信息。

Pipeline 负责编排流程，不负责存储知识。背景信息应拆到其他载体并通过链接引用：

- **Knowledge**：外部标准、参考资料、检查项
- **Maxims**：跨场景原则
- **Decisions**：上下文决策与理由
- **外部 skills/tools**：专用能力与重指令

## 写 Pipeline 前的反问（必须）

在落笔前先问：

**“这段内容是否直接改变 task 的顺序、输入、步骤或完成标准？”**

- 如果答案是“否”，这段内容不应放在 pipeline 主体，必须拆出去并用 `[[...]]` 引用。
- 如果答案是“是”，才保留在 pipeline 主体。

快速拆分规则：
1. 原理、理论、长解释 -> `knowledge`
2. 项目取舍、策略结论 -> `decision`
3. 跨场景原则 -> `maxim`
4. pipeline 仅保留：任务编排 + 验证闭环 + 关键约束

闭环模型：

```
Input -> Execute -> Validate -> Output
         ^        |
         +-- Feedback --+
```

## 好的 Pipeline 长什么样

| 特征 | 价值（LLM 视角） |
|---|---|
| 闭环明确 | 防止漂移，清楚知道何时开始/结束 |
| 使用真实信号 | 用真实输出验证，而非“看起来对” |
| 文件化留痕 | 可追溯，能定位问题步骤 |
| 可测试 | 不依赖“感觉正确” |
| 工具友好 | 明确哪些步骤应借助工具降不确定性 |

## 验证必须依赖真实反馈

反模式：读代码 -> 感觉正确 -> 继续

正确方式：执行 -> 拿到输出/日志 -> 基于结果判断

| 验证类型 | 真实反馈来源 |
|---|---|
| 构建 | 编译输出、构建日志 |
| 测试 | 测试结果、覆盖率 |
| 运行时 | 应用日志、错误栈 |
| 集成 | API 响应、DB 状态 |

关键点：优先系统反馈，不依赖模型臆断。

## 捕获标准

核心问题：**如果不固化这个流程，哪些决策会被反复重做？**

### 是否需要新建 pipeline

先判断：能否通过组合现有 pipeline 解决？

| 情况 | 动作 |
|---|---|
| 现有 pipeline 组合可覆盖 | 组合/重排，不新增 |
| 仅缺少验证步骤 | 在现有 pipeline 增补 |
| 执行闭环完全不同 | 新建 pipeline |

### 适合沉淀的信号

| 信号 | 说明 |
|---|---|
| 多个 loop 出现相同任务结构 | 步骤已稳定，可抽象 |
| 某步骤反复漏掉 | 需要 pipeline 强制约束 |
| 依赖多个知识来源协同 | 需要流程统一编排 |

### 演化路径

1. 先达到可运行基线（哪怕验证先手动）
2. 再把脆弱/重复步骤工具化
3. 最后做步骤重排，减少回退

反模式：还没跑通就追求“完美设计”。

## 关系与演化

| 方向 | 说明 |
|---|---|
| Pipeline <- Knowledge | 外部标准约束流程 |
| Pipeline -> Tasks | Pipeline 定义蓝图，Task 执行实例 |
| Pipeline <-> Decision | 执行中的决策可反哺流程 |

## 链接规则（Pipeline 强制）

每条 pipeline 正文至少包含一条显式链接，用于追溯来源与影响。

推荐字段：
- `基于`：依赖哪些 decision/knowledge
- `导致`：触发哪些输出或后续流程
- `相关`：相邻流程或关联主题

Hard rule：
- 任何不直接服务于任务编排的长段落，都必须迁移到被链接文件中。

## Pipeline 与 Tasks 区分

| 类型 | 本质 | 关注点 |
|---|---|---|
| Pipeline | 任务蓝图 + 验证闭环 | “按什么顺序做什么” |
| Tasks | 运行时实例 | “现在执行哪一步” |

Pipeline 应直接产出可实例化任务模板。

## 编写规范

### 目录结构

```
.claude/pensieve/pipelines/
├── run-when-*.md
```

### 命名约定

Hard rule（必须）：
- pipeline 文件名必须使用触发意图风格：`run-when-*.md`
- 不保留旧命名兼容（如 `review.md` 必须改名）

| 命名模式 | 类型 | 说明 |
|---|---|---|
| `run-when-*.md` | 用户定义 | 从文件名直接看出“何时调用” |
| `_*.md` | 禁止 | 历史系统命名，不再使用 |

### 文件模板

```markdown
# Pipeline 名称

---
id: run-when-xxx
type: pipeline
title: Pipeline 名称
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [pensieve, pipeline]
description: 简要说明。触发词如 "trigger1", "trigger2"。
---

Role: You are [doing what]...

## 核心原则

- **Principle 1**: 简短可执行
- **Principle 2**: 简短可执行

---

## Task Blueprint

### Task 1: 任务名

**Goal**: 本任务目标

**Read Inputs**:
1. 必读文件/路径
2. 必读文件/路径

**Steps**:
1. 具体动作
2. 具体动作

**Done When**: 可验证的完成条件

---

### Task 2: 任务名

**Goal**: 本任务目标

**Read Inputs**:
1. 上一步输出

**CRITICAL**: 关键警告（如有）

**Steps**:
1. 具体动作
2. **向用户展示并等待确认**

**Done When**: 可验证的完成条件

---

### Task 3: 沉淀结论（可选）

**Goal**: 保存可复用结论

**Read Inputs**:
1. 前序任务输出

**Steps**:
1. 项目选择写入/更新 `decision`
2. 外部资料写入/更新 `knowledge`
3. 补充 `基于/导致/相关` 链接
4. 若无需沉淀，明确记录 "no capture"

**Done When**: 明确写入或明确跳过原因

---

## 相关文件

- `path/to/file` — 说明
```

### 格式检查清单

| 要素 | 要求 |
|---|---|
| 文件名 | 必须为 `run-when-*.md`，从文件名即可判断触发场景 |
| frontmatter 必填 | `id/type/title/status/created/updated/tags/description` |
| `description` | 位于 frontmatter，包含触发词 |
| Role 行 | 以 "You are..." 开头定义角色 |
| 核心原则 | 1-3 条，短且可执行 |
| 不堆知识 | 长背景放到 Knowledge/Maxims/Decisions/Skills |
| 内容拆分 | 若段落不影响 task 编排，必须拆分并改为 `[[...]]` 引用 |
| Task Blueprint | 必须显式 `Task 1/2/3...` 顺序 |
| **Goal** | 每个任务必须有 |
| **Read Inputs** | 文件/路径必须写清 |
| **Steps** | 编号、具体、可执行 |
| **Done When** | 必须可验证 |
| **CRITICAL** / **DO NOT SKIP** | 关键步骤强提示 |
| 用户确认 | 显式写“等待确认” |
| 链接 | 正文至少一条有效链接 |

## 备注

- Pipeline 应轻量且可执行
- 每次只解决一个闭环问题，避免超大流程
- 不确定时先最小可运行版本，再迭代
