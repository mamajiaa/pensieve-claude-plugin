#!/bin/bash
# 根据 task subject 在 ~/.claude/tasks 中查找 taskListId
# 用法: find-task-list-id.sh [subject]
# 默认 subject: 初始化 loop

set -euo pipefail

SUBJECT="${1:-初始化 loop}"
TASKS_BASE="$HOME/.claude/tasks"

if [[ ! -d "$TASKS_BASE" ]]; then
    echo "错误: 任务目录不存在: $TASKS_BASE" >&2
    exit 1
fi

matches=()

for dir in "$TASKS_BASE"/*; do
    [[ -d "$dir" ]] || continue

    if command -v jq >/dev/null 2>&1; then
        if jq -e --arg subj "$SUBJECT" '.subject == $subj' "$dir"/*.json >/dev/null 2>&1; then
            matches+=("$dir")
        fi
    else
        if grep -Rqs "\"subject\" *: *\"$SUBJECT\"" "$dir"/*.json 2>/dev/null; then
            matches+=("$dir")
        fi
    fi
done

if [[ "${#matches[@]}" -eq 0 ]]; then
    echo "错误: 未找到 subject=\"$SUBJECT\" 的 taskListId" >&2
    exit 1
fi

# 选最近修改的目录
latest_dir=$(ls -dt "${matches[@]}" | head -1)
basename "$latest_dir"
