> [!TIP]
>
> **不想读文档？说 `loop` 就行。**
>
> Pensieve 会自动理解你的意图。不用记命令，不用读文档。

<!-- <居中展示区域> -->

<div align="center">

# Pensieve

**冥想盆 — 人类存入经验，AI 读取真相**

[![GitHub Stars](https://img.shields.io/github/stars/mamajiaa/pensieve-claude-plugin?color=ffcb47&labelColor=black&style=flat-square)](https://github.com/mamajiaa/pensieve-claude-plugin/stargazers)
[![License](https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square)](LICENSE)

[English](README.md)

</div>

<!-- </居中展示区域> -->

## 为什么叫 Pensieve？

在《哈利·波特》中，冥想盆是一个古老的石质浅盆，里面盛着银色的液态记忆。巫师可以用魔杖把记忆从脑中抽出，存入盆中。

**Pensieve** 这个词由 **pensive（沉思）** 和 **sieve（筛子）** 组合而来——它能筛选、整理思绪。

故事中，冥想盆多次成为揭示真相的关键——当事人把记忆存入盆中，观看者进入那些记忆，终于理解了当时的情境和真实动机。**没有冥想盆，真相永远无法揭示。**

---

> [!NOTE]
>
> **关于架构演进**
>
> 我们最初把 Linus Torvalds 的角色提示词放在 CLAUDE.md 里，让它始终存在于上下文中。**这是个错误。**
>
> 长提示词会让 LLM 输出变得冗长、难以预测。我们发现：**只在特定环节加载提示词，响应会更可靠。**
>
> 这和冥想盆的工作方式一样——记忆不是一直塞在脑子里，而是需要时才取出来看。
>
> 现在，Linus 的准则被拆分到 `maxims/_linus.md`，只在执行任务时加载。**按需读取，而不是全量携带。**

---

## 目录

- [它解决什么问题](#它解决什么问题)
- [安装](#安装)
- [Loop 模式](#loop-模式)
- [五类记忆](#五类记忆)
- [内置准则](#内置准则)
- [自定义](#自定义)
- [架构](#架构)
- [设计哲学](#设计哲学)
- [交流群](#交流群)

---

## 它解决什么问题

**Claude Code 执行大任务时，你必须盯着屏幕，随时准备干预。**

这很烦。

Pensieve 的 Loop 模式让你可以：
1. 描述任务，然后离开
2. Stop Hook 检测到未完成任务会自动继续
3. 每个任务在独立 subagent 中执行，主窗口不会爆上下文
4. 结束后自动对比事前假设和实际发现，有价值的偏差会被记录

**你的任务会被完成，句号。**

---

## 直接跳过阅读本文档

### 这是智能体时代

**把这份文档链接粘贴给 Claude Code，让它帮你理解和设置。**

如果你是 LLM 智能体，向用户解释这个项目现在能够实现什么。

### 推荐命令

| 命令 | 作用 |
|------|------|
| `/loop` | 复杂任务：规划 → 拆解 → 自动续跑 |
| `/pipeline` | 列出项目 pipelines（路径 + 描述） |
| `/upgrade` | 迁移用户数据到 `.claude/pensieve/` |
| `/selfimprove` | 改进 Pensieve 系统能力 |

**说人话，Pensieve 会路由到对应工具或流程。**

---

## 安装

Pensieve 现在采用**官方插件结构**：

- **插件（系统能力）**：hooks + skills，完全由插件更新维护
- **项目级用户数据**：`.claude/pensieve/`，永不被插件更新覆盖

### 快速安装

#### 1.（推荐）通过 Marketplace 安装并固定到 `zh` 分支

```bash
claude plugin marketplace add mamajiaa/pensieve-claude-plugin#zh
claude plugin install pensieve@pensieve-claude-plugin --scope user
```

如果你希望团队共享，把 scope 改为 `project`：

```bash
claude plugin install pensieve@pensieve-claude-plugin --scope project
```

#### 2. 配置 CLAUDE.md（或 AGENTS.md，二选一）

```markdown
## Pensieve
先探索项目，再决定是否使用 Pensieve 工具。
复杂任务：/pipeline → /loop；迁移数据：/upgrade。
改进 Pensieve 时必须使用 `tools/self-improve/_self-improve.md`。
```

#### 3. 初始化项目级用户数据（推荐）

```bash
mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}
```

或运行插件内置初始化脚本（不会覆盖已有文件；绝对路径会在 SessionStart 注入）：

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

#### 4. 重启 Claude Code

说 `loop` 验证安装成功。

详见 **[安装指南](docs/installation.md)**。更新请看 **[更新指南](docs/update.md)**。

### 面向 LLM 智能体

如果你是 LLM 智能体，帮用户：

1. 添加 marketplace（固定到 `zh` 分支）：
   ```bash
   claude plugin marketplace add mamajiaa/pensieve-claude-plugin#zh
   ```
2. 安装插件：
   ```bash
   claude plugin install pensieve@pensieve-claude-plugin --scope user
   ```
3. 在 `CLAUDE.md`（或 `AGENTS.md`）中添加简短路由指引 + 自改进要求
4. 初始化项目级用户数据：`.claude/pensieve/`
5. 提醒用户重启 Claude Code

---

## Loop 模式

Pensieve 的核心能力。它让 Claude Code 变成一个自律的执行者。

### 职责划分

| 角色 | 做什么 |
|------|--------|
| **主窗口** | Planning：初始化 → 填充 context → 生成 tasks → 调用 subagent |
| **Subagent** | 执行单个 task：读 context → 干活 → 返回 |
| **Stop Hook** | 自动循环：检测 pending task → 注入强化信息 → 继续执行 |

### 执行流程

```
Phase 0: 简单任务判断
         ↓ 复杂任务走 loop
Phase 1: 创建占位任务 + init-loop.sh
         ↓
Phase 2: init-loop.sh 写入 marker（Stop Hook 自动接管）
         ↓
Phase 3: 填充 _context.md（交互历史、最终共识、理解与假设）
         ↓
Phase 4: 拆分任务，用户确认
         ↓
Phase 5: Subagent 逐个执行，Stop Hook 自动循环
         ↓
Phase 6: Stop Hook 提示自改进（可选）
```

### 两套存储

| 存储 | 内容 | 为什么 |
|------|------|--------|
| `~/.claude/tasks/<uuid>/` | 任务状态（JSON） | Claude Code 原生，用于 Stop Hook 检测 |
| `.claude/pensieve/loop/{date}-{slug}/` | 元数据 + 文档 | 项目级追踪执行过程，沉淀改进 |

### 自动化程度

用"单次 Loop 完成的任务数"衡量：

| 任务数 | 级别 |
|--------|------|
| < 10 | 低自动化（初期正常） |
| 10-50 | 中等自动化 |
| 100+ | 完全自动化（终极目标） |

**目标不是一步到位，是渐进提升。**

初期自动化程度很低，但通过每次 Loop 的 self-improve，能代替你回答的问题会越来越多。

---

## 内置准则

我们预存了 4 条准则，来自 Linux 内核的创造者 Linus Torvalds。

这些是我们认为最值得传承的"品德记忆"。从上到下代表优先级——遇到冲突时，优先遵守排在前面的。

### 1. "好品味" — 消除边界情况

> "有时你可以从不同角度看问题，重写它让特殊情况消失，变成正常情况。"

**经典案例**：链表删除操作，10 行带 if 判断优化为 4 行无条件分支。

- 消除边界情况永远优于增加条件判断
- 充分相信上游数据，缺失数据应在上游提供而不是打补丁
- 好品味是一种直觉，需要经验积累

### 2. "Never break userspace" — 用户可见行为不变

> "我们不破坏用户可见行为！"

- 任何会意外导致用户可见行为改变的代码都是 bug，无论多么"理论正确"
- 内核的职责是服务用户，而不是教育用户
- 需求以外的用户可见行为不变是神圣不可侵犯的

### 3. 实用主义 — 解决实际问题

> "我是个该死的实用主义者。"

**经典案例**：删除 10 行 fallback 逻辑直接抛出错误，让上游数据问题在测试中暴露而不是被掩盖。

- 解决实际问题，而不是假想的威胁
- 主动直接地暴露问题
- 拒绝微内核等"理论完美"但实际复杂的方案
- 代码要为现实服务，不是为论文服务

### 4. 简洁执念 — 3 层缩进就完蛋

> "如果你需要超过 3 层缩进，你就已经完蛋了，应该修复你的程序。"

**经典案例**：290 行巨型函数拆分为 4 个单一职责函数，主函数变为 10 行组装逻辑。

- 函数必须短小精悍，只做一件事并做好
- 不要写兼容、回退、临时、备用、特定模式生效的代码
- 代码即文档，命名服务于阅读
- 复杂性是万恶之源
- 默认不写注释，除非需要解释"为什么"

---

## 五类记忆

Pensieve 把记忆分成五类。**不同的记忆有不同的生命周期和读取时机。**

| 类型 | 是什么 | 什么时候读取 |
|------|--------|--------------|
| **Maxims** | 你的品德，跨项目的普遍原则 | 执行任务时，作为判断依据 |
| **Decisions** | 你的历史选择，"为什么当时这样做" | 遇到类似情境时，避免重复踩坑 |
| **Pipelines** | 你的工作流程，可执行的闭环 | 用户触发对应流程时 |
| **Knowledge** | 外部参考资料 | Pipeline 需要引用时 |
| **Loop** | 当前任务的上下文 | 执行期间 |

### 什么值得存入冥想盆？

**Maxim**（准则）：必须全部满足——换项目还适用？换语言还适用？换领域还适用？能指导未来未知问题？

**Decision**（决策）：三个黄金问题任一为"是"——删掉会犯错？三个月后能做更好选择？能作为模式教给别人？

**Pipeline**（流程）：重复出现的任务结构。先能跑通，再精细化。

### 记忆的演化

```
Loop 中的临时决策 → 经筛选 → Decision
多次相似 Decision → 提炼 → Maxim
外部知识 + 项目实践 → Decision
Decision 指导 → Pipeline 改进
```

**就像斯内普的记忆揭示了真相，你存入的记忆会帮助 Claude 理解你的意图。**

---

## 自定义

用 `/selfimprove` 触发自改进工具，它会引导你把经验沉淀到**项目级用户数据**中（插件更新不会覆盖）。

| 类型 | 位置 | 命名 |
|------|------|------|
| Decision | `.claude/pensieve/decisions/` | `{date}-{结论}.md` |
| Maxim | `.claude/pensieve/maxims/custom.md` | 编辑此文件 |
| Knowledge | `.claude/pensieve/knowledge/{name}/` | `content.md` |
| Pipeline | `.claude/pensieve/pipelines/` | `{name}.md` |

**注意**：系统提示词（tools/scripts/系统 knowledge）都在插件内，完全随插件更新维护。

---

## 架构

Pensieve 采用官方插件结构：

- **插件（系统能力）**：hooks + skills（随插件更新）
- **项目级用户数据**：`.claude/pensieve/`（永不覆盖）

```
pensieve/
├── .claude-plugin/
│   └── plugin.json          # 插件清单
├── hooks/                    # 自动触发器
│   ├── hooks.json           # Hook 配置
│   ├── inject-routes.sh     # SessionStart: 扫描可用资源，注入到上下文
│   └── loop-controller.sh   # Stop: 检测 pending task，自动继续
└── skills/
    └── pensieve/             # 系统 Skill（随插件更新）
        ├── SKILL.md
        ├── tools/
        │   ├── loop/
        │   ├── pipeline/
        │   ├── upgrade/
        │   └── self-improve/
        ├── maxims/
        ├── decisions/
        ├── knowledge/
        └── pipelines/         # 系统示例流程（如 review）

<project>/
└── .claude/
    └── pensieve/             # 项目级用户数据（永不覆盖）
        ├── maxims/
        ├── decisions/
        ├── knowledge/
        ├── pipelines/
        └── loop/
```

### Hook 系统

| Hook | 触发时机 | 作用 |
|------|----------|------|
| `inject-routes.sh` | SessionStart | 注入系统路径 + 项目级用户数据概览到上下文 |
| `loop-controller.sh` | Stop | 检查是否有 pending task，有则注入强化信息继续执行 |

**Stop Hook 是 Loop 模式的心脏——它让自动循环成为可能。**

如果智能体没有完成开始的工作，系统会强制它继续。你的任务会被完成，句号。

---

## 设计哲学

### 按需加载，而不是全量携带

长提示词会让 LLM 输出变得不可预测。Pensieve 的核心思想是：**只在特定环节加载需要的知识。**

- Maxims 只在执行任务时加载
- Knowledge 只在 Pipeline 需要时加载
- 历史 Decision 只在遇到类似情境时被引用

这就是为什么 Linus 的角色提示词被拆分到 Skill 里，而不是放在 CLAUDE.md。

### 文档解耦

**每个目录的 README 是唯一真相源。**

- 修改某个模块 → 只改该目录的 README
- 其他文件需要引用 → 写链接，不复制内容

重复的文档会腐烂。

### 闭环验证

**验证必须基于实际反馈，不是从代码推演。**

| 验证类型 | 实际反馈来源 |
|----------|--------------|
| 编译/构建 | 编译器输出、构建日志 |
| 测试 | 测试运行结果 |
| 运行时 | 应用日志、错误堆栈 |

系统不会骗你，模型推演会。

### 渐进演化

**先可达成（baseline），再精细化。**

1. Baseline：能跑通，有基本验证
2. 工具化：识别重复/易错环节，制作工具
3. 编排优化：调整顺序减少回退

反模式：一开始就追求完美，没跑过就优化。

---

## 交流群

<img src="./QRCode.png" alt="微信交流群二维码" width="200">

---

## License

MIT
