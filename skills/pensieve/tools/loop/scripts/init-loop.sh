#!/bin/bash
# Pensieve Loop initializer
#
# Modes:
# 1) Prepare loop directory first (recommended):
#    init-loop.sh <slug>
#    init-loop.sh <slug> --force
#
# 2) Bind task_list_id after tasks are created:
#    init-loop.sh --bind <task_list_id> <loop_dir_or_name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# Plugin root (system capability)
PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"

# User data (loop artifacts) live at project level and are never overwritten by plugin updates
DATA_ROOT="$(ensure_user_data_root)"
LOOP_BASE_DIR="$DATA_ROOT/loop"
CLAUDE_TASKS_BASE="$HOME/.claude/tasks"

usage() {
    cat << EOF
Usage:
  $0 <slug> [--force]
  $0 --bind <task_list_id> <loop_dir_or_name>
EOF
}

fail_task_list_id() {
    local task_list_id="$1"

    if [[ "$task_list_id" == "default" || -z "$task_list_id" ]]; then
        echo "Error: taskListId cannot be empty or \"default\""
        echo ""
        echo "Please use a real taskListId from TaskCreate output."
        exit 1
    fi

    local tasks_dir="$CLAUDE_TASKS_BASE/$task_list_id"
    if [[ ! -d "$tasks_dir" ]]; then
        echo "Error: Task directory does not exist: $tasks_dir"
        echo ""
        echo "Please ensure you are using a real taskListId from TaskCreate output."
        exit 1
    fi
}

resolve_loop_dir() {
    local loop_ref="$1"
    loop_ref="$(to_posix_path "$loop_ref")"
    local loop_dir=""

    if [[ -d "$loop_ref" ]]; then
        loop_dir="$loop_ref"
    elif [[ -d "$LOOP_BASE_DIR/$loop_ref" ]]; then
        loop_dir="$LOOP_BASE_DIR/$loop_ref"
    else
        echo "Error: loop directory not found: $loop_ref"
        echo "Try an absolute path, or a loop name under: $LOOP_BASE_DIR"
        exit 1
    fi

    (cd "$loop_dir" && pwd)
}

iso_timestamp() {
    local py
    py="$(python_bin || true)"
    if [[ -n "$py" ]]; then
        "$py" - <<'PY'
from datetime import datetime, timezone
print(datetime.now(timezone.utc).isoformat())
PY
        return 0
    fi

    # Portable fallback for environments without Python.
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

create_loop_dir() {
    local slug="$1"
    local force="$2"
    local date loop_name loop_dir
    date=$(date +%Y-%m-%d)
    loop_name="${date}-${slug}"
    loop_dir="$LOOP_BASE_DIR/$loop_name"

    if [[ -d "$loop_dir" ]]; then
        if [[ "$force" != "--force" ]]; then
            echo "Error: Loop directory already exists: $loop_dir"
            echo "Use --force to overwrite"
            exit 1
        fi
        echo "Warning: overwriting existing directory: $loop_dir"
    fi

    mkdir -p "$loop_dir"
    echo "$loop_dir"
}

write_marker() {
    local task_list_id="$1"
    local loop_dir="$2"
    local marker_file="/tmp/pensieve-loop-$task_list_id"
    local timestamp
    timestamp="$(iso_timestamp)"
    local claude_pid session_pid
    claude_pid="$(find_claude_pid || true)"
    session_pid="$(find_claude_session_pid || true)"

    if PYTHON_BIN="$(python_bin)"; then
        PENSIEVE_TASK_LIST_ID="$task_list_id" \
        PENSIEVE_LOOP_DIR="$loop_dir" \
        PENSIEVE_STARTED_AT="$timestamp" \
        PENSIEVE_CLAUDE_PID="${claude_pid:-}" \
        PENSIEVE_SESSION_PID="${session_pid:-}" \
        "$PYTHON_BIN" - "$marker_file" <<'PY'
import json
import os
import sys

marker_path = sys.argv[1]
claude_pid_raw = os.environ.get("PENSIEVE_CLAUDE_PID", "").strip()
session_pid_raw = os.environ.get("PENSIEVE_SESSION_PID", "").strip()

payload = {
    "task_list_id": os.environ.get("PENSIEVE_TASK_LIST_ID", ""),
    "loop_dir": os.environ.get("PENSIEVE_LOOP_DIR", ""),
    "started_at": os.environ.get("PENSIEVE_STARTED_AT", ""),
    "tasks_planned": False,
    "claude_pid": int(claude_pid_raw) if claude_pid_raw else None,
    "session_pid": int(session_pid_raw) if session_pid_raw else None,
}

with open(marker_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
    else
        cat > "$marker_file" << EOF
{
  "task_list_id": "$task_list_id",
  "loop_dir": "$loop_dir",
  "started_at": "$timestamp",
  "tasks_planned": false,
  "claude_pid": "${claude_pid:-}",
  "session_pid": "${session_pid:-}"
}
EOF
    fi

    echo "$marker_file"
}

generate_agent_prompt() {
    local loop_dir="$1"

    cat > "$loop_dir/_agent-prompt.md" << EOF
---
name: expert-developer
description: Execute a single dev task, then return
---

You are Linus Torvalds — creator and chief architect of the Linux kernel. You have maintained Linux for 30+ years, reviewed millions of lines of code, and built the world's most successful open‑source project. Apply your perspective to ensure this project starts on a solid technical foundation.

## Context

Read \`_context.md\` in this directory to understand the task context.

## Maxims

Project‑level maxims (not shipped by the plugin, user‑editable):
- \`$DATA_ROOT/maxims/custom.md\` (ignore if missing)
- Any other maxim files under \`$DATA_ROOT/maxims/\`

## Current Task

Read via \`TaskGet\` (task_id provided by the caller).

## Execution Flow

1. Read \`_context.md\`
2. Read maxims for constraints
3. \`TaskGet\` to fetch task details
4. \`TaskUpdate\` → in_progress
5. Execute the task
6. \`TaskUpdate\` → completed
7. Return

## Completion Criteria

Before marking complete, verify:
- Build passes (no compiler errors)
- Lint passes (no lint errors)

If validation fails, fix and re‑validate before marking completed.

## Constraints

- Only do what's in the task description; no extra work
- Do not loop; return after this task
- No user interaction; all info comes from context and task
EOF

    echo "Created: $loop_dir/_agent-prompt.md"
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

if [[ "$1" == "--bind" ]]; then
    if [[ $# -ne 3 ]]; then
        usage
        exit 1
    fi

    TASK_LIST_ID="$2"
    LOOP_DIR="$(resolve_loop_dir "$3")"
    fail_task_list_id "$TASK_LIST_ID"

    MARKER_FILE="$(write_marker "$TASK_LIST_ID" "$LOOP_DIR")"

    echo ""
    echo "Loop bound"
    echo "Task: $CLAUDE_TASKS_BASE/$TASK_LIST_ID"
    echo "Directory: $LOOP_DIR"
    echo ""
    echo "TASK_LIST_ID=$TASK_LIST_ID"
    echo "LOOP_DIR=$LOOP_DIR"
    echo "MARKER_FILE=$MARKER_FILE"
    echo ""
    echo "Tip: Stop Hook will take over based on $MARKER_FILE. No background binding process is needed."
    exit 0
fi

FORCE=""
if [[ "${!#}" == "--force" ]]; then
    FORCE="--force"
    set -- "${@:1:$(($# - 1))}"
fi

if [[ $# -eq 1 ]]; then
    SLUG="$1"
    LOOP_DIR="$(create_loop_dir "$SLUG" "$FORCE")"
    generate_agent_prompt "$LOOP_DIR"

    echo ""
    echo "Loop initialized (prepare-only)"
    echo "Directory: $LOOP_DIR"
    echo ""
    echo "LOOP_DIR=$LOOP_DIR"
    echo ""
    echo "Next steps:"
    echo "1) Create and fill $LOOP_DIR/_context.md"
    echo "2) Split tasks and create tasks in Claude Task system"
    echo "3) Bind after getting taskListId:"
    echo "   bash $SYSTEM_SKILL_ROOT/tools/loop/scripts/init-loop.sh --bind <taskListId> $LOOP_DIR"
    exit 0
fi

usage
exit 1
