---
description: 版本检查入口：先同步最新版本定义并确认是否有新版本。若已是最新，停止 upgrade 并询问用户是否运行 `doctor` 自检；仅在确认有新版本时才执行迁移校准（结构、关键文件内容、旧路径清理、插件键统一）。
---

# 升级工具

> 工具边界见 `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | 共享规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` | 目录约定见 `<SYSTEM_SKILL_ROOT>/references/directory-layout.md`

先同步最新版本并确认版本状态。若已是最新，停止 upgrade 并询问用户是否运行 `doctor` 自检；仅在确认有新版本时才进入迁移校准。

## Tool Contract

### Use when

- 用户要求更新插件版本或确认版本状态
- 用户要求把历史数据迁移到 `.claude/skills/pensieve/`
- 用户存在旧路径并行，需要统一到单一事实源
- 用户需要清理旧插件命名并切换到新引用
- 用户存在插件级/用户级 pensieve skill 副本，需清理为仅项目级
- 用户目录中存在独立 graph 文件（`_pensieve-graph*.md`/`pensieve-graph*.md`/`graph*.md`），需删除
- 用户目录中存在历史规范 README 副本（`.claude/skills/pensieve/{maxims,decisions,knowledge,pipelines,loop}/{README*.md,readme*.md}`），需删除

### Required inputs

- 最新版本来源（优先 GitHub / Marketplace，同步后落到本地插件）
- 版本状态（是否已按 `<PLUGIN_ROOT>/docs/update.md` 完成更新 + 重启）
- 用户数据结构迁移规范：`<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md`（单一事实源）
- 共享结构扫描脚本：`<SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh`（与 Doctor 共用）
- 两级 settings 路径：`~/.claude/settings.json`、`<project>/.claude/settings.json`
- 本地现状结构（旧路径与 `.claude/skills/pensieve/` 当前目录）
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh`

### Output contract

- 先输出版本检查结论（有新版本 / 已是最新 / 无法确认）
- 已是最新：仅询问用户是否运行 `doctor` 自检，不进入迁移
- 有新版本：输出迁移校准结论（结构 + 关键文件内容）
- 有新版本且有差异：输出迁移报告（旧路径 → 新路径、已替换关键文件、已清理旧路径）
- 有新版本但无差异：输出 no-op（结构与关键内容均一致）
- 关键文件都要对齐模板；内容不一致时先备份再替换
- 不输出 `PASS/FAIL`、`MUST_FIX/SHOULD_FIX`——合规判定由 `doctor` 负责
- 输出项目级 `SKILL.md` 更新结果
- 输出 Claude auto memory `~/.claude/projects/<project>/memory/MEMORY.md`（Pensieve 引导块）更新结果

### Failure fallback

- 更新状态无法确认：停在"确认更新 + 重启"，不进入迁移——版本不确定时迁移可能基于过时的结构定义
- 无法拉取最新版本定义：参考 GitHub 最新文档并给重试建议，不进入迁移
- 用户文件冲突无法自动合并：生成 `*.migrated.md` 并记录人工合并点
- 关键文件内容冲突：备份为 `*.bak.<timestamp>` 后直接替换——保留备份让用户可以对比差异

### Negative examples

- "版本已经最新，仍然直接进入迁移" → 不允许；无新版本时必须停在询问 `doctor` 自检
- "迁移时顺便给我判定 PASS/FAIL" → 迁移关注的是"对齐结构"，合规判定是另一个维度，由 doctor 负责

## Upgrade 特有规则

以下规则解释了 upgrade 工具的设计决策：

- **先清理旧插件命名，再迁移用户数据**：新旧并行会导致 Claude Code 加载两份插件，行为不可预测。
- **先从 GitHub/Marketplace 拉取最新版本结构定义，再做本地结构判定**：用本地旧定义做判定可能遗漏新增的必需目录。
- **目录历史与最新目标结构以 `migrations/README.md` 为准**：单一事实源避免多处定义不一致。
- **版本检查是唯一硬门禁**：未确认有新版本前，不进入迁移步骤。
- **无新版本即停止迁移**：只询问用户是否运行 `doctor` 自检，不自动继续。
- **发现旧路径/插件级副本/独立 graph 文件/历史规范 README 副本要清理**：多源并行与规范副本漂移是结构问题的主要来源。
- **升级或迁移后执行一次 `doctor`**：迁移操作可能引入新的格式问题，立即体检能尽早发现。
- **进入迁移前先检查 `<PLUGIN_ROOT>/docs/update.md`**：有新版本先更新插件并重启。
- 更新命令失败时，先查阅 [GitHub docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md) 再继续。

> 全局 upgrade-first 规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

---

## 版本检查前置（唯一硬门禁）

1. 按 `<PLUGIN_ROOT>/docs/update.md` 执行插件更新命令。
2. 更新失败则查阅 [GitHub docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md) 并重试。
3. 有新版本并完成更新：先重启 Claude Code，再进入迁移校准。
4. 已是最新：输出"当前已是最新版本"，询问用户是否运行 `doctor` 自检；不进入迁移。
5. 无法确认版本状态：先询问用户；未确认前不进入迁移。

## 完整迁移校准门禁（仅在有新版本时）

先执行与 Doctor 共用的结构扫描：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh --output .state/pensieve-structure-scan.pre.json
```

基于扫描输出判定：
- 读取 `summary.must_fix_count`、`flags.*`、`findings[]`
- 结构、旧路径、README 副本、关键文件漂移、settings 键冲突统一以此扫描结果为准
- 迁移动作只消费这份结果，不再在 Upgrade 文档内维护第二套检查逻辑

判定（仅在有新版本时）：
- **`summary.must_fix_count = 0`** → no-op → `doctor`
- **`summary.must_fix_count > 0`** → 完整迁移校准 → `doctor`

## 迁移原则

- 先清理旧插件标识（`pensieve@Pensieve`、`pensieve@pensieve-claude-plugin`），保留 `pensieve@kingkongshot-marketplace`。
- 仅迁移用户编写内容到 `.claude/skills/pensieve/`（唯一用户数据根）。
- 关键文件（review/commit pipeline + taste-review knowledge）与模板对齐；内容不一致时默认替换，因为这些文件是系统流程的一部分，用户自定义内容应在其他文件中。
- review 依赖项目内化：引用 `.claude/skills/pensieve/knowledge/taste-review/content.md`。
- 用户文件冲突时做最小合并（必要时产出 `*.migrated.md`）。
- 迁移完成后删除旧路径（包含插件级/用户级副本与独立 graph 文件），避免双源。
- 迁移完成后删除项目级子目录历史规范 README 副本（只保留插件侧规范 README）。
- 用模板做种子：初始 maxims 与 pipeline 模板来自插件。

> 数据边界（系统 vs 用户）见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

## 需要迁移的内容

用户文件（非系统文件）：
- `maxims/*.md`（非 `_` 前缀）
- `decisions/*.md`
- `knowledge/*`
- `pipelines/*.md`
- `loop/*`

> 旧版 `maxims/_linus.md` 与 `pipelines/review.md` 需合并到新命名后删除旧副本。

### 模板位置（插件内）

- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/maxims/*.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.run-when-reviewing-code.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.run-when-committing.md`
- `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

## 关键文件强对齐（内容不一致即替换）

- 覆盖对象：
  - `.claude/skills/pensieve/pipelines/run-when-reviewing-code.md`
  - `.claude/skills/pensieve/pipelines/run-when-committing.md`
  - `.claude/skills/pensieve/knowledge/taste-review/content.md`
- 处理策略：
  - 目标文件缺失：直接从模板复制。
  - 目标文件存在但内容不一致：先备份 `*.bak.<timestamp>`，再用模板替换。
  - 默认执行完整对齐——这些文件定义系统流程步骤，局部偏离会导致 pipeline 执行不一致。

### 不应迁移的内容

- 系统文件（`_` 前缀）：`pipelines/_*.md`、`maxims/_*.md`
- 历史复制目录中的系统 README / templates / scripts
- 项目级子目录中的历史规范 README 副本（`{maxims,decisions,knowledge,pipelines,loop}/{README*.md,readme*.md}`）

## 清理旧系统副本（仅项目内）

迁移后删除：
- `<project>/skills/pensieve/`
- `<project>/.claude/pensieve/`
- `<user-home>/.claude/skills/pensieve/`
- `<user-home>/.claude/pensieve/`
- `<project>/.claude/skills/pensieve/_pensieve-graph.md`
- `<project>/.claude/skills/pensieve/pensieve-graph.md`
- `<project>/.claude/skills/pensieve/graph.md`
- `<project>/.claude/skills/pensieve/{maxims,decisions,knowledge,pipelines,loop}/{README*.md,readme*.md}`
- 历史系统 `README.md` 与 `_*.md`

不确定时先备份再删除。

## 先清理旧插件命名

检查 `~/.claude/settings.json` 和 `<project>/.claude/settings.json` 的 `enabledPlugins`：
- 移除 `pensieve@Pensieve`
- 移除 `pensieve@pensieve-claude-plugin`
- 保留/添加 `pensieve@kingkongshot-marketplace: true`

## 迁移步骤

1. 版本检查前置。
2. 若已是最新：
   - 输出版本已最新
   - 询问用户是否运行 `doctor` 自检
   - 维护项目级 SKILL：`bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade skipped: version up-to-date; asked whether to run doctor"`
   - 结束 upgrade（不进入迁移）
3. 若有新版本：执行共享结构扫描（pre）并读取 `.state/pensieve-structure-scan.pre.json`。
4. 若无差异（`summary.must_fix_count = 0`）：
   - 输出 no-op
   - 维护项目级 SKILL：`bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade no-op after new version sync (structure + critical content aligned)"`
   - 运行 `doctor`
5. 若有差异（`summary.must_fix_count > 0`）：
   - 修正 `enabledPlugins`
   - 清理旧安装引用与旧目录
   - 删除项目级子目录历史规范 README 副本
     ```bash
     for d in maxims decisions knowledge pipelines loop; do
       find ".claude/skills/pensieve/$d" -maxdepth 1 -type f \( -iname 'readme*.md' -o -iname 'readme' \) -delete 2>/dev/null || true
     done
     ```
   - 迁移用户编写内容到 active 根目录
   - 对齐关键文件（缺失补齐；不一致替换）
   - 重写 review pipeline 路径引用
   - 用户文件冲突时最小合并
6. 再次执行共享结构扫描（post）：
   - `bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh --output .state/pensieve-structure-scan.post.json --fail-on-drift`
   - 若 post 扫描仍有 MUST_FIX，升级判定为未收敛，停止并返回差异清单
7. 输出迁移报告。
8. 维护项目级 SKILL：`bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade migration completed after new version sync"`
9. 运行 `doctor`。

## 插件清理与更新命令

```bash
CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope user || true
CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope user || true
CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope project || true
CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope project || true
CLAUDECODE= claude plugin marketplace update kingkongshot/Pensieve
CLAUDECODE= claude plugin update pensieve@kingkongshot-marketplace --scope user
```

## 约束

- 不删除插件内部系统文件——插件的下一次更新依赖这些文件完整存在。
- 不修改插件托管的系统内容——插件内容由版本控制管理，本地修改会在下次更新时被覆盖。
- 只允许为 Pensieve 相关 `enabledPlugins` 键修改 `settings.json`。
- 不在 upgrade 阶段输出体检级别结论——upgrade 关注"对齐"，体检关注"合规"，混合会模糊职责边界。
- 不保留独立 graph 文件——图谱统一维护在项目级 `SKILL.md#Graph`，多处维护会导致不一致。
- 不保留项目级子目录规范 README 副本——规范单一事实源在插件侧 `<SYSTEM_SKILL_ROOT>/*/README.md`。
