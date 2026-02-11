# 升级工具

---
description: 引导将用户数据升级到项目级 `.claude/pensieve/` 结构
---

你是 Upgrade 工具。你的职责是解释目标目录结构，并指导把旧布局迁移到新布局。你不决定用户内容，只定义路径与规则。

Hard rule：先清理旧插件命名，再迁移用户数据。不要长期并行保留新旧命名。
Hard rule：升级/迁移后必须执行一次 doctor 复检。
Hard rule：不要把“升级前先 doctor”当作门槛；默认流程是 upgrade-first。

## 目标结构（项目级，永不被插件覆盖）

```
<project>/.claude/pensieve/
  maxims/      # 用户/团队准则（如 custom.md）
  decisions/   # 决策记录（ADR）
  knowledge/   # 用户参考资料
  pipelines/   # 项目级 pipelines
  loop/        # loop 产物（每次 loop 一个目录）
```

## 迁移原则

- 先清理旧插件标识：迁移前删除旧安装引用和 `settings.json` 里的旧 key。
- 待清理旧引用：
  - `pensieve@Pensieve`
  - `pensieve@pensieve-claude-plugin`
- 新的唯一引用：
  - `pensieve@kingkongshot-marketplace`
- 系统能力保留在插件内：`<SYSTEM_SKILL_ROOT>/` 下内容由插件管理，不迁移不覆盖。
- 历史系统副本应清理：迁移完成后删除项目中的旧系统拷贝（不要触碰插件内部）。
- 用户数据必须项目级：仅迁移用户编写内容到 `.claude/pensieve/`。
- 不覆盖用户数据：目标文件存在时，采用合并或后缀策略。
- 尽量保留结构：保留子目录层级与文件名。
- 用模板做种子：初始 maxims 与 pipeline 模板来自插件模板。
- 若版本分叉：先读双方内容，再按目录 README 规则进行合并。

## 常见旧位置

用户数据可能存在于：

- 项目内 `skills/pensieve/` 或其子目录
- 用户自建 `maxims/`、`decisions/`、`knowledge/`、`pipelines/`、`loop/`

### 需要迁移的内容

- 用户文件（非系统文件）：
  - `maxims/custom.md` 或其他非 `_` 前缀文件
  - `decisions/*.md`
  - `knowledge/*`
  - `pipelines/*.md`
  - `loop/*`

> 旧版本可能在插件/项目副本里包含 `maxims/_linus.md` 与 `pipelines/review.md`。若仍在使用，请将内容合并到：
> - `.claude/pensieve/maxims/custom.md`
> - `.claude/pensieve/pipelines/review.md`
> 然后删除旧副本，避免混淆。

### 模板位置（插件内）

- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/maxims.initial.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/maxims/*.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.review.md`

### 不应迁移的内容

- 系统文件（通常 `_` 前缀）：
  - `pipelines/_*.md`
  - `maxims/_*.md`
  - 插件管理的系统 knowledge
  - 历史复制目录中的系统 README / templates / scripts

## 清理旧系统副本（仅项目内）

迁移后，删除项目中的旧系统副本：

- `<project>/skills/pensieve/`
- `<project>/.claude/skills/pensieve/`
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

## 迁移步骤（建议由 LLM 执行）

1. 扫描并检查：
   - `~/.claude/settings.json`
   - `<project>/.claude/settings.json`
2. 清理旧 `enabledPlugins` 键，仅保留/添加新键。
3. 清理旧安装引用：
   - 卸载 `pensieve@Pensieve`（若存在）
   - 卸载 `pensieve@pensieve-claude-plugin`（若存在）
4. 按规则扫描旧位置中的用户内容。
5. 创建目标目录：
   - `mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}`
6. 合并 maxims：
   - 若 `.claude/pensieve/maxims/custom.md` 不存在，从模板复制
   - 若 `.claude/pensieve/maxims/{maxim}.md` 不存在，从 `templates/maxims/*.md` 种子化
   - 若双方都存在，加迁移标记后合并
7. 迁移预置 pipeline（必须比较内容）：
   - 若 `.claude/pensieve/pipelines/review.md` 不存在，从模板复制
   - 若存在，比较内容：
     - 相同：跳过
     - 不同：创建 `review.migrated.md` 并记录合并说明
8. 迁移用户文件到目标目录，尽量保持相对结构。
9. 文件名冲突先比较内容：
   - 相同：跳过
   - 不同：追加迁移标记或创建 `*.migrated.md`
10. 清理上面列出的旧系统副本。
11. 输出迁移报告（旧路径 -> 新路径）。
12. 升级后强制复检：
   - 运行一次 `/doctor`
   - 若 doctor 报告迁移/结构问题，继续修复直到 `PASS` 或 `PASS_WITH_WARNINGS`
   - 通过后再按需运行 `/selfimprove`（可选）

## 可选可视化

迁移后可生成项目级用户数据链接图：

```bash
bash <SYSTEM_SKILL_ROOT>/tools/upgrade/scripts/generate-user-data-graph.sh
```

## 插件清理与更新命令（按顺序）

```bash
# 清理旧安装引用（未安装时忽略错误）
claude plugin uninstall pensieve@Pensieve --scope user || true
claude plugin uninstall pensieve@pensieve-claude-plugin --scope user || true

# 若存在项目级安装，也清理
claude plugin uninstall pensieve@Pensieve --scope project || true
claude plugin uninstall pensieve@pensieve-claude-plugin --scope project || true

# 刷新 marketplace 并更新新插件引用
claude plugin marketplace update kingkongshot/Pensieve
claude plugin update pensieve@kingkongshot-marketplace --scope user
```

## 约束

- 不要删除插件内部系统文件。
- 不要修改插件托管的系统内容。
- 只允许为 Pensieve 相关 `enabledPlugins` 键修改 `settings.json`。
