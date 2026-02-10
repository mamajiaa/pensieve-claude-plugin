#!/bin/bash
# Pensieve Loop Controller - Stop Hook
# Check pending tasks and auto-continue the loop

set -euo pipefail

# Dependency check
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python || true)}"
[[ -n "$PYTHON_BIN" ]] || exit 0

to_posix_path() {
    local raw_path="$1"
    [[ -n "$raw_path" ]] || {
        echo ""
        return 0
    }

    if [[ "$raw_path" =~ ^[A-Za-z]:[\\/].* ]]; then
        if command -v cygpath >/dev/null 2>&1; then
            cygpath -u "$raw_path"
            return 0
        fi

        local drive rest drive_lower
        drive="${raw_path:0:1}"
        rest="${raw_path:2}"
        rest="${rest//\\//}"
        drive_lower="$(printf '%s' "$drive" | tr 'A-Z' 'a-z')"
        echo "/$drive_lower$rest"
        return 0
    fi

    echo "$raw_path"
}

# Resolve plugin root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT_RAW="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PLUGIN_ROOT="$(to_posix_path "$PLUGIN_ROOT_RAW")"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"

# Read hook input
HOOK_INPUT=$(cat)

# Lightweight logging (for debugging; appends across runs)
# log() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
# }
log() { :; }  # no-op

json_get_value() {
    local file="$1"
    local key="$2"
    local default_value="${3:-}"

    "$PYTHON_BIN" - "$file" "$key" "$default_value" <<'PY'
import json
import sys

file_path, key, default_value = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    print(default_value)
    sys.exit(0)

if not isinstance(data, dict):
    print(default_value)
    sys.exit(0)

value = data.get(key)
if value is None:
    print(default_value)
elif isinstance(value, bool):
    print("true" if value else "false")
elif isinstance(value, (int, float)):
    print(value)
elif isinstance(value, str):
    print(value)
else:
    print(default_value)
PY
}

json_get_array_lines() {
    local file="$1"
    local key="$2"

    "$PYTHON_BIN" - "$file" "$key" <<'PY'
import json
import sys

file_path, key = sys.argv[1], sys.argv[2]
try:
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

if not isinstance(data, dict):
    sys.exit(0)

value = data.get(key, [])
if isinstance(value, list):
    for item in value:
        if item is None:
            continue
        if isinstance(item, bool):
            print("true" if item else "false")
        else:
            print(item)
PY
}

json_update_marker_tasks_planned_file() {
    local source_file="$1"
    local target_file="$2"
    local now="$3"
    local total="$4"
    local pending="$5"
    local in_progress="$6"

    "$PYTHON_BIN" - "$source_file" "$target_file" "$now" "$total" "$pending" "$in_progress" <<'PY'
import json
import sys

source_file, target_file, now, total, pending, in_progress = sys.argv[1:7]

with open(source_file, "r", encoding="utf-8") as f:
    data = json.load(f)

if not isinstance(data, dict):
    raise ValueError("marker must be an object")

data["tasks_planned"] = True
data["last_seen_at"] = now
data["last_seen_total"] = int(total)
data["last_seen_pending"] = int(pending)
data["last_seen_in_progress"] = int(in_progress)

with open(target_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
}

json_mark_task_in_progress_file() {
    local source_file="$1"
    local target_file="$2"

    "$PYTHON_BIN" - "$source_file" "$target_file" <<'PY'
import json
import sys

source_file, target_file = sys.argv[1:3]

with open(source_file, "r", encoding="utf-8") as f:
    data = json.load(f)

if not isinstance(data, dict):
    raise ValueError("task must be an object")

data["status"] = "in_progress"

with open(target_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
}

json_promote_pending_marker_file() {
    local source_file="$1"
    local target_file="$2"
    local task_list_id="$3"
    local auto_bound_at="$4"

    "$PYTHON_BIN" - "$source_file" "$target_file" "$task_list_id" "$auto_bound_at" <<'PY'
import json
import sys

source_file, target_file, task_list_id, auto_bound_at = sys.argv[1:5]

with open(source_file, "r", encoding="utf-8") as f:
    data = json.load(f)

if not isinstance(data, dict):
    raise ValueError("marker must be an object")

data["task_list_id"] = task_list_id
data["auto_bound_at"] = auto_bound_at
if "tasks_planned" not in data:
    data["tasks_planned"] = False

with open(target_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
}

find_auto_bind_task_list_id() {
    local marker_file="$1"
    local tasks_base="$2"

    "$PYTHON_BIN" - "$marker_file" "$tasks_base" <<'PY'
from __future__ import annotations

import glob
import json
import os
import sys
from datetime import datetime

marker_file, tasks_base = sys.argv[1], sys.argv[2]

try:
    with open(marker_file, "r", encoding="utf-8") as f:
        marker = json.load(f)
except Exception:
    print("")
    raise SystemExit(0)

if not isinstance(marker, dict):
    print("")
    raise SystemExit(0)

started_at = str(marker.get("started_at", "") or "").strip()

def parse_iso_timestamp(value: str) -> float:
    if not value:
        return 0.0
    normalized = value
    if normalized.endswith("Z"):
        normalized = normalized[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(normalized).timestamp()
    except Exception:
        return 0.0

started_epoch = parse_iso_timestamp(started_at)

candidates: list[tuple[float, str]] = []
for task_dir in glob.glob(os.path.join(tasks_base, "*")):
    if not os.path.isdir(task_dir):
        continue

    task_list_id = os.path.basename(task_dir)
    # Skip already-bound task lists.
    if os.path.exists(f"/tmp/pensieve-loop-{task_list_id}"):
        continue

    latest_mtime = 0.0
    has_active = False

    for path in glob.glob(os.path.join(task_dir, "*.json")):
        try:
            stat = os.stat(path)
            if stat.st_mtime > latest_mtime:
                latest_mtime = stat.st_mtime
        except Exception:
            pass

        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue

        if isinstance(data, dict) and data.get("status") in ("pending", "in_progress"):
            has_active = True

    if not has_active:
        continue
    if latest_mtime < started_epoch:
        continue

    candidates.append((latest_mtime, task_list_id))

if not candidates:
    print("")
else:
    # Pick the most recently updated active task list after this loop started.
    candidates.sort()
    print(candidates[-1][1])
PY
}

try_auto_bind_pending_marker() {
    local marker_file="$1"
    local task_list_id
    task_list_id=$(json_get_value "$marker_file" "task_list_id" "") || return 1
    [[ -z "$task_list_id" ]] || return 1

    local tasks_base="$HOME/.claude/tasks"
    [[ -d "$tasks_base" ]] || return 1

    local candidate_task_list_id
    candidate_task_list_id=$(find_auto_bind_task_list_id "$marker_file" "$tasks_base")
    [[ -n "$candidate_task_list_id" ]] || return 1

    local new_marker="/tmp/pensieve-loop-$candidate_task_list_id"
    if [[ -f "$new_marker" ]]; then
        rm -f "$marker_file"
        echo "$new_marker"
        return 0
    fi

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    json_promote_pending_marker_file "$marker_file" "$new_marker" "$candidate_task_list_id" "$now"
    rm -f "$marker_file"
    echo "$new_marker"
}

emit_block_response() {
    local reason="$1"
    local message="$2"
    local additional_context="${3-}"
    local has_additional="0"

    if [[ $# -ge 3 ]]; then
        has_additional="1"
    fi

    PENSIEVE_REASON="$reason" \
    PENSIEVE_MESSAGE="$message" \
    PENSIEVE_ADDITIONAL="$additional_context" \
    PENSIEVE_HAS_ADDITIONAL="$has_additional" \
    "$PYTHON_BIN" - <<'PY'
import json
import os

payload = {
    "decision": "block",
    "reason": os.environ.get("PENSIEVE_REASON", ""),
    "systemMessage": os.environ.get("PENSIEVE_MESSAGE", ""),
}

if os.environ.get("PENSIEVE_HAS_ADDITIONAL") == "1":
    payload["additionalContext"] = os.environ.get("PENSIEVE_ADDITIONAL", "")

print(json.dumps(payload, ensure_ascii=False))
PY
}

# Get file mtime (seconds), macOS/Linux compatible
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

# Get current Claude PID (for marker binding)
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

# Get current session shell PID (compat/debug)
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
log "Hook 触发 pid=$$ ppid=$PPID claude_pid=$CURRENT_CLAUDE_PID session_pid=$CURRENT_SESSION_PID"

# ============================================
# Check active loops (via marker files)
# ============================================

# Scan and collect all markers for this session
MARKERS=()

for marker in /tmp/pensieve-loop-*; do
    [[ -f "$marker" ]] || continue

    local_claude_pid=$(json_get_value "$marker" "claude_pid" "") || true
    [[ -n "$local_claude_pid" ]] || continue
    [[ -n "$CURRENT_CLAUDE_PID" ]] || continue

    # Only handle markers for current session
    [[ "$local_claude_pid" == "$CURRENT_CLAUDE_PID" ]] || continue

    # Cleanup: remove marker if claude_pid is no longer alive
    if ! kill -0 "$local_claude_pid" 2>/dev/null; then
        rm -f "$marker"
        log "清理过期 marker: $marker claude_pid=$local_claude_pid"
        continue
    fi

    local_task_list_id=$(json_get_value "$marker" "task_list_id" "") || local_task_list_id=""
    if [[ -z "$local_task_list_id" ]]; then
        auto_bound_marker="$(try_auto_bind_pending_marker "$marker" || true)"
        if [[ -n "$auto_bound_marker" && -f "$auto_bound_marker" ]]; then
            marker="$auto_bound_marker"
        else
            continue
        fi
    fi

    MARKERS+=("$marker")
done

if [[ "${#MARKERS[@]}" -eq 0 ]]; then
    log "未匹配到 marker，退出"
    exit 0
fi

# Sort by mtime ascending (older loops first)
sort_markers_by_mtime() {
    for m in "$@"; do
        printf "%s %s\n" "$(get_mtime "$m")" "$m"
    done | sort -n | awk '{print $2}'
}

# Initialize globals (overwritten per marker)
MARKER_FILE=""
TASK_LIST_ID=""
LOOP_DIR=""
META_FILE=""
CONTEXT_FILE=""
TASKS_DIR=""
MARKER_TASKS_PLANNED="false"

update_marker_tasks_planned() {
    local total="$1"
    local pending="$2"
    local in_progress="$3"
    local tmp_file="${MARKER_FILE}.tmp"
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    json_update_marker_tasks_planned_file \
        "$MARKER_FILE" "$tmp_file" "$now" "$total" "$pending" "$in_progress"
    mv "$tmp_file" "$MARKER_FILE"
    MARKER_TASKS_PLANNED="true"
}

# ============================================
# Helpers
# ============================================

read_goal() {
    if [[ -f "$META_FILE" ]]; then
        awk '/^## Overview/{flag=1; next} /^## /{flag=0} flag' "$META_FILE" | head -10
    else
        echo "(goal not set)"
    fi
}

read_pipeline() {
    if [[ -f "$META_FILE" ]]; then
        sed -n '/^---$/,/^---$/p' "$META_FILE" | grep "^pipeline:" | sed 's/^pipeline: *//'
    else
        echo "未知"
    fi
}

is_task_blocked() {
    local task_file="$1"
    local blocked_by
    blocked_by=$(json_get_array_lines "$task_file" "blockedBy")

    [[ -z "$blocked_by" ]] && return 1

    for dep_id in $blocked_by; do
        local dep_file="$TASKS_DIR/$dep_id.json"
        if [[ -f "$dep_file" ]]; then
            local dep_status
            dep_status=$(json_get_value "$dep_file" "status" "")
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
        status=$(json_get_value "$task_file" "status" "")

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
        status=$(json_get_value "$task_file" "status" "")

        case "$status" in
            completed) ((completed++)) || true ;;
            pending) ((pending++)) || true ;;
            in_progress) ((in_progress++)) || true ;;
        esac
    done

    echo "$total $completed $pending $in_progress"
}

check_all_completed_with_stats() {
    local total="$1"
    local pending="$2"
    local in_progress="$3"

    # total==0:
    # - tasks_planned=false → still in setup (no real tasks yet) → do not end
    # - tasks_planned=true  → tasks finished and cleaned by system → treat as done
    if [[ "$total" -eq 0 ]]; then
        [[ "$MARKER_TASKS_PLANNED" == "true" ]]
    else
        [[ "$pending" -eq 0 && "$in_progress" -eq 0 ]]
    fi
}

mark_in_progress() {
    local task_file="$1"
    local tmp_file="${task_file}.tmp"
    json_mark_task_in_progress_file "$task_file" "$tmp_file"
    mv "$tmp_file" "$task_file"
}

# ============================================
# Reinforcement message
# ============================================

generate_reinforcement() {
    local task_file="$1"
    local stats
    stats=$(count_tasks)
    local total completed pending in_progress
    read -r total completed pending in_progress <<< "$stats"

    local task_id task_subject
    task_id=$(json_get_value "$task_file" "id" "")
    task_subject=$(json_get_value "$task_file" "subject" "")
    local task_description
    task_description=$(json_get_value "$task_file" "description" "")

    local agent_prompt="$LOOP_DIR/_agent-prompt.md"

    local context_file="$LOOP_DIR/_context.md"

    local project_root_raw project_root user_data_root
    project_root_raw="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
    project_root="$(to_posix_path "$project_root_raw")"
    user_data_root="$project_root/.claude/pensieve"

    cat << EOF
Only call Task — do not execute yourself:

Task(subagent_type: "general-purpose", prompt: "Read $agent_prompt and execute task_id=$task_id")

System capability (updated via plugin): $SYSTEM_SKILL_ROOT
Project user data (never overwritten): $user_data_root

If you detect direction drift:
1. Read system pipelines/maxims/knowledge first
2. Record questions + answers in "$context_file" under "Post Context"
3. Continue

Task content:
- subject: $task_subject
- description: $task_description
EOF
}

should_skip_subagent() {
    local task_file="$1"
    local subject description
    subject=$(json_get_value "$task_file" "subject" "")
    description=$(json_get_value "$task_file" "description" "")
    [[ "$subject" == "Self‑Improve" ]] && return 0
    echo "$description" | grep -q "do not call agent" && return 0
    return 1
}

# ============================================
# Main
# ============================================

main() {
    local marker
    for marker in $(sort_markers_by_mtime "${MARKERS[@]}"); do
        local local_task_id local_loop_dir
        local_task_id=$(json_get_value "$marker" "task_list_id" "") || continue
        local_loop_dir=$(json_get_value "$marker" "loop_dir" "") || continue
        [[ -n "$local_task_id" && -n "$local_loop_dir" ]] || continue

        MARKER_FILE="$marker"
        TASK_LIST_ID="$local_task_id"
        LOOP_DIR="$local_loop_dir"
        META_FILE="$LOOP_DIR/_meta.md"
        CONTEXT_FILE="$LOOP_DIR/_context.md"
        TASKS_DIR="$HOME/.claude/tasks/$TASK_LIST_ID"
        MARKER_TASKS_PLANNED=$(json_get_value "$MARKER_FILE" "tasks_planned" "false") || MARKER_TASKS_PLANNED="false"

        if [[ ! -d "$TASKS_DIR" ]]; then
            if [[ "$MARKER_TASKS_PLANNED" == "true" ]]; then
                local self_improve_path
                self_improve_path="$SYSTEM_SKILL_ROOT/tools/self-improve/_self-improve.md"

                rm -f "$MARKER_FILE"
                local reason
                reason=$'All tasks are complete (task data was cleaned by the system). Run self‑improve?\n\nPipeline path:\n- '"$self_improve_path"$'\n\nIf yes, follow that pipeline; if no, that’s fine. Loop has stopped.'
                emit_block_response "$reason" "✅ Loop done | Self‑improve?"
                exit 0
            fi

            rm -f "$MARKER_FILE"
            log "任务目录不存在，已移除 marker: $TASKS_DIR"
            continue
        fi

        local stats
        stats=$(count_tasks)
        local total completed pending in_progress
        read -r total completed pending in_progress <<< "$stats"

        if [[ "$total" -gt 0 && "$MARKER_TASKS_PLANNED" != "true" ]]; then
            update_marker_tasks_planned "$total" "$pending" "$in_progress"
        fi

        if check_all_completed_with_stats "$total" "$pending" "$in_progress"; then
            local self_improve_path
            self_improve_path="$SYSTEM_SKILL_ROOT/tools/self-improve/_self-improve.md"

            # Remove marker so Stop Hook won't continue
            rm -f "$MARKER_FILE"
            local reason
            reason=$'All tasks are complete. Run self‑improve?\n\nPipeline path:\n- '"$self_improve_path"$'\n\nIf yes, follow that pipeline; if no, that’s fine. Loop has stopped.'
            emit_block_response "$reason" "✅ Loop done | Self‑improve?"
            exit 0
        fi

        local next_task
        if next_task=$(get_next_task); then
            if should_skip_subagent "$next_task"; then
                local task_id task_subject task_description
                task_id=$(json_get_value "$next_task" "id" "")
                task_subject=$(json_get_value "$next_task" "subject" "")
                task_description=$(json_get_value "$next_task" "description" "")
                local additional_context
                additional_context=$'Task content:\n- subject: '"$task_subject"$'\n- description: '"$task_description"
                emit_block_response \
                    "This task must be executed in the main window (no subagent). Follow the task instructions directly (e.g., read _self-improve.md), then update Task status." \
                    "⛳️ Loop | #$task_id $task_subject" \
                    "$additional_context"
                exit 0
            fi

            mark_in_progress "$next_task"

            local reinforcement
            reinforcement=$(generate_reinforcement "$next_task")

            local task_id task_subject
            task_id=$(json_get_value "$next_task" "id" "")
            task_subject=$(json_get_value "$next_task" "subject" "")
            local stats
            stats=$(count_tasks)
            local total completed pending in_progress
            read -r total completed pending in_progress <<< "$stats"
            emit_block_response "$reinforcement" "🔄 Loop [$completed/$total] | #$task_id $task_subject"
            exit 0
        fi
    done

    exit 0
}

main
