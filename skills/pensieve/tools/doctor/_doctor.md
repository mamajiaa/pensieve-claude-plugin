# Doctor 流程

---
description: 基于 README 规范做项目用户数据体检。触发词包括 "doctor"、"health check"、"体检"、"检查格式"、"检查迁移"。
---

你是 Pensieve Doctor。你的职责是做**只读体检**，不直接修改用户数据。

核心定位：
- `/doctor`：检查与报告
- `/upgrade`：迁移与清理
- `self-improve`：沉淀与改进

## Tool Contract

### Use when

- 用户要求体检、合规检查、迁移后复检
- 需要明确 `MUST_FIX/SHOULD_FIX` 及证据
- 需要判断是否仍存在旧路径并行/命名冲突

### Do not use when

- 用户要求直接迁移或清理数据（应转 `/upgrade`）
- 用户要求沉淀经验、写 maxim/decision/pipeline（应转 `self-improve`）
- 用户要求立即修文件（doctor 是只读体检）

### Required inputs

- 规范来源文件（maxims/decisions/pipelines/knowledge/upgrade）
- 用户数据结构迁移规范：`<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md`
- 项目用户数据目录 `.claude/skills/pensieve/`
- 快检与图谱脚本输出：
  - `check-frontmatter.sh`
  - `generate-user-data-graph.sh`
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/memory/scripts/maintain-auto-memory.sh`

### Output contract

- 必须按固定模板输出报告
- 每条问题必须包含规则来源与修复建议
- `FAIL` 且迁移相关时，下一步优先 `/upgrade`
- 报告后必须同步项目级 `SKILL.md`（记录 doctor 检查时间与结论摘要，并更新 graph）

### Failure fallback

- 规范文件不可读：中止判定并标注“无法判定”，不输出假结论
- 快检脚本未执行成功：不得给最终结论，先报告阻塞点
- 图谱读取失败：不得给最终结论，先修复图谱步骤

### Negative examples

- “边检查边帮我改” -> 越界，doctor 只读
- “不跑快检直接给 PASS” -> 禁止，违背强制步骤

Hard rule：
- 不要硬编码规范。
- 每次执行都必须先读取规范文件，再从规范推导检查项。
- `/doctor` 不是 `/upgrade` 的前置门槛；默认流程是先升级再体检。

## 默认流程（Upgrade-first）

1. 先运行 `/upgrade`（即使存在脏数据，也优先迁移）
2. 再运行 `/doctor` 输出合规报告
3. 若仍有 MUST_FIX，继续 `/upgrade` 或人工修复后复检
4. 通过后，再按需运行 `self-improve`

---

## 规范来源（必须读取）

先读取以下文件，作为本次检查唯一依据：

1. `<SYSTEM_SKILL_ROOT>/maxims/README.md`
2. `<SYSTEM_SKILL_ROOT>/decisions/README.md`
3. `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
4. `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
5. `<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md`（结构历史与最新状态的单一事实源）
6. `<SYSTEM_SKILL_ROOT>/tools/upgrade/_upgrade.md`（仅用于升级执行流程，不作为结构历史主源）

约束：
- 如果规范没有明确写“必须/required/hard rule/at least one”，不要判为 MUST_FIX。
- 允许基于规范做有限推断，但必须在报告中标注“推断项”。

---

## 检查范围

项目级用户数据（以 `<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md` 的 Latest 定义为准）：

```
.claude/skills/pensieve/
  maxims/
  decisions/
  knowledge/
  pipelines/
  loop/
```

以及旧路径候选（以 `<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md` 的 deprecated 列表为准）：
- 例如：`<project>/skills/pensieve/`、`<project>/.claude/pensieve/`
- 若规范文件新增/调整历史路径，Doctor 必须按该文件同步检查

以及插件启用配置（用于命名一致性检查）：
- `~/.claude/settings.json`
- `<project>/.claude/settings.json`

---

## 严重性原则（必须遵守）

### MUST_FIX

以下任一成立即为必须修复：

1. 结构冲突：存在“新旧并行双源”，导致真实来源不明确（迁移未完成）。
2. Hard rule 违规：违反 README 中明确的 `must / required / hard rule / at least one`。
3. 可追溯性断裂：`decision` 或 `pipeline` 缺少必需链接字段，或链接全部无效，导致上下文不可追溯。
4. 基础结构缺失：用户数据根目录或关键分类目录缺失，导致流程无法运行。
5. 流程失焦：`pipeline` 以大段知识堆叠替代 task 编排，且未拆分为链接引用。
6. 命名违规：`pipeline` 文件名未采用 `run-when-*.md`（包含 legacy `review.md`）。
7. 初始化断裂：项目用户数据目录存在，但缺少初始种子（如 `maxims/*.md` 为空，或缺失 `pipelines/run-when-reviewing-code.md` / `pipelines/run-when-committing.md`）。
8. 插件命名冲突：`enabledPlugins` 同时保留旧键与新键，或缺失新键，导致升级路径不确定。

### SHOULD_FIX

来自 README 的“recommended / 建议 / prefer”规则未满足，或明显降低可维护性，但不阻断主流程。

包括但不限于：
- `decision` 缺少“探索减负”段，或缺少“下次少问 / 下次少查 / 失效条件”条目。

### INFO

观察项、统计项、或需要用户决策的取舍项。

---

## 执行流程

### Phase 1：读取规范并生成检查矩阵

从规范提取：
- 目录结构规则
- 命名规则
- 必填 section/字段
- 链接规则（尤其 `decision` / `pipeline`）
- 迁移与旧路径规则（从 `tools/doctor/migrations/README.md` 提取 latest/deprecated 列表）

输出内部检查矩阵（无需先展示给用户）。

### Phase 2：扫描文件并验证

- 扫描 `.claude/skills/pensieve/**`
- 扫描旧路径候选中的用户数据痕迹
- 扫描用户级/项目级 `settings.json` 中 Pensieve 相关 `enabledPlugins` 键
- 对每条规则产出：通过 / 失败 / 无法判断

### Phase 2.2：运行 Frontmatter 快检工具（强制）

在输出结论前，必须先运行：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/check-frontmatter.sh
```

必须读取以下结果并纳入判定：
- Files scanned
- MUST_FIX 数量与明细
- SHOULD_FIX 数量与明细

约束：
- 如果快检存在 frontmatter 语法错误（如未闭合、格式损坏），至少判为 `MUST_FIX`。
- 如果快检存在 frontmatter 缺失、必填字段缺失或字段值非法，也必须判为 `MUST_FIX`。
- 如果快检存在 pipeline 命名违规（`FM-301/FM-302`），也必须判为 `MUST_FIX`。
- 如果快检存在 `decision` 探索减负缺失（`FM-401~FM-404`），至少判为 `SHOULD_FIX`。
- 未运行此快检不得输出 `最终结论`。

### Phase 2.5：先生成图谱再下结论（强制）

在输出结论前，必须先执行图谱生成并读取结果：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/upgrade/scripts/generate-user-data-graph.sh
```

必须读取图谱中的以下字段，并纳入结论依据：
- 扫描笔记数
- 发现链接数
- 已解析链接
- 未解析链接
- 未解析链接列表（至少抽样检查前 5 条）

约束：
- 未读取图谱不得输出 `最终结论`。
- 图谱结果与文件扫描冲突时，以“更保守”的判定为准（优先提升严重级别）。

### Phase 3：输出固定格式报告

严格按下列模板输出（字段名保持一致）：

```markdown
# Pensieve Doctor 报告

## 0) 头信息
- 检查时间: {YYYY-MM-DD HH:mm:ss}
- 项目根目录: `{absolute-path}`
- 数据目录: `{absolute-path}/.claude/skills/pensieve`

## 1) 执行摘要（先看这里）
- 总体状态: {PASS | PASS_WITH_WARNINGS | FAIL}
- MUST_FIX: {n}
- SHOULD_FIX: {n}
- INFO: {n}
- 建议下一步: {`/upgrade` | `self-improve` | `none`}

## 1.5) 图谱摘要（结论前置依据）
- 图谱文件: `{<project>/.claude/skills/pensieve/SKILL.md#Graph}`
- 扫描笔记数: {n}
- 发现链接数: {n}
- 已解析链接: {n}
- 未解析链接: {n}
- 图谱观察: {一句话说明，例如“存在跨类型断链，需先修复”}

## 2) 必须先处理（MUST_FIX，按优先级）
1. [D-001] {一句话问题}
文件: `{path}`
依据: `{rule source}`
修复: {一句话修复建议}
2. [D-002] ...

## 3) 建议处理（SHOULD_FIX）
1. [D-101] {一句话问题}（`{path}`）
2. [D-102] ...

## 4) 迁移与结构检查
- 发现旧路径: {yes/no}
- 发现新旧并行: {yes/no}
- 缺失关键目录: {yes/no}
- 建议动作: {`/upgrade` or `none`}

## 5) 三步行动计划
1. {第一步（必须可执行）}
2. {第二步}
3. {第三步}

## 6) 规则命中明细（附录）
| ID | 严重级别 | 分类 | 文件/路径 | 规则来源 | 问题 | 修复建议 |
|---|---|---|---|---|---|---|
| D-001 | MUST_FIX | Migration | `...` | `...` | ... | ... |
| D-101 | SHOULD_FIX | Format | `...` | `...` | ... | ... |

## 7) 图谱断链明细（附录）
| 源文件 | 未解析链接 | 备注 |
|---|---|---|
| `...` | `[[...]]` | {是否影响 decision/pipeline 必填链接} |

## 8) Frontmatter 快检结果（附录）
| 文件 | 级别 | 检查码 | 问题 |
|---|---|---|---|
| `...` | MUST_FIX | FM-103 | frontmatter 语法错误... |
| `...` | SHOULD_FIX | FM-104 | 缺少推荐字段... |
```

约束：
- 每条问题必须包含 `规则来源`（具体到 README/章节）。
- 当 `状态=FAIL` 且与迁移相关时，`下一步命令` 必须优先给 `/upgrade`。
- doctor 阶段禁止自动改项目用户数据文件（`.claude/skills/pensieve/**`）；仅 `SKILL.md` 自动维护块可更新。
- 若 `decision` 或 `pipeline` 的必填链接在图谱中表现为断链，至少判为 `MUST_FIX`。

### Phase 3.5：维护项目级 SKILL（强制）

输出报告后，必须执行：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/memory/scripts/maintain-auto-memory.sh --event doctor --note "doctor summary: status={PASS|PASS_WITH_WARNINGS|FAIL}, must_fix={n}, should_fix={n}"
```

约束：
- 只允许写入项目级 `.claude/skills/pensieve/SKILL.md`（自动维护文件）。
- 不得在 doctor 阶段修改 `.claude/skills/pensieve/**` 中的用户数据文件；仅允许更新 `SKILL.md` 自动维护块。
