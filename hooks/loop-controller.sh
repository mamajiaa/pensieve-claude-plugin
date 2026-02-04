#!/bin/bash
# Pensieve Loop Controller - Stop Hook
# 检查是否有待执行的 task，自动继续循环

set -euo pipefail

# 依赖检查
command -v jq >/dev/null 2>&1 || exit 0

# 获取插件根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"

# 读取 Hook 输入
HOOK_INPUT=$(cat)

# 轻量日志（便于调试，多次触发会追加）
# log() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
# }
log() { :; }  # no-op

# 获取当前会话的 Shell PID（用于匹配 marker）
get_shell_pid() {
    local pid="$$"
    while [[ "$pid" -gt 1 ]]; do
        local comm
        comm=$(ps -o comm= -p "$pid" 2>/dev/null | sed 's/^[[:space:]]*//')
        comm=$(basename "$comm")
        if [[ "$comm" == "claude" ]]; then
            ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' '
            return 0
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        [[ -z "$pid" ]] && break
    done
    return 1
}

CURRENT_SESSION_PID="$(get_shell_pid || true)"
log "Hook triggered pid=$$ ppid=$PPID session_pid=$CURRENT_SESSION_PID"

# ============================================
# 检查是否有活跃的 Loop（通过标记文件）
# ============================================

# 查找标记文件
MARKER_FILE=""
TASK_LIST_ID=""
LOOP_DIR=""

for marker in /tmp/pensieve-loop-*; do
    [[ -f "$marker" ]] || continue

    # 解析标记文件
    local_task_id=$(jq -r '.task_list_id' "$marker" 2>/dev/null) || continue
    local_loop_dir=$(jq -r '.loop_dir' "$marker" 2>/dev/null) || continue
    local_session_pid=$(jq -r '.session_pid // empty' "$marker" 2>/dev/null) || true
    log "marker=$(basename "$marker") task_list_id=$local_task_id loop_dir=$local_loop_dir session_pid=$local_session_pid"

    # 只处理与当前会话匹配的 marker
    if [[ -n "$CURRENT_SESSION_PID" ]]; then
        [[ "$local_session_pid" == "$CURRENT_SESSION_PID" ]] || continue
    else
        # 无法识别当前会话时，仅允许旧 marker（无 session_pid）继续
        [[ -z "$local_session_pid" ]] || continue
    fi

    # 检查标记文件对应的进程是否还活着
    local_pid=$(jq -r '.pid' "$marker" 2>/dev/null) || continue
    if ! kill -0 "$local_pid" 2>/dev/null; then
        rm -f "$marker"
        log "stale marker removed: $marker pid=$local_pid"
        continue
    fi

    MARKER_FILE="$marker"
    TASK_LIST_ID="$local_task_id"
    LOOP_DIR="$local_loop_dir"
    log "marker selected: $marker"
    break
done

if [[ -z "$MARKER_FILE" ]]; then
    log "no marker matched, exit"
    exit 0
fi

# 从 _meta.md 读取信息
META_FILE="$LOOP_DIR/_meta.md"
CONTEXT_FILE="$LOOP_DIR/_context.md"

TASKS_DIR="$HOME/.claude/tasks/$TASK_LIST_ID"

if [[ ! -d "$TASKS_DIR" ]]; then
    rm -f "$MARKER_FILE"
    log "tasks dir missing, marker removed: $TASKS_DIR"
    exit 0
fi

# ============================================
# 辅助函数
# ============================================

read_goal() {
    if [[ -f "$META_FILE" ]]; then
        awk '/^## 概述/{flag=1; next} /^## /{flag=0} flag' "$META_FILE" | head -10
    else
        echo "(未设置目标)"
    fi
}

read_pipeline() {
    if [[ -f "$META_FILE" ]]; then
        sed -n '/^---$/,/^---$/p' "$META_FILE" | grep "^pipeline:" | sed 's/^pipeline: *//'
    else
        echo "unknown"
    fi
}

is_task_blocked() {
    local task_file="$1"
    local blocked_by
    blocked_by=$(jq -r '.blockedBy // [] | .[]' "$task_file" 2>/dev/null)

    [[ -z "$blocked_by" ]] && return 1

    for dep_id in $blocked_by; do
        local dep_file="$TASKS_DIR/$dep_id.json"
        if [[ -f "$dep_file" ]]; then
            local dep_status
            dep_status=$(jq -r '.status' "$dep_file" 2>/dev/null)
            [[ "$dep_status" != "completed" ]] && return 0
        fi
    done

    return 1
}

get_next_task() {
    for task_file in "$TASKS_DIR"/*.json; do
        [[ -f "$task_file" ]] || continue
        [[ "$(basename "$task_file")" == ".DS_Store" ]] && continue

        local status
        status=$(jq -r '.status' "$task_file" 2>/dev/null)

        if [[ "$status" == "pending" ]]; then
            if ! is_task_blocked "$task_file"; then
                echo "$task_file"
                return 0
            fi
        fi
    done
    return 1
}

count_tasks() {
    local total=0 completed=0 pending=0 in_progress=0

    for task_file in "$TASKS_DIR"/*.json; do
        [[ -f "$task_file" ]] || continue
        [[ "$(basename "$task_file")" == ".DS_Store" ]] && continue

        ((total++)) || true
        local status
        status=$(jq -r '.status' "$task_file" 2>/dev/null)

        case "$status" in
            completed) ((completed++)) || true ;;
            pending) ((pending++)) || true ;;
            in_progress) ((in_progress++)) || true ;;
        esac
    done

    echo "$total $completed $pending $in_progress"
}

check_all_completed() {
    local stats
    stats=$(count_tasks)
    local total completed pending in_progress
    read -r total completed pending in_progress <<< "$stats"

    if [[ "$total" -eq 0 ]]; then
        # 目录为空时，检查是否曾经开始过任务
        local tasks_started
        tasks_started=$(jq -r '.tasks_started // false' "$MARKER_FILE" 2>/dev/null)
        [[ "$tasks_started" == "true" ]]
    else
        [[ "$pending" -eq 0 && "$in_progress" -eq 0 ]]
    fi
}

mark_in_progress() {
    local task_file="$1"
    local tmp_file="${task_file}.tmp"
    jq '.status = "in_progress"' "$task_file" > "$tmp_file"
    mv "$tmp_file" "$task_file"

    # 首次执行时标记 tasks_started
    local started
    started=$(jq -r '.tasks_started // false' "$MARKER_FILE" 2>/dev/null)
    if [[ "$started" != "true" ]]; then
        jq '.tasks_started = true' "$MARKER_FILE" > "${MARKER_FILE}.tmp"
        mv "${MARKER_FILE}.tmp" "$MARKER_FILE"
    fi
}

# ============================================
# 强化信息生成
# ============================================

generate_reinforcement() {
    local task_file="$1"
    local stats
    stats=$(count_tasks)
    local total completed pending in_progress
    read -r total completed pending in_progress <<< "$stats"

    local task_id task_subject
    task_id=$(jq -r '.id' "$task_file")
    task_subject=$(jq -r '.subject' "$task_file")

    local agent_prompt="$LOOP_DIR/_agent-prompt.md"

    local context_file="$LOOP_DIR/_context.md"

    local project_root user_data_root
    project_root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
    user_data_root="$project_root/.claude/pensieve"

    cat << EOF
只调用 Task，不要自己执行：

Task(subagent_type: "general-purpose", prompt: "Read $agent_prompt and execute task_id=$task_id")

系统能力（随插件更新）：$SYSTEM_SKILL_ROOT
项目级用户数据（永不覆盖）：$user_data_root

遇到方向性偏差时：
1. 优先阅读系统能力目录下的 pipelines/maxims/knowledge 寻找答案
2. 将问题和答案记录到 $context_file 的"事后 Context"部分
3. 继续推进
EOF
}

# ============================================
# 主逻辑
# ============================================

main() {
    # 检查是否已开始执行任务，未开始则放行
    local tasks_started
    tasks_started=$(jq -r '.tasks_started // false' "$MARKER_FILE" 2>/dev/null)
    if [[ "$tasks_started" != "true" ]]; then
        exit 0
    fi

    if check_all_completed; then
        # 先读取 pid，再删除文件
        local bind_pid
        bind_pid=$(jq -r '.pid' "$MARKER_FILE" 2>/dev/null) || true
        # 删除标记文件
        rm -f "$MARKER_FILE"
        # 终止绑定进程
        if [[ -n "$bind_pid" ]] && kill -0 "$bind_pid" 2>/dev/null; then
            kill "$bind_pid" 2>/dev/null || true
        fi
        exit 0
    fi

    local next_task
    if next_task=$(get_next_task); then
        mark_in_progress "$next_task"

        local reinforcement
        reinforcement=$(generate_reinforcement "$next_task")

        local task_id task_subject
        task_id=$(jq -r '.id' "$next_task")
        task_subject=$(jq -r '.subject' "$next_task")
        local stats
        stats=$(count_tasks)
        local total completed pending in_progress
        read -r total completed pending in_progress <<< "$stats"

        jq -n \
            --arg reason "$reinforcement" \
            --arg msg "🔄 Loop [$completed/$total] | #$task_id $task_subject" \
            '{
                "decision": "block",
                "reason": $reason,
                "systemMessage": $msg
            }'
        exit 0
    fi

    exit 0
}

main
