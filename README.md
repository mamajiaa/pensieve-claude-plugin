> [!TIP]
>
> 不想读文档？安装好后，直接对 Claude 说：`用 loop 完成开发`

<div align="center">

# Pensieve

**让每次干预都成为自动化的机会。**

[![GitHub Stars](https://img.shields.io/github/stars/kingkongshot/Pensieve?color=ffcb47&labelColor=black&style=flat-square)](https://github.com/kingkongshot/Pensieve/stargazers)
[![License](https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square)](LICENSE)

[English README](https://github.com/mamajiaa/pensieve-claude-plugin/blob/main/README.md)

</div>

## 如果你正在查找 linus 引导词

你熟悉的那套方法还在，并且已经升级成可执行系统：

- Linus 风格准则已成为默认行动规则
- 关键能力挂在 Claude Code 执行链（skills / hooks / task / agent）
- 审查能力以 `review` pipeline + knowledge 形式落地

你拿到的是工程能力级封装：提示词、流程和执行机制一起交付。

## 为什么需要 linus 提示词？

- **更强破局能力**：顽固 bug 优先走根因修复，不走补丁堆叠
- **更高代码品味**：输出更简洁、可维护、可验证
- **更硬的代码审查**：`review` pipeline 执行 linus 一致的标准
- **更稳的长会话表现**：按需加载减少上下文噪音，提示词不在塞爆上下文
- **更少人工盯流程**：`/loop` 自动拆解并续跑任务，让每一次对话都改进 pipeline

## 30 秒开始

1. 安装插件
2. 初始化 `.claude/pensieve/`
3. 重启 Claude Code
4. 输入 `loop`

快速入口（推荐自动化）：

把本 README 链接或全文贴给大模型，并直接下达指令：

`按 README 完成 Pensieve 安装与初始化；完成后汇报执行结果。`

大模型会按步骤自动完成安装、初始化与校验。

- [安装指南](docs/installation.md)
- [更新指南](docs/update.md)
- [升级工具](skills/pensieve/tools/upgrade/_upgrade.md)
- [卸载说明](docs/installation.md#卸载)

## 为什么这套方式更稳

### 1. 默认准则驱动执行

系统默认强调：根因修复、简化分支、控制复杂度、拒绝低质量实现。

### 2. 按需加载上下文

不同阶段加载不同内容：执行时读 maxims，审查时读审查 pipeline/knowledge，迁移时读 upgrade。

### 3. 绑定 Claude Code 原生能力

- **Skills**：路由意图到工具
- **Hooks**：SessionStart 注入路由，Stop 负责自动续跑
- **Task**：任务状态驱动流程节奏
- **Agent**：主窗口拆解，子代理执行

这样设计有两个直接收益：

- **更轻量**：复用 Claude Code 原生执行链，减少额外封装和维护负担
- **升级红利**：Claude Code 原生能力升级时，Pensieve 可同步获得改进

## 只需要学会几个简单的命令

- `/loop`：复杂任务拆解 + 自动循环执行，直接说“使用 loop 完成“
- `/doctor`：按 README 规范做用户数据体检，输出固定格式报告
- `/pipeline`：查看并调用项目 pipelines
- `/selfimprove`：沉淀经验并改进系统行为（不负责迁移体检）
- `/upgrade`：迁移历史用户数据到当前标准（迁移后用 `/doctor` 复检）

## 适合什么场景

- 顽固 bug 长时间修不动
- 高标准 code review
- 复杂项目的长周期迭代
- 团队想把个人经验固化为默认流程

## 社区

<img src="./QRCode.png" alt="微信交流群二维码" width="200">

## 许可证

MIT
