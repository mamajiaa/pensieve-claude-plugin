# 自改进 Pipeline

---
description: Knowledge capture workflow. Trigger when loop completes or user says "capture", "record", or "save".
---

你在帮助把经验与模式沉淀到 Pensieve 的四类用户数据中：`maxim / decision / pipeline / knowledge`。

**系统提示词**（tools/scripts/系统 knowledge）位于插件内部，随插件更新维护。

**用户数据**位于项目级 `.claude/pensieve/`，永不被插件更新覆盖。

## Tool Contract

### Use when

- loop 完成后要沉淀经验
- 用户明确要求“沉淀/记录/复盘/规范化”
- 目标是新增或改进 `maxim / decision / pipeline / knowledge`

### Do not use when

- 用户要做迁移/目录清理/历史兼容处理（应转 `/upgrade`）
- 用户要做结构合规判定（应转 `/doctor`）
- 用户还未确认沉淀对象与分类（先问清再继续）

### Required inputs

- 用户确认过的“核心结论”与目标分类
- 目标类型对应 README：
  - `<SYSTEM_SKILL_ROOT>/maxims/README.md`
  - `<SYSTEM_SKILL_ROOT>/decisions/README.md`
  - `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
  - `<SYSTEM_SKILL_ROOT>/knowledge/README.md`

### Output contract

- 先给分类建议与草稿，再等待用户确认
- 写入后必须反馈：写入路径 + 回链变更
- `decision/pipeline` 必须至少包含 1 条有效 `[[...]]` 链接

### Failure fallback

- 发现结构性问题（旧路径并行/目录缺失/格式大面积不符）：暂停写入，先建议 `/doctor`，必要时 `/upgrade`
- 无法判断分类：给 2-3 个候选并请求确认，不盲写

### Negative examples

- “先自动把这次会话都沉淀了，不用我确认” -> 禁止自动沉淀
- “顺便帮我把旧目录迁移掉” -> 不属于 self-improve 范围

## 职责边界（Hard Rule）

- `/selfimprove` 只负责沉淀与改进，不负责全量迁移体检。
- 迁移/结构合规体检由 `/doctor` 负责。
- 若执行中发现“旧路径并行、目录缺失、格式大面积不符”等问题，先建议运行 `/doctor`，必要时转 `/upgrade`。

## 核心原则

- **必须用户确认**：绝不自动沉淀，先询问
- **先读后写**：创建任何文件前必须阅读对应 README
- **分类稳定**：只使用 `maxim / decision / pipeline / knowledge`
- **结论优先**：标题与第一句话必须能独立表达结论
- **关系可追溯**：通过 `基于/导致/相关` 建立关联
- **准则单文件**：每条 `maxim` 必须是独立文件，不依赖索引文件
- **流程只做编排**：`pipeline` 只保留 task 编排与验证；理论背景必须外链

---

## 关联强度（Hard Rule）

- `decision`：**至少一条有效链接必填**（`基于/导致/相关` 三选一或多选）
- `pipeline`：**至少一条有效链接必填**
- `knowledge`：建议填写链接（可空）
- `maxim`：建议填写来源链接（可空）

---

## Phase 1: 理解意图

**目标**：澄清用户想沉淀什么结论。

**行动**：
1. 识别来源：loop 偏差、执行中发现的模式、用户明确指令、外部参考
2. 提炼一句核心结论
3. 判断结论归属的四类之一

---

## Phase 2: 分类建议并确认

**目标**：给出最小且正确的分类。

**行动**：
1. 对照分类：
   - `maxim`：跨场景长期原则
   - `decision`：当前情境下的项目选择
   - `pipeline`：可执行流程模板
   - `knowledge`：外部资料或方法沉淀
2. 输出分类建议并请求用户确认
3. 未获确认不得继续写入

**路径规则**：
- `maxim`：`.claude/pensieve/maxims/{one-sentence-conclusion}.md`
- `decision`：`.claude/pensieve/decisions/{date}-{conclusion}.md`
- `pipeline`：`.claude/pensieve/pipelines/run-when-*.md`
- `knowledge`：`.claude/pensieve/knowledge/{name}/content.md`

---

## Phase 3: 读取目标规范

**目标**：按现有规范写，不引入新概念。

**行动**：
1. 读取目标 README：
   - `<SYSTEM_SKILL_ROOT>/maxims/README.md`
   - `<SYSTEM_SKILL_ROOT>/decisions/README.md`
   - `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
   - `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
2. 把关联强度规则应用到草稿

---

## Phase 4: 草稿输出

**目标**：给出可直接落盘的草稿。

**行动**：
1. 写结论式标题
2. 写一条一句话结论
3. 写核心内容与关键文件
4. 按类型补链接：
   - decision/pipeline：至少 1 条有效 `[[...]]`
   - knowledge/maxim：可选但建议
5. 若是 `pipeline` 草稿，额外自检：
   - 哪些段落不影响 task 编排？
   - 这些段落是否已拆到 `knowledge/decision/maxim` 并改为链接？
6. 向用户展示草稿并等待确认

---

## Phase 5: 写入与回链

**目标**：落盘并保持知识网络连通。

**行动**：
1. 写入目标路径
2. 若新增 `maxim`，确保与相关 `decision/knowledge/pipeline` 建立链接
3. 如有必要，在关联文档补反向链接
4. 向用户确认写入位置与关联变更

---

## 相关文件

- `maxims/README.md` — Maxim 格式与标准
- `decisions/README.md` — Decision 格式与标准
- `pipelines/README.md` — Pipeline 格式与标准
- `knowledge/README.md` — Knowledge 格式与标准
