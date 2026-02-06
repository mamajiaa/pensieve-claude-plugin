> [!TIP]
>
> **不想读文档？说 `loop` 就行。**
>
> Pensieve 会自动理解你的意图。不用记命令，不用读文档。

<!-- <居中展示区域> -->

<div align="center">

# Pensieve

**存下你的决策与准则，让 Claude 做出更好的选择。**

[![GitHub Stars](https://img.shields.io/github/stars/kingkongshot/Pensieve?color=ffcb47&labelColor=black&style=flat-square)](https://github.com/kingkongshot/Pensieve/stargazers)
[![License](https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square)](LICENSE)

[English](https://github.com/kingkongshot/Pensieve/blob/main/README.md)

</div>

<!-- </居中展示区域> -->

## 目录

- [Pensieve](#pensieve)
- [直接跳过这份 README](#直接跳过这份-readme)
- [这是智能体时代](#这是智能体时代)
- [魔法词：`loop`](#魔法词loop)
- [想读的人：Pensieve 是什么](#想读的人pensieve-是什么)
- [直接安装即可](#直接安装即可)
- [安装](#安装)
- [面向用户](#面向用户)
- [面向 LLM 智能体](#面向-llm-智能体)
- [卸载](#卸载)
- [特性](#特性)
- [Loop 模式](#loop-模式)
- [记忆系统](#记忆系统)
- [配置](#配置)
- [项目结构](#项目结构)
- [设计哲学](#设计哲学)
- [为什么叫 “Pensieve”？](#为什么叫-pensieve)
- [社区](#社区)
- [License](#license)

---

## 直接跳过这份 README

### 这是智能体时代

**把这份文档链接粘贴给 Claude Code，让它帮你理解和设置。**

如果你是 LLM 智能体，向用户解释这个项目现在能做什么。

### 魔法词：`loop`

不想读这份文档？在提示里包含 `loop` 就行。

Pensieve 会自动规划、拆解、执行并持续续跑直到完成。智能体会处理其余细节。

### 想读的人：Pensieve 是什么

Pensieve 是一个 Claude Code 插件，把经验变成可复用的优势：

- **Decisions** 被保存下来，避免重复踩坑
- **Maxims** 记录你希望 Claude 遵循的长期原则
- **Loop 模式** 保证大任务不需要你一直盯着

### 直接安装即可

如果你只做一件事，那就安装插件并初始化项目记忆：

1. 安装插件
2. 在 `CLAUDE.md` 加一条路由说明
3. 创建 `.claude/pensieve/`
4. 重启 Claude Code

如果你是智能体，可以帮用户一次性完成这些步骤。

---

## 安装

Pensieve 采用 Claude Code 插件结构：

- **插件（系统能力）**：hooks + skills，随插件更新
- **项目级用户数据**：`.claude/pensieve/`，插件不覆盖

### 面向用户

#### 1.（推荐）通过 Marketplace 安装并固定到 `zh` 分支

```bash
claude plugin marketplace add kingkongshot/Pensieve#zh
claude plugin install pensieve@kingkongshot-marketplace --scope user
```

如果你希望团队共享，把 scope 改为 `project`：

```bash
claude plugin install pensieve@kingkongshot-marketplace --scope project
```

#### 2. 配置 `CLAUDE.md`

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

或运行插件内置初始化脚本（写入初始准则与 pipeline，不覆盖已有文件；绝对路径会在 SessionStart 注入）：

```bash
<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh
```

#### 4. 重启 Claude Code

说 `loop` 验证安装成功。

详见 **[安装指南](docs/installation.md)**、**[更新指南](docs/update.md)** 与 **[卸载](docs/installation.md#卸载)**。

### 面向 LLM 智能体

如果你是 LLM 智能体，帮用户：

1. 添加 marketplace（固定到 `zh` 分支）
2. 安装插件
3. 在 `CLAUDE.md` 中添加简短路由指引 + 自改进要求
4. 初始化 `.claude/pensieve/`
5. 提醒用户重启 Claude Code
6. 告诉用户只需掌握几个基础命令：`/loop`、`/selfimprove`、`/pipeline`、`/upgrade`

---

## 卸载

要移除 Pensieve：

1. 卸载插件：`claude plugin uninstall pensieve@kingkongshot-marketplace --scope user`（若为项目级安装则用 `--scope project`）
2.（可选）删除项目记忆：`rm -rf .claude/pensieve`
3. 重启 Claude Code

---

## 特性

Pensieve 小而清晰，但很实用。它通过记忆与纪律让 Claude Code 更可靠。

### Loop 模式

Pensieve 的核心能力。让 Claude Code 变成一个自律的执行者。

#### 职责划分

| 角色 | 做什么 |
|------|--------|
| **主窗口** | Planning：初始化 → 填充 context → 生成 tasks → 调用 subagent |
| **Subagent** | 执行单个 task：读 context → 干活 → 返回 |
| **Stop Hook** | 自动循环：检测 pending task → 注入强化信息 → 继续执行 |

#### 执行流程

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

#### 两套存储

| 存储 | 内容 | 为什么 |
|------|------|--------|
| `~/.claude/tasks/<uuid>/` | 任务状态（JSON） | Claude Code 原生，用于 Stop Hook 检测 |
| `.claude/pensieve/loop/{date}-{slug}/` | 元数据 + 文档 | 项目级追踪执行过程，沉淀改进 |

#### 自动化程度

用“单次 Loop 完成的任务数”衡量：

| 任务数 | 级别 |
|--------|------|
| < 10 | 低自动化（初期正常） |
| 10-50 | 中等自动化 |
| 100+ | 完全自动化（终极目标） |

**目标不是一步到位，而是渐进提升。**

### 记忆系统

Pensieve 把记忆分成五类。**不同记忆有不同的生命周期和读取时机。**

| 类型 | 是什么 | 什么时候读取 |
|------|--------|--------------|
| **Maxims** | 你的品德，跨项目的普遍原则 | 执行任务时，作为判断依据 |
| **Decisions** | 你的历史选择，"为什么当时这样做" | 遇到类似情境时，避免重复踩坑 |
| **Pipelines** | 你的工作流程，可执行的闭环 | 用户触发对应流程时 |
| **Knowledge** | 外部参考资料 | Pipeline 需要引用时 |
| **Loop** | 当前任务的上下文 | 执行期间 |

#### 什么值得存入冥想盆？

**Maxim（准则）**：必须全部满足——换项目还适用？换语言还适用？换领域还适用？能指导未来未知问题？

**Decision（决策）**：三个黄金问题任一为“是”——删掉会犯错？三个月后能做更好选择？能作为模式教给别人？

**Pipeline（流程）**：重复出现的任务结构。先能跑通，再精细化。

#### 记忆的演化

```
临时决策在 Loop 中 → 筛选 → Decision
多次相似 Decision → 提炼 → Maxim
外部知识 + 项目实践 → Decision
Decision 指导 → Pipeline 改进
```

**就像记忆揭示真相，你存入的记忆会帮助 Claude 理解你的意图。**

---

## 配置

用 `/selfimprove` 触发自改进工具，它会引导你把经验沉淀到**项目级用户数据**中（插件更新不会覆盖）。

| 类型 | 位置 | 命名 |
|------|------|------|
| Decision | `.claude/pensieve/decisions/` | `{date}-{结论}.md` |
| Maxim | `.claude/pensieve/maxims/custom.md` | 编辑此文件 |
| Knowledge | `.claude/pensieve/knowledge/{name}/` | `content.md` |
| Pipeline | `.claude/pensieve/pipelines/` | `{name}.md` |

**注意**：系统提示词（tools/scripts/系统 knowledge）都在插件内，完全随插件更新维护。

---

## 项目结构

Pensieve 是一个官方 Claude Code 插件：

- **插件（系统能力）**：hooks + skills，位于插件目录
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
        └── pipelines/         # 仅格式文档（不内置 pipeline）

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

---

## 设计哲学

> [!NOTE]
>
> **关于架构演进**
>
> 我们最初把长提示词放在 CLAUDE.md 里，让它始终存在于上下文中。**这是个错误。**
>
> 长提示词会让 LLM 输出变得冗长、难以预测。我们发现：**只在特定环节加载提示词，响应会更可靠。**
>
> 这和冥想盆的工作方式一样——记忆不是一直塞在脑子里，而是需要时才取出来看。
>
> 现在，准则与 pipeline 仅在**项目级用户数据**中维护，并在需要时加载。**按需读取，而不是全量携带。**

### 按需加载，而不是全量携带

长提示词会让 LLM 输出变得不可预测。Pensieve 的核心思想是：**只在特定环节加载需要的知识。**

- Maxims 只在执行任务时加载
- Knowledge 只在 Pipeline 需要时加载
- 历史 Decision 只在遇到类似情境时被引用

这就是为什么角色提示词被拆分到工具/技能里，而不是放在 CLAUDE.md。

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

## 为什么叫 “Pensieve”？

在《哈利·波特》中，冥想盆是一个古老的石质浅盆，里面盛着银色的液态记忆。巫师可以用魔杖把记忆从脑中抽出，存入盆中。

**Pensieve** 这个词由 **pensive（沉思）** 和 **sieve（筛子）** 组合而来——它能筛选、整理思绪。

故事中，冥想盆多次成为揭示真相的关键——当事人把记忆存入盆中，观看者进入那些记忆，终于理解了当时的情境和真实动机。**没有冥想盆，真相永远无法揭示。**

---

## 社区

<img src="./QRCode.png" alt="微信交流群二维码" width="200">

---

## License

MIT
