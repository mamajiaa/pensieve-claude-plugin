---
description: 版本检查与迁移校准：同步最新版本，有新版本时执行结构对齐与旧路径清理；已是最新则询问是否运行 doctor。
---

# 升级工具

> 工具边界见 `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | 共享规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` | 目录约定见 `<SYSTEM_SKILL_ROOT>/references/directory-layout.md`

先同步最新版本并确认版本状态。若已是最新，停止 upgrade 并询问用户是否运行 `doctor`；仅在确认有新版本时才进入迁移校准。

## Tool Contract

### Use when

- 用户要求更新插件版本、确认版本状态或迁移历史数据到 `.claude/skills/pensieve/`
- 用户存在旧路径/插件级副本/独立 graph 文件/历史规范 README 副本，需清理统一

### Failure fallback

- 无法确认更新状态：停在"确认更新 + 重启"，不进入迁移
- 无法拉取最新版本定义：参考 GitHub 最新文档并给重试建议，不进入迁移
- 用户文件冲突无法自动合并：生成 `*.migrated.md` 并记录人工合并点

## Upgrade 特有规则

- 先清理旧插件命名，再迁移用户数据
- 先从 GitHub/Marketplace 拉取最新版本结构定义，再做本地结构判定
- 目录历史与最新目标结构以 `migrations/README.md` 为准（单一事实源）
- 版本检查是唯一硬门禁：未确认有新版本前不进入迁移；无新版本只询问是否运行 `doctor`
- 更新命令失败时，先查阅 [GitHub docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md) 再继续

> 全局 upgrade-first 规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

---

## Phase 1: 版本检查（唯一硬门禁）

**Goal**: 确认是否有新版本，决定是否进入迁移。

**Actions**:
1. 按 `<PLUGIN_ROOT>/docs/update.md` 执行插件更新命令
2. 更新失败则查阅 [GitHub docs/update.md](https://github.com/kingkongshot/Pensieve/blob/main/docs/update.md) 并重试
3. 有新版本并完成更新：先重启 Claude Code，再进入 Phase 2
4. 已是最新：输出"当前已是最新版本"，询问用户是否运行 `doctor`，维护项目级 SKILL 后结束：`bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade skipped: version up-to-date; asked whether to run doctor"`
5. 无法确认版本状态：先询问用户，未确认前不进入迁移

## Phase 2: 结构扫描与判定

**Goal**: 扫描当前结构，判定是否需要迁移。

**Actions**:
1. 执行共享结构扫描：
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh --output .state/pensieve-structure-scan.pre.json
   ```
2. 读取 `summary.must_fix_count`、`flags.*`、`findings[]`
3. `must_fix_count = 0` → no-op，维护项目级 SKILL 后运行 `doctor`：`bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade no-op after new version sync (structure + critical content aligned)"`
4. `must_fix_count > 0` → 进入 Phase 3

## Phase 3: 迁移校准

**Goal**: 清理旧插件、迁移用户数据、对齐关键文件。

### 3a. 清理旧插件命名

1. 修正 `enabledPlugins`（两级 settings：`~/.claude/settings.json` 和 `<project>/.claude/settings.json`）：
   - 移除 `pensieve@Pensieve`、`pensieve@pensieve-claude-plugin`
   - 保留/添加 `pensieve@kingkongshot-marketplace: true`
2. 执行插件清理命令：
   ```bash
   CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope user || true
   CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope user || true
   CLAUDECODE= claude plugin uninstall pensieve@Pensieve --scope project || true
   CLAUDECODE= claude plugin uninstall pensieve@pensieve-claude-plugin --scope project || true
   CLAUDECODE= claude plugin marketplace update kingkongshot/Pensieve
   CLAUDECODE= claude plugin update pensieve@kingkongshot-marketplace --scope user
   ```

### 3b. 清理旧目录与副本

1. 删除旧安装目录：
   - `<project>/skills/pensieve/`
   - `<project>/.claude/pensieve/`
   - `<user-home>/.claude/skills/pensieve/`
   - `<user-home>/.claude/pensieve/`
2. 删除独立 graph 文件：`_pensieve-graph*.md`、`pensieve-graph*.md`、`graph*.md`
3. 删除项目级子目录历史规范 README 副本：
   ```bash
   for d in maxims decisions knowledge pipelines loop; do
     find ".claude/skills/pensieve/$d" -maxdepth 1 -type f \( -iname 'readme*.md' -o -iname 'readme' \) -delete 2>/dev/null || true
   done
   ```
4. 不确定时先备份再删除

### 3c. 迁移用户编写内容

目标路径：`.claude/skills/pensieve/`（唯一用户数据根）

1. 迁移用户文件：`maxims/*.md`（非 `_` 前缀）、`decisions/*.md`、`knowledge/*`、`pipelines/*.md`、`loop/*`
2. 不迁移系统文件（`_` 前缀）、历史复制目录中的系统 README/templates/scripts
3. 旧版 `maxims/_linus.md` 与 `pipelines/review.md` 合并到新命名后删除旧副本
4. 冲突时做最小合并（必要时产出 `*.migrated.md`）
5. 用模板做种子：初始 maxims 与 pipeline 模板来自插件

### 3d. 对齐关键文件

覆盖对象：
- `.claude/skills/pensieve/pipelines/run-when-reviewing-code.md`
- `.claude/skills/pensieve/pipelines/run-when-committing.md`
- `.claude/skills/pensieve/knowledge/taste-review/content.md`

模板来源：`<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/` 与 `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

处理策略：
- 目标文件缺失：直接从模板复制
- 目标文件存在但内容不一致：先备份 `*.bak.<timestamp>`，再用模板替换
- 重写 review pipeline 路径引用，指向 `.claude/skills/pensieve/knowledge/taste-review/content.md`

## Phase 4: 验证与报告

**Goal**: 确认迁移收敛，输出报告并运行 doctor。

**Actions**:
1. 执行 post 扫描：
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/scan-structure.sh --output .state/pensieve-structure-scan.post.json --fail-on-drift
   ```
2. 若 post 扫描仍有 MUST_FIX，判定为未收敛，停止并返回差异清单
3. 输出迁移报告（旧路径 → 新路径、已替换关键文件、已清理旧路径）
4. 维护项目级 SKILL：`bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event upgrade --note "upgrade migration completed after new version sync"`
5. 输出项目级 `SKILL.md` 更新结果与 Claude auto memory `~/.claude/projects/<project>/memory/MEMORY.md`（Pensieve 引导块）更新结果
6. 运行 `doctor`

## 约束

- 不删除插件内部系统文件
- 不修改插件托管的系统内容
- 只允许为 Pensieve 相关 `enabledPlugins` 键修改 `settings.json`
- 不在 upgrade 阶段输出检查级别结论（`PASS/FAIL`、`MUST_FIX/SHOULD_FIX`）
- 不保留独立 graph 文件（图谱统一维护在项目级 `SKILL.md#Graph`）
- 不保留项目级子目录规范 README 副本（规范单一事实源在插件侧 `<SYSTEM_SKILL_ROOT>/*/README.md`）

> 数据边界（系统 vs 用户）见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`
