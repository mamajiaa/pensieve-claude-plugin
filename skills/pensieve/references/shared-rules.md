# 共享规则

所有工具的跨领域硬规则。单一事实源——各 tool file 引用此处，不再内联。

---

## 版本更新优先（Hard Rule）

版本更新前置检查统一由 `/upgrade` 负责，且是最高优先级门槛。

- 涉及"更新版本/插件异常/版本不确定/兼容问题"时，优先路由 `/upgrade`。
- 执行 `/init` 或 `/doctor` 前，若版本状态不明，先完成 `/upgrade`。
- 默认流程：`/upgrade` → `/doctor` → `/self-improve`。
- `/doctor` 不是 `/upgrade` 的前置门槛。

---

## 确认再执行（Hard Rule）

用户未显式下达工具命令时，先用一句话确认再执行。禁止按候选意图自动开跑。

- Loop Phase 2 上下文摘要必须获得用户确认后才进入 Phase 3。
- Self-Improve 在显式触发或 pipeline 触发时可直接沉淀，无需额外确认。
- 写操作以各工具 `Tool Contract` 为准，不额外增加全局“先草稿后落盘”门槛。

---

## 语义链接规则（Hard Rule）

三种链接关系：`基于` / `导致` / `相关`。

关联强度要求：
- `decision`：**至少一条有效 `[[...]]` 链接必填**
- `pipeline`：**至少一条有效 `[[...]]` 链接必填**
- `knowledge`：建议填写链接（可空）
- `maxim`：建议填写来源链接（可空）

Loop 输出若成为 `decision` 或 `pipeline`，必须在 wrap-up 前补齐链接。

---

## 数据边界

- **系统能力**（随插件更新）：`<SYSTEM_SKILL_ROOT>/`（`skills/pensieve/` 内，插件管理）
  - 包含 tools / scripts / system knowledge / 格式 README
  - 不内置 pipelines / maxims 内容
- **用户数据**（项目级，永不覆盖）：`<USER_DATA_ROOT>/`（`<project>/.claude/skills/pensieve/`）
  - 完整目录结构见 `<SYSTEM_SKILL_ROOT>/references/directory-layout.md`

路径约定（由 SessionStart hook 注入）：
- `<SYSTEM_SKILL_ROOT>` = 插件内 `skills/pensieve/` 绝对路径
- `<USER_DATA_ROOT>` = 项目级 `.claude/skills/pensieve/` 绝对路径

---

## 规范来源（先读后写）

创建或检查任何类型的用户数据前，先读取对应的格式规范 README：

1. `<SYSTEM_SKILL_ROOT>/maxims/README.md`
2. `<SYSTEM_SKILL_ROOT>/decisions/README.md`
3. `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
4. `<SYSTEM_SKILL_ROOT>/knowledge/README.md`

约束：
- 规范没有明确写 `must / required / hard rule / at least one` 的，不得判为 MUST_FIX。
- 允许基于规范做有限推断，但必须标注"推断项"。

---

## 置信度门禁（Pipeline 输出质量）

Pipeline 输出中每个候选问题标注置信度（0-100）：

| 范围 | 处理 |
|------|------|
| >= 80 | 进入最终报告 |
| 50-79 | 标注"待验证"，不直接输出为定论 |
| < 50 | 丢弃 |

仅报告 >= 80 的问题作为确定性结论。
