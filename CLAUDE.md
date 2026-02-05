# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Pensieve（冥想盆）是 Claude Code 的知识管理系统，核心理念：**每次人工干预都是自动化机会**。

## 架构

插件和用户数据分离：

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
        ├── knowledge/            # 系统知识
        ├── tools/                # 内置工具（loop / pipeline / upgrade / self-improve）
        └── pipelines/            # 系统示例流程（如 review）

项目级用户数据（永不被插件更新覆盖）：

```
<project>/.claude/pensieve/
├── maxims/
├── decisions/
├── knowledge/
├── pipelines/
└── loop/
```

## 安装方式

1. **插件**：通过 marketplace 安装（固定到 `zh` 分支）
2. **用户数据**：初始化项目级目录 `.claude/pensieve/`（可用 `tools/loop/scripts/init-project-data.sh`）

## 核心脚本

| 脚本 | 用途 |
|------|------|
| `skills/pensieve/tools/loop/scripts/init-loop.sh <taskListId> <slug>` | 初始化 loop 目录 |
| `skills/pensieve/tools/loop/scripts/end-loop.sh <taskListId>` | 结束指定 loop |

## 文档解耦原则

**每个目录的 README 是唯一真相源。** 其他文件通过链接引用，不重复描述。

关键 README：
- `skills/pensieve/SKILL.md` — Pensieve 总览
- `skills/pensieve/tools/loop/README.md` — Loop 机制详解
- `skills/pensieve/maxims/README.md` — 准则编写指南
- `skills/pensieve/decisions/README.md` — 决策编写指南

## 推荐命令

| 命令 | 对应工具 | 说明 |
|------|----------|------|
| `/loop` | `tools/loop/_loop.md` | 自动循环执行多任务 |
| `/pipeline` | `tools/pipeline/_pipeline.md` | 列出项目 pipelines |
| `/upgrade` | `tools/upgrade/_upgrade.md` | 迁移用户数据 |
| `/selfimprove` | `tools/self-improve/_self-improve.md` | 系统自我优化 |

## Loop 模式

启动前**必须先读** `skills/pensieve/tools/loop/README.md`，了解：
- 职责划分（主窗口 vs task-executor）
- 启动流程（Step 1-5）
- 文件格式要求
