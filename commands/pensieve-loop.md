---
description: 初始化 Pensieve Loop（系统提示词在插件内更新，项目数据永不被覆盖）
argument-hint: [slug]
allowed-tools: ["Task", "Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

# Pensieve Loop

目标：在当前项目启用 Pensieve Loop 流程。

## 规则（非常重要）

- 只用 **TaskCreate** 工具拿到真实 `taskListId`（不要用 `Bash(claude ...)` 猜 ID）
- `init-loop.sh` 必须前台运行，拿到脚本输出的 `LOOP_DIR`
- 从 `0.3.2` 起：Stop Hook 通过 `/tmp/pensieve-loop-<taskListId>` 自动接管，**无需**运行 `bind-loop.sh`

## 步骤

1) 初始化项目级用户数据目录（只补齐缺失项，不覆盖已有内容）：

!`${CLAUDE_PLUGIN_ROOT}/skills/pensieve/scripts/init-project-data.sh`

2) 创建占位 task（只为拿到 taskListId）：

TaskCreate subject="初始化 loop" description="1. 初始化 loop 目录 2. 为任务构建上下文 3. 生成并执行任务"

3) 用脚本获取 taskListId（更符合 AI 直觉，避免猜 ID）：

```bash
${CLAUDE_PLUGIN_ROOT}/skills/pensieve/scripts/find-task-list-id.sh "初始化 loop"
```

4) 用输出的 UUID 初始化 loop（不要带尖括号）：

```bash
${CLAUDE_PLUGIN_ROOT}/skills/pensieve/scripts/init-loop.sh <taskListId> $1
```

5) 在 `LOOP_DIR` 下创建并填充 `_context.md`，确认无误后再继续生成 tasks 并执行（参考 `skills/pensieve/pipelines/_loop.md`）。
