#!/bin/bash
# SessionStart hook: inject an overview of "system capability + project user data"
#
# Conventions:
# - System capability (tools/knowledge/scripts/format docs) lives in the plugin and updates with it
# - User data is never overwritten and lives at project level: <project>/.claude/pensieve/
#
# Output: hookSpecificOutput.additionalContext (string)

set -euo pipefail

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT_RAW="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PLUGIN_ROOT="$(to_posix_path "$PLUGIN_ROOT_RAW")"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"
TOOLS_ROOT="$SYSTEM_SKILL_ROOT/tools"
PROJECT_ROOT_RAW="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PROJECT_ROOT="$(to_posix_path "$PROJECT_ROOT_RAW")"
USER_DATA_ROOT="$PROJECT_ROOT/.claude/pensieve"

if [[ ! -d "$SYSTEM_SKILL_ROOT" ]]; then
    # Safety: if plugin content is incomplete, do not affect the session
    exit 0
fi

# Clean stale loop markers (avoid /tmp buildup)
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

for marker in /tmp/pensieve-loop-*; do
    [[ -f "$marker" ]] || continue
    marker_claude_pid=$("$PYTHON_BIN" - "$marker" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    print("")
    sys.exit(0)

value = data.get("claude_pid")
if value is None:
    print("")
else:
    print(value)
PY
) || true
    [[ -n "$marker_claude_pid" ]] || continue
    if ! kill -0 "$marker_claude_pid" 2>/dev/null; then
        rm -f "$marker" 2>/dev/null || true
    fi
done

# Build context content
CONTEXT="# Pensieve available resources"
CONTEXT+=$'\n\n'
CONTEXT+="## Paths"
CONTEXT+=$'\n\n'
CONTEXT+="- Plugin root (system capability): \`$PLUGIN_ROOT\`"
CONTEXT+=$'\n'
CONTEXT+="- System skill: \`$SYSTEM_SKILL_ROOT\`"
CONTEXT+=$'\n'
CONTEXT+="- Project user data: \`$USER_DATA_ROOT\`"
CONTEXT+=$'\n\n'

# System Tools
if [[ -d "$TOOLS_ROOT" ]]; then
    CONTEXT+="## System Tools"
    CONTEXT+=$'\n\n'
    for d in "$TOOLS_ROOT"/*/; do
        [[ -d "$d" ]] || continue
        tool_name=$(basename "$d")
        CONTEXT+="- \`$tool_name/\`"

        # List entry files (prefer _*.md)
        entry_files=()
        for f in "$d"/_*.md; do
            [[ -f "$f" ]] && entry_files+=("$(basename "$f")")
        done
        if [[ "${#entry_files[@]}" -gt 0 ]]; then
            CONTEXT+=" (entry: ${entry_files[*]})"
        fi
        CONTEXT+=$'\n'
    done
    CONTEXT+=$'\n'
fi

# System Knowledge
if [[ -d "$SYSTEM_SKILL_ROOT/knowledge" ]]; then
    has_knowledge=false
    for d in "$SYSTEM_SKILL_ROOT/knowledge"/*/; do
        [[ -d "$d" ]] && has_knowledge=true && break
    done
    if $has_knowledge; then
        CONTEXT+="## System Knowledge"
        CONTEXT+=$'\n\n'
        for d in "$SYSTEM_SKILL_ROOT/knowledge"/*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            CONTEXT+="- \`$name/\`"
            CONTEXT+=$'\n'
        done
        CONTEXT+=$'\n'
    fi
fi

# Project user data overview
if [[ -d "$USER_DATA_ROOT" ]]; then
    CONTEXT+="## Project user data"
    CONTEXT+=$'\n\n'

    if [[ -d "$USER_DATA_ROOT/maxims" ]]; then
        custom_count=$(find "$USER_DATA_ROOT/maxims" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- maxims: $custom_count files"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- maxims: (not created)"
        CONTEXT+=$'\n'
    fi

    if [[ -d "$USER_DATA_ROOT/decisions" ]]; then
        decision_count=$(find "$USER_DATA_ROOT/decisions" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- decisions: $decision_count files"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- decisions: (not created)"
        CONTEXT+=$'\n'
    fi

    if [[ -d "$USER_DATA_ROOT/knowledge" ]]; then
        knowledge_count=$(find "$USER_DATA_ROOT/knowledge" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- knowledge: $knowledge_count directories"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- knowledge: (not created)"
        CONTEXT+=$'\n'
    fi

    if [[ -d "$USER_DATA_ROOT/pipelines" ]]; then
        pipeline_count=$(find "$USER_DATA_ROOT/pipelines" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- pipelines: $pipeline_count files"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- pipelines: (not created)"
        CONTEXT+=$'\n'
    fi

    if [[ -d "$USER_DATA_ROOT/loop" ]]; then
        loop_count=$(find "$USER_DATA_ROOT/loop" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- loop: $loop_count run directories"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- loop: (not created)"
        CONTEXT+=$'\n'
    fi

    CONTEXT+=$'\n'
else
    CONTEXT+="## Project user data (not initialized)"
    CONTEXT+=$'\n\n'
    CONTEXT+="Suggested directory creation (never overwritten by plugin updates):"
    CONTEXT+=$'\n'
    CONTEXT+="\`mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}\`"
    CONTEXT+=$'\n'
    CONTEXT+="Optional: run initializer script:"
    CONTEXT+=$'\n'
    CONTEXT+="\`$SYSTEM_SKILL_ROOT/tools/loop/scripts/init-project-data.sh\`"
    CONTEXT+=$'\n\n'
fi

CONTEXT+="Usage: name a pipeline or intent, and I will load and run the corresponding flow."

PENSIEVE_CONTEXT="$CONTEXT" "$PYTHON_BIN" - <<'PY'
import json
import os

context = os.environ.get("PENSIEVE_CONTEXT", "")
payload = {
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": context,
    }
}
print(json.dumps(payload, ensure_ascii=False))
PY
