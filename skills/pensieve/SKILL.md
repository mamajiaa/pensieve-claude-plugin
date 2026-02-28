---
name: pensieve
description: 主窗口在进入“探索/定位/判断”前必须先调用本 skill。它是项目级唯一路由与历史事实源（knowledge/decision/maxim/pipeline）；跳过会导致重复提问、重复查代码、遗漏历史结论并放大回归风险。凡命中 init/upgrade/doctor/self-improve/loop/graph 或复杂任务需要先复用历史，一律先经由本 skill 分流到对应 tool file。
---

# Pensieve

把用户请求路由到正确的内置工具提示词（tool file），避免重复探索和错误分流。

## 1) 意图判断（先路由，后执行）

1. 先看显式意图：用户明确说“初始化 / 升级 / 体检 / 沉淀 / loop / 图谱”，直接路由，不猜测。
2. 再看会话阶段（用户未显式指定时）：
   - 新项目或空白上下文 -> 候选 `init`
   - 版本/兼容/迁移不确定 -> 候选 `upgrade`
   - 开发完成、需要复盘沉淀 -> 候选 `self-improve`
   - 任务复杂且需要拆解并持续推进 -> 候选 `loop`
3. 未显式下达工具命令时，先一句话确认再执行；禁止按候选意图直接开跑。

## 2) 全局硬规则

1. `upgrade` 优先级最高：凡是“版本不确定 / 兼容异常 / 迁移问题”，先走 `upgrade`。
2. 执行任一工具前，必须先读该工具 `## Tool Contract` 并逐条满足。
3. 不得跳过 `Required inputs`，不得改写 `Output contract`。
4. 工具失败时必须按 `Failure fallback` 处理，不得静默继续。

## 3) 路由表（单一事实源）

| 意图 | 入口 | 典型触发词 |
|---|---|---|
| Init | `tools/init/_init.md` | `init`, `initialize`, `初始化` |
| Upgrade | `tools/upgrade/_upgrade.md` | `upgrade`, `migrate`, `迁移`, `版本` |
| Doctor | `tools/doctor/_doctor.md` | `doctor`, `health check`, `体检`, `检查格式` |
| Self-Improve | `tools/self-improve/_self-improve.md` | `self-improve`, `沉淀`, `复盘`, `规范化` |
| Loop | `tools/loop/_loop.md` | `loop`, `loop mode`, `循环执行` |
| Graph View | 项目级 `.claude/skills/pensieve/SKILL.md` 的 `## Graph` 段 | `graph`, `图谱`, `关系图` |

## 4) 统一执行协议

对任意已路由工具，执行顺序固定：

1. 读取 tool file 的 `Use when / Do not use when`。
2. 补齐 `Required inputs`（缺一项都先补输入，不执行）。
3. 按步骤执行，并严格输出 `Output contract` 要求内容。
4. 失败则按 `Failure fallback` 返回阻塞点与下一步，不跨阶段硬推进。

## 5) 数据边界（避免污染）

- 系统能力（随插件更新）：`skills/pensieve/`
- 项目用户数据（永不覆盖）：`.claude/skills/pensieve/`
- 项目级 `SKILL.md`（路由+图谱）为自动生成文件：只读使用，不手工改写。

## 6) 项目级目录约定

- `maxims/`：团队强约束（每条一文件）
- `decisions/`：项目决策记录
- `knowledge/`：外部参考知识
- `pipelines/`：项目流程（安装时种子化）
- `loop/`：loop 运行产物（每次 loop 一个目录）

## 7) 路由失败回退

1. 意图不明确：先返回候选路由（init/upgrade/doctor/self-improve/loop）并要求用户确认，不自动执行。
2. 工具入口缺失或不可读：停止执行并报告缺失路径，不切换到“相近工具”替代执行。
3. 命中工具但 `Required inputs` 不满足：先补输入，再执行；禁止盲跑。

`<SYSTEM_SKILL_ROOT>` 由 `CLAUDE_PLUGIN_ROOT` 推导（`$CLAUDE_PLUGIN_ROOT/skills/pensieve`）；项目用户数据路径固定为 `.claude/skills/pensieve/`。
