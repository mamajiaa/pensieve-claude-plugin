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

# 获取文件修改时间（秒），兼容 macOS / Linux
get_mtime() {
    local file="$1"
    if stat -f %m "$file" >/dev/null 2>&1; then
        stat -f %m "$file"
    elif stat -c %Y "$file" >/dev/null 2>&1; then
        stat -c %Y "$file"
    else
        echo 0
    fi
}

# 获取当前 Claude 进程 PID（用于绑定 marker）
get_claude_pid() {
    local pid="$$"
    while [[ "$pid" -gt 1 ]]; do
        local comm
        comm=$(ps -o comm= -p "$pid" 2>/dev/null | sed 's/^[[:space:]]*//')
        comm=$(basename "$comm")
        if [[ "$comm" == "claude" ]]; then
            echo "$pid"
            return 0
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        [[ -z "$pid" ]] && break
    done
    return 1
}

# 获取当前会话的 Shell PID（用于兼容 / 调试）
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
CURRENT_CLAUDE_PID="$(get_claude_pid || true)"
log "Hook triggered pid=$$ ppid=$PPID claude_pid=$CURRENT_CLAUDE_PID session_pid=$CURRENT_SESSION_PID"

# ============================================
# 检查是否有活跃的 Loop（通过标记文件）
# ============================================

# 扫描并处理所有 marker（同一会话）
MARKERS=()

for marker in /tmp/pensieve-loop-*; do
    [[ -f "$marker" ]] || continue

    local_claude_pid=$(jq -r '.claude_pid // empty' "$marker" 2>/dev/null) || true
    [[ -n "$local_claude_pid" ]] || continue
    [[ -n "$CURRENT_CLAUDE_PID" ]] || continue

    # 只处理当前会话的 marker
    [[ "$local_claude_pid" == "$CURRENT_CLAUDE_PID" ]] || continue

    # 容错：若 claude_pid 已不存活，清理 marker
    if ! kill -0 "$local_claude_pid" 2>/dev/null; then
        rm -f "$marker"
        log "stale marker removed: $marker claude_pid=$local_claude_pid"
        continue
    fi

    MARKERS+=("$marker")
done

if [[ "${#MARKERS[@]}" -eq 0 ]]; then
    log "no marker matched, exit"
    exit 0
fi

# 以 mtime 升序遍历（更早的 loop 优先）
sort_markers_by_mtime() {
    for m in "$@"; do
        printf "%s %s\n" "$(get_mtime "$m")" "$m"
    done | sort -n | awk '{print $2}'
}

# 初始化全局变量（每个 marker 会覆盖）
MARKER_FILE=""
TASK_LIST_ID=""
LOOP_DIR=""
META_FILE=""
CONTEXT_FILE=""
TASKS_DIR=""

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

# 忽略 Phase 1 的占位 task（只用于拿 taskListId，避免被 loop 执行）
is_ignored_task() {
    local task_file="$1"
    local id subject
    id=$(jq -r '.id // ""' "$task_file" 2>/dev/null)
    subject=$(jq -r '.subject // ""' "$task_file" 2>/dev/null)
    [[ "$id" == "1" && "$subject" == "初始化 loop" ]]
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
        is_ignored_task "$task_file" && continue

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
        is_ignored_task "$task_file" && continue

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

    # total==0: 仍处于 setup（仅有占位 task）→ 不结束
    [[ "$total" -gt 0 && "$pending" -eq 0 && "$in_progress" -eq 0 ]]
}

mark_in_progress() {
    local task_file="$1"
    local tmp_file="${task_file}.tmp"
    jq '.status = "in_progress"' "$task_file" > "$tmp_file"
    mv "$tmp_file" "$task_file"
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
    local marker
    for marker in $(sort_markers_by_mtime "${MARKERS[@]}"); do
        local local_task_id local_loop_dir
        local_task_id=$(jq -r '.task_list_id' "$marker" 2>/dev/null) || continue
        local_loop_dir=$(jq -r '.loop_dir' "$marker" 2>/dev/null) || continue

        MARKER_FILE="$marker"
        TASK_LIST_ID="$local_task_id"
        LOOP_DIR="$local_loop_dir"
        META_FILE="$LOOP_DIR/_meta.md"
        CONTEXT_FILE="$LOOP_DIR/_context.md"
        TASKS_DIR="$HOME/.claude/tasks/$TASK_LIST_ID"

        if [[ ! -d "$TASKS_DIR" ]]; then
            rm -f "$MARKER_FILE"
            log "tasks dir missing, marker removed: $TASKS_DIR"
            continue
        fi

        if check_all_completed; then
            rm -f "$MARKER_FILE"
            continue
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
    done

    exit 0
}

main
