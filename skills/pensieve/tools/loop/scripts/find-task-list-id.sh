#!/bin/bash
# Find taskListId by task subject in ~/.claude/tasks
# Usage: find-task-list-id.sh [subject]
# Default subject: Initialize loop

set -euo pipefail

SUBJECT="${1:-Initialize loop}"
TASKS_BASE="$HOME/.claude/tasks"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python || true)}"

if [[ ! -d "$TASKS_BASE" ]]; then
    echo "Error: task directory does not exist: $TASKS_BASE" >&2
    exit 1
fi

matches=()

dir_has_subject() {
    local dir="$1"
    local subject="$2"

    [[ -n "$PYTHON_BIN" ]] || return 1

    "$PYTHON_BIN" - "$dir" "$subject" <<'PY'
import glob
import json
import sys

directory, subject = sys.argv[1], sys.argv[2]
for path in glob.glob(f"{directory}/*.json"):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        continue
    if isinstance(data, dict) and data.get("subject") == subject:
        sys.exit(0)
sys.exit(1)
PY
}

for dir in "$TASKS_BASE"/*; do
    [[ -d "$dir" ]] || continue

    if [[ -n "$PYTHON_BIN" ]]; then
        if dir_has_subject "$dir" "$SUBJECT"; then
            matches+=("$dir")
        fi
    else
        if grep -Rqs "\"subject\" *: *\"$SUBJECT\"" "$dir"/*.json 2>/dev/null; then
            matches+=("$dir")
        fi
    fi
done

if [[ "${#matches[@]}" -eq 0 ]]; then
    echo "Error: no taskListId found for subject=\"$SUBJECT\"" >&2
    exit 1
fi

# Pick the most recently modified directory
pick_latest_dir() {
    if [[ -n "$PYTHON_BIN" ]]; then
        "$PYTHON_BIN" - "$@" <<'PY'
import os
import sys

dirs = [p for p in sys.argv[1:] if p]
if not dirs:
    sys.exit(1)

latest = max(dirs, key=os.path.getmtime)
print(latest)
PY
        return 0
    fi

    ls -dt "$@" | head -1
}

latest_dir="$(pick_latest_dir "${matches[@]}")"
basename "$latest_dir"
