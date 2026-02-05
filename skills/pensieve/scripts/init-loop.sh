#!/bin/bash
# Pensieve Loop 初始化工具
# 创建 loop 目录结构并关联 task_list_id
#
# 用法:
#   init-loop.sh <task_list_id> <slug>
#   init-loop.sh <task_list_id> <slug> --force   # 覆盖已存在的目录
#
# 例如:
#   init-loop.sh abc-123-uuid login-feature

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/_lib.sh"

# 插件根目录（系统能力）
PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"

# 用户数据（loop 产物）在项目级，不随插件更新覆盖
DATA_ROOT="$(ensure_user_data_root)"
LOOP_BASE_DIR="$DATA_ROOT/loop"
CLAUDE_TASKS_BASE="$HOME/.claude/tasks"

# ============================================
# 参数解析
# ============================================

if [[ $# -lt 2 ]]; then
    echo "用法: $0 <task_list_id> <slug>"
    echo ""
    echo "例如:"
    echo "  $0 abc-123-uuid login-feature"
    exit 1
fi

TASK_LIST_ID="$1"
SLUG="$2"
FORCE="${3:-}"
MARKER_FILE="/tmp/pensieve-loop-$TASK_LIST_ID"

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -Iseconds)

# ============================================
# taskListId 容错（避免误用 "default"）
# ============================================

if [[ "$TASK_LIST_ID" == "default" ]]; then
    echo "错误: taskListId 不能是 \"default\""
    echo ""
    echo "请使用真实的 taskListId："
    echo "- 优先从 TaskCreate 的返回中复制"
    echo "- 如果没有看到 taskListId，说明你可能没有调用 TaskCreate 工具（只是输出了文本）；请重新调用 TaskCreate 并展开工具输出"
    echo "- 或使用: $SYSTEM_SKILL_ROOT/scripts/find-task-list-id.sh \"初始化 loop\""
    exit 1
fi

# 验证 task 目录存在
TASKS_DIR="$CLAUDE_TASKS_BASE/$TASK_LIST_ID"
if [[ ! -d "$TASKS_DIR" ]]; then
    echo "错误: Task 目录不存在: $TASKS_DIR"
    echo ""
    echo "请确保使用真实的 taskListId："
    echo "- 优先从 TaskCreate 的返回中复制"
    echo "- 如果没有看到 taskListId，请展开工具输出（例如 ctrl+o）查看返回的 JSON"
    echo "- 或使用: $SYSTEM_SKILL_ROOT/scripts/find-task-list-id.sh \"初始化 loop\""
    exit 1
fi

# ============================================
# 创建 Loop 目录
# ============================================

LOOP_NAME="${DATE}-${SLUG}"
LOOP_DIR="$LOOP_BASE_DIR/$LOOP_NAME"

if [[ -d "$LOOP_DIR" ]]; then
    if [[ "$FORCE" != "--force" ]]; then
        echo "错误: Loop 目录已存在: $LOOP_DIR"
        echo "使用 --force 参数覆盖"
        exit 1
    fi
    echo "警告: 覆盖已存在的目录: $LOOP_DIR"
fi

mkdir -p "$LOOP_DIR"

# ============================================
# 写入 Loop marker（让 Stop hook 自动接管，无需后台常驻进程）
# ============================================

CLAUDE_PID="$(find_claude_pid || true)"
SESSION_PID="$(find_claude_session_pid || true)"

if command -v jq >/dev/null 2>&1; then
    jq -n \
        --arg task_list_id "$TASK_LIST_ID" \
        --arg loop_dir "$LOOP_DIR" \
        --arg started_at "$TIMESTAMP" \
        --arg claude_pid "$CLAUDE_PID" \
        --arg session_pid "$SESSION_PID" \
        '{
          task_list_id: $task_list_id,
          loop_dir: $loop_dir,
          started_at: $started_at,
          claude_pid: (if $claude_pid == "" then null else ($claude_pid | tonumber) end),
          session_pid: (if $session_pid == "" then null else ($session_pid | tonumber) end)
        }' > "$MARKER_FILE"
else
    cat > "$MARKER_FILE" << EOF
{
  "task_list_id": "$TASK_LIST_ID",
  "loop_dir": "$LOOP_DIR",
  "started_at": "$TIMESTAMP",
  "claude_pid": "${CLAUDE_PID:-}",
  "session_pid": "${SESSION_PID:-}"
}
EOF
fi

echo "已创建: $MARKER_FILE"

# ============================================
# 生成 _agent-prompt.md
# ============================================

cat > "$LOOP_DIR/_agent-prompt.md" << EOF
---
name: expert-developer
description: 执行单个开发任务，完成后返回
---

你是 Linus Torvalds，Linux 内核的创造者和首席架构师，你已经维护 Linux 内核超过30年，审核过数百万行代码，建立了世界上最成功的开源项目。现在我们正在开创一个新项目，以你独特的视角来分析代码，确保项目从一开始就建立在坚实的技术基础上。

## Context

读取本目录下的 `_context.md` 了解任务背景。

## 准则

系统准则（随插件更新）：
- \`$SYSTEM_SKILL_ROOT/maxims/_linus.md\`

项目级自定义准则（永不被插件覆盖）：
- \`$DATA_ROOT/maxims/custom.md\`（若不存在可忽略）

核心信条：

- 如果需要超过 3 层缩进，你就已经完蛋了
- 重写问题让特殊情况消失，不要加 if 打补丁
- 永远不破坏用户可见行为
- 暴露问题，不要掩盖它

## 当前任务

通过 `TaskGet` 读取（task_id 由调用时传入）。

## 执行流程

1. 读取 `_context.md` 了解背景
2. 读取准则文件了解约束
3. `TaskGet` 获取任务详情
4. `TaskUpdate` → in_progress
5. 执行任务
6. `TaskUpdate` → completed
7. 返回

## 完成标准

任务完成前必须验证：
- 编译通过（无编译错误）
- Lint 通过（无 lint 错误）

如果验证失败，修复后再标记 completed。

## 约束

- 只做任务描述的事，不做额外工作
- 不循环，执行完当前 task 就返回
- 不和用户交互，所有信息来自 context 和 task
EOF

echo "已创建: $LOOP_DIR/_agent-prompt.md"

# ============================================
# 输出结果
# ============================================

echo ""
echo "Loop 初始化完成"
echo "目录: $LOOP_DIR"
echo "Task: $TASKS_DIR"
echo ""
echo "TASK_LIST_ID=$TASK_LIST_ID"
echo "LOOP_DIR=$LOOP_DIR"
echo ""
echo "下一步:"
echo "1) 创建并填充 $LOOP_DIR/_context.md（建议先 Read 再 Edit/Write，或直接 Write 创建新文件）"
echo "2) 回到 Loop Pipeline，继续生成 tasks 并执行"
echo ""
echo "提示：Stop Hook 会根据 $MARKER_FILE 自动接管，无需再手动启动后台绑定进程。"
