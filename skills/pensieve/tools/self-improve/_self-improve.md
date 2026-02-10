# 自改进 Pipeline

---
description: Knowledge capture workflow. Trigger when loop completes or user says "capture", "record", or "save".
---

你在帮助把经验与模式沉淀到 Pensieve 的知识系统中。

**系统提示词**（tools/scripts/系统 knowledge）位于插件内部，随插件更新维护。

**用户数据**位于项目级 `.claude/pensieve/`，永不被插件更新覆盖。

判断哪些内容值得保留、如何分类，并按正确格式写入。

## 核心原则

- **必须用户确认**：绝不自动沉淀，先询问
- **先读后写**：创建任何文件前必须阅读对应 README
- **删除优于新增**：系统越简单越可靠
- **分类正确**：内容必须匹配正确的知识类型

---

## Phase 1: 理解意图

**目标**：澄清用户想沉淀什么

**行动**：
1. 识别来源：
   - Loop 偏差（预期 vs 实际）
   - 执行中发现的模式
   - 用户明确指令
   - 外部参考资料

2. 如有需要，追问：
   - 具体要沉淀的洞见是什么？
   - 触发这个洞见的事件是什么？
   - 这条经验有多通用？

---

## Phase 2: Audit Existing Pensieve (Optional)

**Goal**: Find improvement opportunities in current project Pensieve data

**Actions**:
1. Ask the user if they want a Pensieve audit:
   - "Want me to review your current `.claude/pensieve/` contents for improvements?"
2. If yes:
   - Read each category README:
     - `<SYSTEM_SKILL_ROOT>/maxims/README.md`
     - `<SYSTEM_SKILL_ROOT>/decisions/README.md`
     - `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
     - `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
   - Review the corresponding project files under `.claude/pensieve/`
   - Flag format violations, missing fields, outdated content, or mis‑categorized items
   - Provide a concise review report with suggested fixes
3. **Do not edit anything without explicit user approval**

If the user declines, skip this phase and continue.

---

## Phase 3: Categorize

**目标**：找出当前项目 Pensieve 的优化点

**行动**：
1. 询问用户是否需要体检：
   - “要不要我检查一下当前 `.claude/pensieve/` 的内容是否有优化空间？”
2. 若用户同意：
   - 先阅读各目录 README：
     - `<SYSTEM_SKILL_ROOT>/maxims/README.md`
     - `<SYSTEM_SKILL_ROOT>/decisions/README.md`
     - `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
     - `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
   - 检查 `.claude/pensieve/` 下对应文件
   - 标注格式不符合、缺字段、过期内容或分类不当
   - 输出简洁的 review 报告并给出修正建议
3. **未经用户明确批准，不做任何修改**

用户拒绝则跳过本阶段，继续下一步。

---

## Phase 3: 分类

**目标**：确定正确的知识类型

**行动**：
1. 对照每一类的标准：

| 类型 | 特征 | README |
|------|------|--------|
| **maxim** | 普遍原则，跨项目/语言/领域 | `maxims/README.md` |
| **decision** | 情境相关的选择 | `decisions/README.md` |
| **pipeline** | 可执行流程，步骤清晰可复用 | `pipelines/README.md` |
| **knowledge** | 外部资料，文档/教程/规范 | `knowledge/README.md` |

2. **向用户呈现分类建议**：
   ```markdown
   ## Capture Recommendation

   [Content summary] → Recommend **[type]**

   Reason: [Explanation based on README criteria]

   Do you agree?
   ```

**关键**：未获得用户确认不得继续。

---

## Phase 4: Read Target README

**目标**：掌握该类别的格式与标准

**不得跳过**：README 定义了：
- 沉淀标准（什么值得写）
- 文件格式要求
- 命名规范
- 示例

**行动**：
1. 阅读对应 README：
   ```
   Read <SYSTEM_SKILL_ROOT>/{type}/README.md
   ```

2. 校验内容是否符合 README 标准

3. 若不符合，向用户说明并询问如何处理

---

## Phase 5: Draft Content

**目标**：严格按 README 格式写草稿

**行动**：
1. 按 README 规范写草稿

2. Choose the target location:
   - **pipeline** → `.claude/pensieve/pipelines/{name}.md` (project user data)
   - **maxim** → `.claude/pensieve/maxims/{name}.md` (project user data)
   - **decision** → `.claude/pensieve/decisions/{date}-{conclusion}.md` (project user data)
   - **knowledge** → `.claude/pensieve/knowledge/{name}/content.md` (project user data)

3. **向用户展示草稿**：
   ```markdown
   ## Draft Preview

   File: `{target_path}`

   ---
   [draft content]
   ---

   Write it?
   ```

**关键**：未获得用户批准不得写入。

---

## Phase 6: Write

**目标**：落盘沉淀

**必须先获得 Phase 4 批准**。

**行动**：
1. 写入 `{target_path}`
2. 向用户确认写入成功
3. 提示相关后续动作（如更新引用此内容的文件）

---

## 知识演化

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐  │
│  │   maxims/   │   │ decisions/  │   │ pipelines/  │   │ knowledge/  │  │
│  │  future guide│ ←│ past lessons│   │ workflows   │   │ external in │  │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘

演化路径：decision → 重复模式 → maxim → 指导 → pipeline
```

---

## 相关文件

- `maxims/README.md` — Maxim 格式与标准
- `decisions/README.md` — Decision 格式与标准
- `pipelines/README.md` — Pipeline 格式与标准
- `knowledge/README.md` — Knowledge 格式与标准
