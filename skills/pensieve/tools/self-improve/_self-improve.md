# 自改进（Auto Self-Improve）

---
description: 自动沉淀经验。由提交 pipeline 在 git commit 时调用，或用户手动触发。从会话上下文 + diff 中提取洞察并写入用户数据。
---

你在帮助把经验与模式沉淀到 Pensieve 的四类用户数据中：`maxim / decision / pipeline / knowledge`。

**系统提示词**（tools/scripts/系统 knowledge）位于插件内部，随插件更新维护。

**用户数据**位于项目级 `.claude/skills/pensieve/`，永不被插件更新覆盖。

## Tool Contract

### Use when

- 提交 pipeline（`run-when-committing.md`）调用（自动触发）
- loop 完成后的收尾沉淀
- 用户明确要求"沉淀/记录/复盘/规范化"

### Do not use when

- 用户要做迁移/目录清理/历史兼容处理（应转 `/upgrade`）
- 用户要做结构合规判定（应转 `/doctor`）

### Required inputs

- 会话上下文（当前对话中的探索、决策、调试记录）
- `git diff --cached`（即将提交的变更）
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/memory/scripts/maintain-auto-memory.sh`
- 目标类型对应 README：
  - `<SYSTEM_SKILL_ROOT>/maxims/README.md`
  - `<SYSTEM_SKILL_ROOT>/decisions/README.md`
  - `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
  - `<SYSTEM_SKILL_ROOT>/knowledge/README.md`

### Output contract

- 直接写入，不等待用户确认
- 写入后输出简短摘要：写入路径 + 沉淀类型
- `decision/pipeline` 必须至少包含 1 条有效 `[[...]]` 链接
- 若属于"探索型问题"，必须包含"探索减负检查项"（见下文）
- 写入后同步项目级 `SKILL.md`（固定路由 + graph）
- 质量门禁由调用方（pipeline）负责，self-improve 不做门禁判断

### Failure fallback

- 发现结构性问题（旧路径并行/目录缺失/格式大面积不符）：跳过沉淀，建议后续运行 `/doctor`
- 无法一次判断分类：按三层拆分（事实 -> `knowledge`，偏好 -> `decision`，强约束 -> `maxim`）

## 职责边界（Hard Rule）

- 自改进只负责沉淀与改进，不负责全量迁移体检。
- 迁移/结构合规体检由 `/doctor` 负责。
- 若执行中发现"旧路径并行、目录缺失、格式大面积不符"等问题，跳过沉淀并建议运行 `/doctor`。

## 语义分层分配（Hard Rule）

必须先判定语义层，再决定写入类型：

1. `knowledge`（IS）：系统事实、现状、边界、机制，即“是这样”
2. `decision`（WANT）：项目偏好、策略取舍、目标方向，即“我想这样”
3. `maxim`（MUST）：必须遵守的硬约束与底线，即“必须这样”

约束：
- 不允许用“knowledge 优先”替代语义判断。
- 同一洞察可同时拆分写入多层（IS/WANT/MUST），不强行只选一个。
- `pipeline` 仅表达 HOW（执行顺序与验证闭环），不替代 IS/WANT/MUST 三层。

### Pipeline 门禁（不满足则禁止新建）

- 同类任务在多个会话/loop 中重复出现
- 执行顺序会显著影响结果（步骤不可随意交换）
- 每步都有可验证完成标准（不是"感觉完成"）

---

## 核心原则

- **自动沉淀**：由 pipeline 触发时直接执行，不等待用户确认
- **先读后写**：创建任何文件前必须阅读对应 README
- **分类稳定**：只使用 `maxim / decision / pipeline / knowledge`
- **结论优先**：标题与第一句话必须能独立表达结论
- **关系可追溯**：通过 `基于/导致/相关` 建立关联
- **准则单文件**：每条 `maxim` 必须是独立文件，不依赖索引文件
- **流程只做编排**：`pipeline` 只保留 task 编排与验证；理论背景必须外链
- **目标是减探索**：沉淀应让"下一次从症状到定位"的路径更短

---

## 关联强度（Hard Rule）

- `decision`：**至少一条有效链接必填**（`基于/导致/相关` 三选一或多选）
- `pipeline`：**至少一条有效链接必填**
- `knowledge`：建议填写链接（可空）
- `maxim`：建议填写来源链接（可空）

---

## 探索减负知识模型（跨语言 / 跨项目）

当问题属于"需要探索代码库才能回答"时，若内容属于 IS（事实层），`knowledge` 应覆盖：

1. **状态转换**：某动作触发后，数据和视图如何变化
2. **症状 -> 根因 -> 定位**：看到什么现象，去哪里查，为什么
3. **边界与所有权**：谁有写权限、谁只能调用、跨模块如何流转
4. **不存在/已移除**：哪些能力不在当前系统，避免重复误判
5. **反模式与禁区**：看起来可行但会失败的路径及原因

### 探索减负检查项（探索型问题必须满足）

- 至少包含 1 条"症状 -> 根因 -> 定位"映射
- 至少包含 1 条"边界与所有权"约束
- 至少包含 1 条"反模式/不要做什么"
- 给出可验证信号（日志、测试、运行结果、可观测行为之一）

---

## Phase 1: 提取与分类

**目标**：从会话上下文 + diff 中提取洞察并确定分类。

**行动**：
1. 从会话中提取核心洞察（可以是多条）
2. 为每条洞察先判定语义层：
   - IS（事实） -> `knowledge`
   - WANT（偏好） -> `decision`
   - MUST（强约束） -> `maxim`
3. 若同一洞察同时包含 IS/WANT/MUST，拆成多条分别写入，不混写。
4. 再判断是否需要 `pipeline`（HOW）：
   - 仅当流程稳定、顺序不可交换、且每步可验证时，才新增/修改 `pipeline`
   - 不满足门禁：不得新建 `pipeline`

**路径规则**：
- `maxim`：`.claude/skills/pensieve/maxims/{one-sentence-conclusion}.md`
- `decision`：`.claude/skills/pensieve/decisions/{date}-{conclusion}.md`
- `pipeline`：`.claude/skills/pensieve/pipelines/run-when-*.md`
- `knowledge`：`.claude/skills/pensieve/knowledge/{name}/content.md`

---

## Phase 2: 读取规范 + 写入

**目标**：按规范写入并保持知识网络连通。

**行动**：
1. 读取目标 README（按分类选择）：
   - `<SYSTEM_SKILL_ROOT>/maxims/README.md`
   - `<SYSTEM_SKILL_ROOT>/decisions/README.md`
   - `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
   - `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
2. 生成内容（遵循 README 中的格式规范）：
   - 写结论式标题
   - 写一条一句话结论
   - 写核心内容与关键文件
   - 按类型补链接（decision/pipeline：至少 1 条 `[[...]]`；knowledge/maxim：可选）
3. 类型特定要求：
   - `decision`：强制包含"探索减负三项"（下次可以少问什么 / 下次可以少查什么 / 失效条件）
   - 探索型 `knowledge`：强制包含（状态转换 / 症状->根因->定位 / 边界与所有权 / 反模式 / 验证信号）
   - `pipeline`：自检"不影响 task 编排的段落是否已拆到外部并改为链接"
4. 写入目标路径
5. 若新增 `maxim`，确保与相关 `decision/knowledge/pipeline` 建立链接
6. 如有必要，在关联文档补反向链接
7. 运行项目级 SKILL 维护：
   - `bash <SYSTEM_SKILL_ROOT>/tools/memory/scripts/maintain-auto-memory.sh --event self-improve --note "auto-improve: {file1,file2,...}"`
8. 输出简短摘要（写入路径 + 沉淀类型）

---

## 相关文件

- `maxims/README.md` — Maxim 格式与标准
- `decisions/README.md` — Decision 格式与标准
- `pipelines/README.md` — Pipeline 格式与标准
- `knowledge/README.md` — Knowledge 格式与标准
