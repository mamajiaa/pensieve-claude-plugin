# 升级工具

---
description: 先拉取最新版本结构定义，再按需执行用户数据迁移（无差异则 no-op）
---

你是 Upgrade 工具。你的职责是先同步最新版本，再基于最新目录结构做“是否需要迁移”的判定。只有存在结构差异时才执行迁移；否则输出 no-op 并交给 `/doctor` 判定本地数据是否还需调整。

## Tool Contract

### Use when

- 用户要求更新插件版本或确认版本状态
- 用户要求把历史数据迁移到 `.claude/skills/pensieve/`
- 用户存在旧路径并行，需要统一到单一事实源
- 用户需要清理旧插件命名并切换到新引用

### Do not use when

- 新项目首次接入，只需要创建 `.claude/skills/pensieve/`（应转 `/init`）
- 用户只想查看合规状态与问题分级（应转 `/doctor`）
- 用户只想沉淀经验或新增流程（应转 `self-improve`）
- 用户只想查看图谱与可用 pipelines（应直接读取项目级 `SKILL.md` 的 `## Graph`）

### Required inputs

- 最新版本来源（优先 GitHub / Marketplace，同步后落到本地插件）
- 版本状态（是否已按 `<PLUGIN_ROOT>/docs/update.md` 完成更新 + 重启）
- 用户数据结构迁移规范：`<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md`（结构历史与最新状态单一事实源）
- 两级 settings 路径：
  - `~/.claude/settings.json`
  - `<project>/.claude/settings.json`
- 本地现状结构（旧路径与 `.claude/skills/pensieve/` 当前目录）
- 项目级 SKILL 维护脚本：`<SYSTEM_SKILL_ROOT>/tools/memory/scripts/maintain-auto-memory.sh`

### Output contract

- 必须输出“结构对比结论”（是否存在结构差异）
- 若有差异：输出迁移报告（旧路径 -> 新路径，含冲突处理）
- 若无差异：明确输出 no-op（无需迁移）
- 无论是否迁移，都必须补齐缺失的项目 pipeline 种子（`run-when-*.md`，只补缺不覆盖）
- 不输出 `PASS/FAIL`、`MUST_FIX/SHOULD_FIX`
- 无论是否迁移，都必须给出下一步 `/doctor`
- 必须输出项目级 `SKILL.md` 更新结果（固定路由 + graph）

### Failure fallback

- 更新状态无法确认：先停在“确认更新 + 重启”，不进入迁移
- 无法拉取最新版本定义：先参考 GitHub 最新文档并给重试建议，不进入迁移
- 文件冲突无法自动合并：生成 `*.migrated.md` 并记录人工合并点

### Negative examples

- “先跑 doctor，再决定要不要 upgrade” -> 与 upgrade-first 规则冲突
- “迁移时顺便给我判定 PASS/FAIL” -> 越界到 doctor

Hard rule：先清理旧插件命名，再迁移用户数据。不要长期并行保留新旧命名。
Hard rule：版本更新前置检查由 Upgrade 统一负责，且是最高优先级门槛。
Hard rule：先从 GitHub/Marketplace 拉取最新版本结构定义，再做本地结构判定。
Hard rule：目录历史与最新目标结构以 `<SYSTEM_SKILL_ROOT>/tools/doctor/migrations/README.md` 为准；若与其他文档冲突，以该文件为准。
Hard rule：若“无新版本 + 本地结构无差异”，直接 no-op；不要进入逐文件迁移。
Hard rule：升级/迁移后必须执行一次 doctor 复检。
Hard rule：不要把“升级前先 doctor”当作门槛；默认流程是 upgrade-first。
Hard rule：进入迁移前先检查插件内文档 `<PLUGIN_ROOT>/docs/update.md`；若插件有新版本（或无法确认），先更新插件并重启 Claude Code。
Hard rule：如果更新命令失败，必须先查阅 GitHub 最新更新文档（[docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md)）再继续；失败状态下不得直接进入迁移。

## 职责边界（与 Doctor 分工）

- Upgrade 先负责**版本更新与最新结构定义同步**，再按需执行迁移动作。
- Upgrade 只处理结构级动作（创建/复制/改名/清理/最小合并），不做逐文件语义审查。
- Upgrade 不负责输出 `PASS/FAIL`、`MUST_FIX/SHOULD_FIX` 结论。
- 合规判定与“还要怎么改本地数据结构”统一由 `/doctor` 负责；Upgrade 只产出“做了什么”的升级/迁移报告。

## 版本检查前置（先于迁移）

在执行任何迁移动作前，先同步“最新版本结构定义”：

1. 先按 `<PLUGIN_ROOT>/docs/update.md` 执行插件更新命令（本质是从 GitHub/Marketplace 拉取最新版本）。
2. 若本地文档不可用或更新失败，查阅 GitHub 最新更新文档（[docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md)）并重试。
3. 如果已执行更新命令：
   - 有新版本并完成更新：必须先重启 Claude Code，再继续 `/upgrade`。
   - 已是最新版本（无变更）：可直接继续 `/upgrade`。
4. 若当前环境无法确认版本状态，先询问用户是否已完成“更新 + 重启”；未确认前不进入结构判定与迁移。

## 目标结构（项目级，永不被插件覆盖）

```
<project>/.claude/skills/pensieve/
  maxims/      # 用户/团队准则（每条准则一个文件）
  decisions/   # 决策记录（ADR）
  knowledge/   # 用户参考资料
  pipelines/   # 项目级 pipelines
  loop/        # loop 产物（每次 loop 一个目录）
```

## 结构差异判定门禁（先判定再迁移）

先做结构级对比，不做逐文件深读：

1. 是否存在旧路径并行（如 `skills/pensieve/`、`.claude/pensieve/`）。
2. `.claude/skills/pensieve/` 是否缺失关键目录或关键命名（如 `run-when-*.md`）。
3. `enabledPlugins` 是否存在旧键并行或缺失新键。
4. review pipeline 是否仍引用插件内 Knowledge 路径（`<SYSTEM_SKILL_ROOT>/knowledge/...`）。

判定规则：
- **无结构差异**：直接输出 no-op（无需迁移），然后进入 `/doctor`。
- **有结构差异**：执行最小迁移动作，再进入 `/doctor`。

## 迁移原则

- 先清理旧插件标识：迁移前删除旧安装引用和 `settings.json` 里的旧 key。
- 待清理旧引用：
  - `pensieve@Pensieve`
  - `pensieve@pensieve-claude-plugin`
- 新的唯一引用：
  - `pensieve@kingkongshot-marketplace`
- 系统能力保留在插件内：`<SYSTEM_SKILL_ROOT>/` 下内容由插件管理，不迁移不覆盖。
- 历史系统副本应清理：迁移完成后删除项目中的旧系统拷贝（不要触碰插件内部）。
- 用户数据必须项目级：仅迁移用户编写内容到 `.claude/skills/pensieve/`。
- 无差异不迁移：若结构门禁判定通过，直接 no-op，不做逐文件思考。
- 缺失 pipeline 必补齐：将模板中的 `pipeline.run-when-*.md` 补齐到项目 `pipelines/`（仅补不存在文件，不覆盖用户修改）。
- review 依赖项目内化：`.claude/skills/pensieve/pipelines/run-when-reviewing-code.md` 应引用 `.claude/skills/pensieve/knowledge/taste-review/content.md`，不依赖插件路径。
- 不覆盖用户数据：目标文件存在时，采用合并或后缀策略。
- 尽量保留结构：保留子目录层级与文件名。
- 用模板做种子：初始 maxims 与 pipeline 模板来自插件模板。
- 若版本分叉：先读双方内容，再按目录 README 规则进行合并。

## 常见旧位置

用户数据可能存在于：

- 项目内 `skills/pensieve/` 或其子目录
- 项目内 `.claude/pensieve/`（历史目录）
- 用户自建 `maxims/`、`decisions/`、`knowledge/`、`pipelines/`、`loop/`

### 需要迁移的内容

- 用户文件（非系统文件）：
  - `maxims/*.md`（非 `_` 前缀文件）
  - `decisions/*.md`
  - `knowledge/*`
  - `pipelines/*.md`
  - `loop/*`

> 旧版本可能在插件/项目副本里包含 `maxims/_linus.md` 与 `pipelines/review.md`。若仍在使用，请将内容合并到：
> - `.claude/skills/pensieve/maxims/{your-maxim}.md`
> - `.claude/skills/pensieve/pipelines/run-when-reviewing-code.md`
> 然后删除旧副本，避免混淆。

### 模板位置（插件内）

- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/maxims/*.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.run-when-reviewing-code.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.run-when-committing.md`
- `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`（作为项目知识种子源）

### 不应迁移的内容

- 系统文件（通常 `_` 前缀）：
  - `pipelines/_*.md`
  - `maxims/_*.md`
  - 历史复制目录中的系统 README / templates / scripts

## 清理旧系统副本（仅项目内）

迁移后，删除项目中的旧系统副本：

- `<project>/skills/pensieve/`
- `<project>/.claude/pensieve/`
- 历史系统 `README.md` 与 `_*.md` 提示词文件

如果不确定某文件是否系统副本，先备份再删除。

## 先清理旧插件命名（必须先做）

迁移前检查：

- 用户级：`~/.claude/settings.json`
- 项目级：`<project>/.claude/settings.json`

在 `enabledPlugins` 中：

- 移除 `pensieve@Pensieve`
- 移除 `pensieve@pensieve-claude-plugin`
- 保留/添加 `pensieve@kingkongshot-marketplace: true`

如果存在多个 key，不要保留兼容键，只保留新键。

## 迁移步骤（建议由 LLM 执行，偏执行）

1. 执行“版本检查前置（先于迁移）”，确保已同步到最新版本结构定义。
2. 做“结构差异判定门禁”（旧路径并行 / 目录缺失 / 命名不一致 / 插件键不一致）。
3. 若无结构差异：
   - 先补齐缺失的 pipeline 种子（不覆盖已有文件）：
     ```bash
     for t in <SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.run-when-*.md; do
       name="$(basename "$t" | sed 's/^pipeline\.//')"
       target=".claude/skills/pensieve/pipelines/$name"
       [ -f "$target" ] || cp "$t" "$target"
     done
     ```
   - 输出 no-op：`无需迁移`
   - 运行项目级 SKILL 维护：`bash <SYSTEM_SKILL_ROOT>/tools/memory/scripts/maintain-auto-memory.sh --event upgrade --note \"upgrade no-op\"`
   - 直接运行 `/doctor`，由 doctor 判定是否还需本地数据结构调整
   - 结束 upgrade
4. 若有结构差异，才进入迁移：
   - 修正 `enabledPlugins`（移除旧键，保留新键）
   - 清理旧安装引用（若存在）
   - 执行最小结构迁移（目录创建、命名改造、旧副本清理）
   - 若缺失 `.claude/skills/pensieve/knowledge/taste-review/content.md`，从插件知识种子化一份
   - 补齐缺失的 pipeline 种子（`run-when-*.md`，不覆盖已有文件）
   - 将 review pipeline 中的 `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md` 重写为 `.claude/skills/pensieve/knowledge/taste-review/content.md`
   - 仅在冲突时做最小合并（必要时产出 `*.migrated.md`）
5. 输出迁移报告（结构差异 -> 执行动作 -> 结果）。
6. 运行项目级 SKILL 维护：
   - `bash <SYSTEM_SKILL_ROOT>/tools/memory/scripts/maintain-auto-memory.sh --event upgrade --note \"upgrade migration completed\"`
7. 迁移后强制运行 `/doctor`：
   - 由 doctor 给出 `PASS/FAIL` 与“还要怎么改本地结构”的具体清单
   - upgrade 不在此阶段做额外逐文件语义修复

## 可选可视化

迁移后可生成项目级用户数据链接图：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/upgrade/scripts/generate-user-data-graph.sh
```

## 插件清理与更新命令（按顺序）

在 Claude Code 会话里由模型代执行 `claude` 命令时，请在命令前加 `CLAUDECODE=`（清空嵌套会话检测变量）。

```bash
# 清理旧安装引用（未安装时忽略错误）
CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope user || true
CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope user || true

# 若存在项目级安装，也清理
CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope project || true
CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope project || true

# 刷新 marketplace 并更新新插件引用
CLAUDECODE= claude plugin marketplace update kingkongshot/Pensieve
CLAUDECODE= claude plugin update pensieve@kingkongshot-marketplace --scope user
```

## 约束

- 不要删除插件内部系统文件。
- 不要修改插件托管的系统内容。
- 只允许为 Pensieve 相关 `enabledPlugins` 键修改 `settings.json`。
- 不要在 upgrade 阶段输出体检级别结论（`MUST_FIX/SHOULD_FIX`）。
