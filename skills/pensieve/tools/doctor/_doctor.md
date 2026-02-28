---
description: 只读体检工具：基于 README 规范输出 PASS/FAIL 与 MUST_FIX/SHOULD_FIX 证据清单，不直接改文件。若跳过体检继续开发，结构问题会被持续放大。触发词：doctor、health check、体检、检查格式、检查迁移。
---

# Doctor 流程

> 工具边界见 `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | 共享规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` | 目录约定见 `<SYSTEM_SKILL_ROOT>/references/directory-layout.md`

只读体检，不直接修改用户数据。

## Tool Contract

### Use when

- 用户要求体检、合规检查、迁移后复检
- 需要明确 `MUST_FIX/SHOULD_FIX` 及证据
- 需要判断是否仍存在旧路径并行/命名冲突
- 需要确认是否存在非项目级 pensieve skill 或独立 graph 遗留文件

### Required inputs

- 规范来源文件（见下方"规范来源"）
- 用户数据结构迁移规范：`<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md`
- 项目用户数据目录 `.claude/skills/pensieve/`
- 共享结构扫描脚本输出：`scan-structure.sh`（Doctor/Upgrade 共用）
- 快检与图谱脚本输出：`check-frontmatter.sh`、`generate-user-data-graph.sh`
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh`

### Output contract

- 按固定模板输出报告
- 每条问题包含规则来源与修复建议
- `FAIL` 且迁移相关时，下一步优先 `upgrade`
- 若发现历史规范 README 副本，标记为 `MUST_FIX` 并建议执行 `upgrade` 清理
- 报告后同步项目级 `SKILL.md`（记录 doctor 检查时间与结论摘要）

### Failure fallback

- 规范文件不可读：中止判定，标注"无法判定"——没有规范基准的结论是不可靠的
- 快检脚本未执行成功：不给最终结论，先报告阻塞点——快检覆盖了 frontmatter 格式验证，跳过它结论不完整
- 图谱读取失败：不给最终结论，先修复图谱步骤——图谱验证了链接连通性

### Negative examples

- "边检查边帮我改" → doctor 只读，因为同时修改和检查会混淆"检查结果反映的是修改前还是修改后的状态"
- "不跑快检直接给 PASS" → 快检覆盖了人工扫描容易遗漏的格式问题（frontmatter 闭合、字段完整性等），跳过它结论不可信

从规范推导检查项而非硬编码，这样规范更新后检查项自动同步，不会出现"规范改了但检查没改"的漂移。

---

## 规范来源

先读取以下文件，作为本次检查唯一依据：

1. `<SYSTEM_SKILL_ROOT>/maxims/README.md`
2. `<SYSTEM_SKILL_ROOT>/decisions/README.md`
3. `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
4. `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
5. `<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md`（结构历史与最新状态的单一事实源）
6. `<SYSTEM_SKILL_ROOT>/tools/upgrade/_upgrade.md`（仅用于升级执行流程，不作为结构历史主源）

> 通用约束见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` § 规范来源

---

## 检查范围

项目级用户数据（以 `migrations/README.md` 的 Latest 定义为准）及旧路径候选（以其 deprecated 列表为准）。

插件启用配置（命名一致性检查）：
- `~/.claude/settings.json`
- `<project>/.claude/settings.json`

---

## 严重性原则

### MUST_FIX

以下情况说明数据结构存在实质风险，应优先修复：

1. **结构冲突**：存在"新旧并行双源"——真实来源不明确会导致工具读到错误数据。
2. **规范违规**：违反 README 中的 `must / required / hard rule / at least one`。
3. **可追溯性断裂**：`decision` 或 `pipeline` 缺少链接字段或链接全部无效——知识网络断连后图谱无法追踪。
4. **基础结构缺失**：用户数据根目录或关键分类目录缺失。
5. **流程失焦**：`pipeline` 以大段知识堆叠替代 task 编排，且未拆分为链接引用——pipeline 应聚焦执行步骤。
6. **命名违规**：`pipeline` 文件名未采用 `run-when-*.md`——统一命名让 init/upgrade 脚本能可靠定位文件。
7. **初始化断裂**：用户数据目录存在但缺少初始种子。
8. **插件命名冲突**：`enabledPlugins` 同时保留旧键与新键，或缺失新键。
9. **范围违规**：发现插件级/用户级 pensieve skill 副本，未收敛到项目级单根目录。
10. **遗留文件**：发现独立 graph 文件（`_pensieve-graph*.md`/`pensieve-graph*.md`/`graph*.md`）。
11. **规范副本遗留**：发现项目级子目录中的历史规范 README 副本（`.claude/skills/pensieve/{maxims,decisions,knowledge,pipelines,loop}/{README*.md,readme*.md}`）。

### SHOULD_FIX

来自 README 的"recommended / 建议 / prefer"规则未满足，或明显降低可维护性，但不阻断主流程。

包括但不限于：
- `decision` 缺少"探索减负"段，或缺少"下次少问 / 下次少查 / 失效条件"条目。

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
- 结构判定统一由共享脚本 `scan-structure.sh` 实现，避免 Doctor/Upgrade 维护两套检查逻辑

输出内部检查矩阵（无需先展示给用户）。

### Phase 2：扫描文件并验证

先运行共享结构扫描（Doctor/Upgrade 共用）：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh --output .state/pensieve-structure-scan.json
```

读取扫描结果并纳入判定：
- `status`（`aligned` / `drift`）
- `summary.must_fix_count` / `summary.should_fix_count`
- `flags.*`（旧路径、graph、README 副本、关键文件漂移、settings 键冲突等）
- `findings[]`（作为报告 `MUST_FIX/SHOULD_FIX` 证据来源）

约束：
- Doctor 不改用户数据文件；结构扫描只读。
- 若 `summary.must_fix_count > 0`，结构结论至少为 `FAIL`，建议动作优先 `upgrade`。

### Phase 2.2：运行 Frontmatter 快检工具

在输出结论前先运行快检——它覆盖了 frontmatter 格式验证（闭合、字段完整性、命名规范），这些是人工扫描最容易遗漏的部分：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/check-frontmatter.sh
```

读取以下结果并纳入判定：
- Files scanned
- MUST_FIX 数量与明细
- SHOULD_FIX 数量与明细

判定规则：
- frontmatter 语法错误（未闭合、格式损坏）→ `MUST_FIX`
- frontmatter 缺失、必填字段缺失或字段值非法 → `MUST_FIX`
- pipeline 命名违规（`FM-301/FM-302`）→ `MUST_FIX`
- `decision` 探索减负缺失（`FM-401~FM-404`）→ `SHOULD_FIX`

### Phase 2.5：生成图谱并验证链接

在输出结论前先执行图谱生成——图谱验证了知识网络的链接连通性，断链意味着知识无法被追踪：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/upgrade/scripts/generate-user-data-graph.sh
```

读取图谱中的以下字段，并纳入结论依据：
- 扫描笔记数 / 发现链接数 / 已解析链接 / 未解析链接
- 未解析链接列表（至少抽样检查前 5 条）

图谱结果与文件扫描冲突时，以更保守的判定为准。

### Phase 3：输出固定格式报告

按下列模板输出（统一格式让报告在不同项目间可对比）：

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
- 建议下一步: {`upgrade` | `self-improve` | `none`}

## 1.5) 图谱摘要（结论前置依据）
- 图谱文件: `{<project>/.claude/skills/pensieve/SKILL.md#Graph}`
- 扫描笔记数: {n}
- 发现链接数: {n}
- 已解析链接: {n}
- 未解析链接: {n}
- 图谱观察: {一句话说明}

## 2) 需优先处理（MUST_FIX，按优先级）
1. [D-001] {一句话问题}
文件: `{path}`
依据: `{rule source}`
修复: {一句话修复建议}

## 3) 建议处理（SHOULD_FIX）
1. [D-101] {一句话问题}（`{path}`）

## 4) 迁移与结构检查
- 发现旧路径: {yes/no}
- 发现新旧并行: {yes/no}
- 发现非项目级 skill 根: {yes/no}
- 发现独立 graph 文件: {yes/no}
- 缺失关键目录: {yes/no}
- 建议动作: {`upgrade` or `none`}

## 5) 三步行动计划
1. {第一步（可执行的具体操作）}
2. {第二步}
3. {第三步}

## 6) 规则命中明细（附录）
| ID | 严重级别 | 分类 | 文件/路径 | 规则来源 | 问题 | 修复建议 |
|---|---|---|---|---|---|---|

## 7) 图谱断链明细（附录）
| 源文件 | 未解析链接 | 备注 |
|---|---|---|

## 8) Frontmatter 快检结果（附录）
| 文件 | 级别 | 检查码 | 问题 |
|---|---|---|---|
```

注意事项：
- 每条问题包含 `规则来源`（具体到 README/章节），让用户能追溯判定依据。
- `状态=FAIL` 且迁移相关时，`下一步` 优先给 `upgrade`。
- doctor 阶段不改项目用户数据文件，仅 `SKILL.md` 自动维护块可更新——同时修改和检查会混淆状态。
- `decision` 或 `pipeline` 的断链至少判为 `MUST_FIX`。

### Phase 3.5：维护项目级 SKILL

输出报告后，执行：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event doctor --note "doctor summary: status={PASS|PASS_WITH_WARNINGS|FAIL}, must_fix={n}, should_fix={n}"
```

仅允许写入项目级 `.claude/skills/pensieve/SKILL.md`（自动维护文件）。

### Phase 4：Auto Memory 补齐检查

检查 Claude Code 的 auto memory（`MEMORY.md`）是否包含 Pensieve 使用说明。

1. 读取 auto memory 入口 `MEMORY.md`
2. 检查是否已存在 `@pensieve.md` 条目
3. **若已存在**：跳过。**若缺失**：追加 `## Pensieve\n- @pensieve.md`

注意事项：
- 仅追加，不修改已有内容
- 写入前确认未超 200 行上限
- 若无法定位 auto memory 目录，在报告中标注为 SHOULD_FIX
