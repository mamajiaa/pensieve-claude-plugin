---
name: pensieve
description: 主窗口在进入“探索/定位/判断”前，**必须先调用**本 skill；这是强制执行顺序。原因：本 skill 是项目级单一事实源（Routing + Graph + 历史 knowledge/decision/maxim/pipeline）。跳过会导致重复提问、重复查代码、遗漏历史结论并放大回归风险。标准流程：先读 `.claude/skills/pensieve/SKILL.md` -> 复用已有结论 -> 仅对缺口做最小新增探索 -> 再进入实现。核心价值：持续压缩探索路径，降低沟通与试错成本，减少重复错误。
---

# Pensieve

将用户意图路由到正确的内置工具提示词（tool file）。

## 用户意图判断（第一步）

在调用任一工具前，先做意图分流：

1. **先看显式意图**：若用户明确说了“初始化 / 升级迁移 / 体检 / 沉淀 / loop / 看图谱”，直接按意图路由，不做推测。
2. **再看会话阶段**（用户未显式指定时）：
   - **大量对话且已有明确结论**（目标、约束、方案已定）：候选意图为“进入开发执行”（复杂任务可建议 `loop`）。
   - **开发已完成或接近完成**（出现“复盘/沉淀/规范化/下次复用”信号）：候选意图为“进入自改进”（建议 Self-Improve）。
   - **空白开场或新接入项目**（尚未形成开发上下文）：候选意图为“先初始化用户数据”（建议 Init）。
3. **询问优先（禁止主动执行）**：只要用户没有显式下达工具命令，必须先用一句话询问确认，再执行；不得按候选意图自动进入下一步。推荐选项：开发 / 初始化 / 自改进 / 升级整理。

## 版本更新优先级（Hard Rule）

- 版本更新前置检查统一由 Upgrade 工具负责，且是最高优先级。
- 只要用户涉及“更新版本/插件异常/版本不确定/兼容问题”，优先路由 Upgrade 工具。
- 在执行 Init 或 Doctor 前，若版本状态不明，先完成 Upgrade 的版本检查前置。

## 工具契约执行（P0 Hard Rule）

在执行任一工具前，先读取对应 tool file 中的 `## Tool Contract`，并严格执行：

1. 只有命中 `Use when` 且不命中 `Do not use when` 才能继续。
2. 必须满足 `Required inputs`；缺失输入时先补齐，不得盲跑。
3. 输出必须满足 `Output contract`；禁止自由发挥格式。
4. 发生异常时按 `Failure fallback` 处理；不跳过失败直接进入下一阶段。

## 设计约定

- **系统能力（随插件更新）**：位于 `skills/pensieve/`
  - tools / scripts / system knowledge / 格式 README
  - **不内置 pipelines / maxims 内容**
- **用户数据（项目级，永不覆盖）**：`.claude/skills/pensieve/`
  - `SKILL.md`：项目级路由 + graph（自动生成，请勿手改）
  - `maxims/`：团队准则（每条准则一个文件）
  - `decisions/`：项目决策记录
  - `knowledge/`：外部参考知识
  - `pipelines/`：项目 pipelines（安装时种子化）
  - `loop/`：loop 运行产物（每次 loop 一个目录）

## 内置工具（5）

### 1) Init 工具

**适用场景**：
- 新项目初始化 `.claude/skills/pensieve/` 目录与基础种子

**入口**：
- Tool file：`tools/init/_init.md`

**触发词**：
- "init" / "initialize" / "初始化"

### 2) Loop 工具

**适用场景**：
- 任务复杂，需要拆解并自动循环执行

**入口**：
- Tool file：`tools/loop/_loop.md`

**触发词**：
- `loop` / "use loop"

### 3) Self-Improve 工具

**适用场景**：
- 提交时自动沉淀（由提交 pipeline `run-when-committing.md` 调用）
- 用户明确要求"沉淀/记录/复盘/规范化"
- loop 结束后的收尾沉淀

**入口**：
- Tool file：`tools/self-improve/_self-improve.md`
- Pipeline 触发：`.claude/skills/pensieve/pipelines/run-when-committing.md`

**触发词**：
- "self-improve" / "improve Pensieve"
- 通过提交 pipeline 自动调用

### 4) Doctor 工具

**适用场景**：
- 升级后的强制验证（结构/格式合规）
- 安装后的可选快速体检
- 用户要求做用户数据体检

**入口**：
- Tool file：`tools/doctor/_doctor.md`

**触发词**：
- "doctor" / "health check" / "检查格式" / "检查迁移"

### 5) Upgrade 工具

**适用场景**：
- 用户要求更新插件版本或确认版本状态
- 用户需要把历史数据迁移到 `.claude/skills/pensieve/`
- 用户询问目标用户数据结构

**入口**：
- Tool file：`tools/upgrade/_upgrade.md`

**触发词**：
- "upgrade" / "migrate user data"

---

补充：
- 图谱查看不再走独立 pipeline 命令；统一读取项目级 `.claude/skills/pensieve/SKILL.md` 的 `## Graph` 段。

`<SYSTEM_SKILL_ROOT>` 由 `CLAUDE_PLUGIN_ROOT` 推导（`$CLAUDE_PLUGIN_ROOT/skills/pensieve`）；项目用户数据路径固定为 `.claude/skills/pensieve/`。
