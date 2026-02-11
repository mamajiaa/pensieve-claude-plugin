description: 使用 Loop 工具（自动循环执行任务）
argument-hint: [slug]
allowed-tools: ["Task", "Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

使用 Loop 工具（完整流程见工具文件）：

@${CLAUDE_PLUGIN_ROOT}/skills/pensieve/tools/loop/_loop.md

如果用户提供 `$1`，将其作为 `slug` 传给 `init-loop.sh`。
