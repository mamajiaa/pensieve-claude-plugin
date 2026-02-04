# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Pensieve（冥想盆）是 Claude Code 的知识管理系统，核心理念：**每次人工干预都是自动化机会**。

## 架构

插件和 Skill 分离安装：

```
Pensieve/                        # 仓库（插件部分）
├── .claude-plugin/
│   └── plugin.json              # 插件清单
├── hooks/                       # Hook 脚本（由插件加载）
│   ├── hooks.json
│   ├── inject-routes.sh         # SessionStart: 扫描并注入可用资源
│   └── loop-controller.sh       # Stop: 自动循环控制器
└── skills/                       # 插件内置 Skills（随插件更新）
    └── pensieve/
        ├── SKILL.md              # Skill 入口
        ├── maxims/               # 系统准则
        ├── decisions/            # 决策格式规范
        ├── pipelines/            # 流程
        ├── knowledge/            # 系统知识
        ├── loop/                 # 执行层文档与模板（运行产物在项目数据目录）
        └── scripts/              # 脚本工具

项目级用户数据（永不被插件更新覆盖）：

```
<project>/.claude/pensieve/
├── maxims/
├── decisions/
├── knowledge/
└── loop/
```

## 安装方式

1. **插件**：通过 `.claude/settings.json` 安装（URL 插件）
2. **用户数据**：初始化项目级目录 `.claude/pensieve/`（可用 `skills/pensieve/scripts/init-project-data.sh`）

## 核心脚本

| 脚本 | 用途 |
|------|------|
| `skills/pensieve/scripts/init-loop.sh <taskListId> <slug>` | 初始化 loop 目录 |
| `skills/pensieve/scripts/bind-loop.sh <taskListId> <loop_dir>` | 绑定已有 loop 目录 |
| `skills/pensieve/scripts/end-loop.sh <taskListId>` | 结束指定 loop |

## 文档解耦原则

**每个目录的 README 是唯一真相源。** 其他文件通过链接引用，不重复描述。

关键 README：
- `skills/pensieve/SKILL.md` — Pensieve 总览
- `skills/pensieve/loop/README.md` — Loop 机制详解
- `skills/pensieve/maxims/README.md` — 准则编写指南
- `skills/pensieve/decisions/README.md` — 决策编写指南

## Pensieve 触发词

| 触发词 | Pipeline | 说明 |
|--------|----------|------|
| "用 loop"、"loop 执行" | `_loop.md` | 自动循环执行多任务 |
| "review"、"审查" | `review.md` | 代码审查流程 |
| "自改进" | `_self-improve.md` | 系统自我优化 |

## Loop 模式

启动前**必须先读** `skills/pensieve/loop/README.md`，了解：
- 职责划分（主窗口 vs task-executor）
- 启动流程（Step 1-5）
- 文件格式要求
