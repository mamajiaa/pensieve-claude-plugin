---
description: Use Loop tool (auto‑loop task execution)
argument-hint: [slug]
allowed-tools: ["Task", "Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

Use the Loop tool (full process in tool file):

@${CLAUDE_PLUGIN_ROOT}/skills/pensieve/tools/loop/_loop.md

If the user provides `$1`, pass it as `slug` to `init-loop.sh`.
