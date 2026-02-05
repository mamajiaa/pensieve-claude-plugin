---
description: 自动循环执行任务。当用户说"用 loop"、"loop 执行"、"使用 loop 模式"时触发。
---

# Loop 流程

你在编排一个自动循环执行流程：将复杂任务拆成可执行的子任务，并通过 subagent 执行；Stop Hook 负责自动接续。

## 核心原则

- **上下文隔离**：每个 task 由 subagent 执行，避免主窗口上下文膨胀
- **原子任务**：每个 task 必须可独立执行与验证
- **用户确认**：生成 tasks 前必须确认上下文理解
- **清晰交接**：subagent 只执行一个 task 后返回；Stop Hook 触发下一个

> **路径说明**：以下脚本路径相对于插件根目录（`skills/pensieve/` 的上级）。脚本内部已自定位，支持从任意工作目录调用。
>
> **重要**：在已安装插件的真实项目中，插件位于 Claude Code 的插件缓存目录里，不在你的项目仓库内。
> SessionStart hook 会把“系统 Skill 的绝对路径”注入到上下文中。
>
> 下文中出现的：
> - `<SYSTEM_SKILL_ROOT>`：指注入的系统 Skill 绝对路径（形如 `/.../plugins/.../skills/pensieve`）
> - `<USER_DATA_ROOT>`：指项目级用户数据目录（形如 `<project>/.claude/pensieve`）

---

## Phase 0: 简单任务判断

**在启动 loop 之前，先评估任务复杂度。**

如果任务满足以下条件，**主动建议直接完成**：
- 只涉及 1-2 个文件
- 改动范围清晰，无需探索
- 预估 1 个 task 即可完成

**建议话术**：
> 这个任务比较简单，直接完成会更快。要直接做还是走 loop？

用户选择直接完成 → 不走 loop，直接执行
用户坚持用 loop → 继续 Phase 1

---

## Phase 1: 初始化

**目标**：创建 task 列表与 loop 目录结构

**行动**：
1. 创建占位 task 获取 taskListId：
   ```
   TaskCreate subject="初始化 loop" description="1. 初始化 loop 目录 2. 为任务构建上下文 3. 生成并执行任务"
   # 返回 { taskListId: "abc-123-uuid", taskId: "1" }
   ```
   ⚠️ **必须使用返回的真实 taskListId**（如 `5e600100-9157-4888-...`），不是 "default"。
   如果你没有看到 taskListId：
   - 先确认你**真的调用了 TaskCreate 工具**（不是把 `TaskCreate ...` 当普通文本输出）
   - 展开工具输出（例如 `ctrl+o`）查看返回的 JSON
   - 从 JSON 中复制 `taskListId`

2. 获取真实 taskListId（更符合 AI 直觉，避免猜 ID）：
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/find-task-list-id.sh "初始化 loop"
   ```

3. 运行初始化脚本创建 loop 目录与 agent prompt：
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh <taskListId> <slug>
   ```
   **slug 参数**：根据任务内容生成简短英文标识（如 `snake-game`、`auth-module`），避免中文和空格。

   **重要**：这一步不要用 `run_in_background: true`。你需要立刻看到脚本输出的 `LOOP_DIR` 才能进入 Phase 2。

   脚本输出（记住这两个值）：
   ```
   TASK_LIST_ID=abc-123-uuid
   LOOP_DIR=.claude/pensieve/loop/2026-01-27-login
   ```

---

## Phase 2: 激活 Stop Hook

**目标**：确保 Stop Hook 能识别活跃 loop

从 `0.3.2` 起，`init-loop.sh` 会自动写入 loop marker：`/tmp/pensieve-loop-<taskListId>`，Stop Hook 会据此接管。

**重要**：无需再启动 `bind-loop.sh`（不再需要后台常驻进程 / `run_in_background: true`）。

---

## Phase 3: 记录上下文

**目标**：在生成任务前记录对话上下文

**行动**：
1. 创建并写入 `LOOP_DIR/_context.md`（Phase 1 不再生成模板文件，避免“已存在文件需先 Read 才能 Write”的摩擦）：

```markdown
# 对话上下文

## 事前 Context

### 交互历史
| 轮次 | 模型尝试 | 用户反馈 |
|------|----------|----------|
| 1 | ... | ... |

### 最终共识
- 目标：XXX
- 范围：YYY
- 约束：ZZZ

### 理解与假设
- 预计涉及的模块
- 预计的实现方式
- 预计的难点

### 文档引用
| 类型 | 路径 |
|------|------|
| requirements | 无需 / 路径 |
| design | 无需 / 路径 |
| plan | 无需 / 路径 |
```

2. **向用户展示上下文摘要并确认理解后再继续**

3. **按需创建 requirements/design**（参考模板）：

   | 条件 | 需要 | 模板 |
   |------|------|------|
   | 预估 6+ tasks / 跨多天 / 多模块联动 | requirements | `loop/REQUIREMENTS.template.md` |
   | 多方案权衡 / 决策影响后续开发 | design | `loop/DESIGN.template.md` |

   创建后将路径填入 `_context.md` 的“文档引用”。

---

## Phase 4: 生成任务

**目标**：将工作拆分为原子可执行任务

**关键**：未获得 Phase 3 的用户确认不得继续。

### 先获取可用 pipeline（用于任务设计）

在拆分任务前，先用脚本列出当前项目的所有 pipelines 和描述，判断是否存在可复用流程：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/pipeline/scripts/list-pipelines.sh
```

如果存在相关 pipeline，应优先基于它拆分 task；如果不存在，再按常规方式拆分。

### 任务粒度标准

**核心判断：agent 能否不问问题就执行？**

- 能 → 粒度合格
- 不能 → 需要拆分或补充细节

每个 task 必须：
- 指明需要创建/修改的文件或组件
- 涉及具体的写代码、改代码或测代码活动

### 行动

1. 拆分任务，确保每个 task 符合上述粒度标准
2. 创建 tasks，增量构建（每个 task 在前一个基础上推进）
3. **向用户展示任务列表并确认**

---

## Phase 5: 执行任务

**目标**：通过 subagent 执行每个 task

**行动**：
1. 为第一个 pending task 启动通用 subagent：

```
Task(
  subagent_type: "general-purpose",
  prompt: "Read .claude/pensieve/loop/{date}-{slug}/_agent-prompt.md and execute task_id={id}"
)
```

`_agent-prompt.md` 模板由 init-loop.sh 生成，包含：
- 角色定义（Linus Torvalds）
- Context 与准则路径
- 执行流程与约束

2. Subagent 读取模板 → TaskGet 获取任务 → 执行 → 返回
3. Stop Hook 检测 pending tasks → 注入强化信息 → 主窗口机械执行

---

## Phase 6: 收尾

**目标**：结束 loop，并根据执行经验自改进

**行动**：
1. 当所有任务完成时，Stop Hook 会提示主窗口是否执行自优化，并给出 `tools/self-improve/_self-improve.md` 的路径；无论是否执行，Loop 都会停止。
2. 如需手动提前结束 loop（`<taskListId>` 是 Phase 1 获取的 ID）：

   ✅ **正确**：
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh <taskListId>
   ```

   ❌ **错误**（缺少 task_list_id 参数）：
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh
   ```

---

## 阶段选择指南

| 任务特征 | 阶段组合 |
|----------|----------|
| 明确、小范围 | tasks |
| 需要了解代码 | plan → tasks |
| 需要技术设计 | plan → design → tasks |
| 需求不明确 | plan → requirements → design → tasks |

---

## 相关文件

- `tools/loop/README.md` — 详细文档
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh` — 初始化 loop 目录
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh` — 手动结束 loop
