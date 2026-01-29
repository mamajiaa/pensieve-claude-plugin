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
└── skill/                       # Skill 内容（用户手动复制）
    ├── SKILL.md                 # Skill 入口
    ├── maxims/                  # 准则
    ├── decisions/               # 决策
    ├── pipelines/               # 流程
    ├── knowledge/               # 知识
    ├── loop/                    # 执行层
    └── scripts/                 # 脚本工具

用户项目/.claude/skills/pensieve/  # Skill 安装位置
├── SKILL.md
├── maxims/
├── decisions/
├── pipelines/
├── knowledge/
├── loop/
└── scripts/
```

## 安装方式

1. **插件**：克隆到 `.claude/plugins/pensieve`，配置 settings.json
2. **Skill**：复制 `skill/` 目录到 `.claude/skills/pensieve/`

## 核心脚本

| 脚本 | 用途 |
|------|------|
| `scripts/init-loop.sh <taskListId> <slug>` | 初始化 loop 目录 |
| `scripts/bind-loop.sh <taskListId>` | 绑定已有 loop 目录 |
| `scripts/end-loop.sh` | 结束当前 loop |

## 文档解耦原则

**每个目录的 README 是唯一真相源。** 其他文件通过链接引用，不重复描述。

关键 README：
- `skill/SKILL.md` — Pensieve 总览
- `skill/loop/README.md` — Loop 机制详解
- `skill/maxims/README.md` — 准则编写指南
- `skill/decisions/README.md` — 决策编写指南

## Pensieve 触发词

| 触发词 | Pipeline | 说明 |
|--------|----------|------|
| "用 loop"、"loop 执行" | `_loop.md` | 自动循环执行多任务 |
| "review"、"审查" | `review.md` | 代码审查流程 |
| "自改进" | `_self-improve.md` | 系统自我优化 |

## Loop 模式

启动前**必须先读** `skill/loop/README.md`，了解：
- 职责划分（主窗口 vs task-executor）
- 启动流程（Step 1-5）
- 文件格式要求
