#!/bin/bash
# PostToolUse hook:
# When project user-data files are edited, auto-refresh `.claude/skills/pensieve/SKILL.md`
# and keep project-level `MEMORY.md` Pensieve guidance block in sync.

set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python || true)}"
[[ -n "$PYTHON_BIN" ]] || exit 0

HOOK_INPUT="$(cat || true)"
[[ -n "$HOOK_INPUT" ]] || exit 0

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

extract_field() {
    local input="$1"
    local field="$2"
    printf '%s' "$input" | "$PYTHON_BIN" -c '
import json
import sys

field = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit(0)

tool_input = data.get("tool_input") or {}
tool_response = data.get("tool_response") or {}

if field == "tool_name":
    print(data.get("tool_name", ""))
elif field == "file_path":
    print(tool_input.get("file_path", ""))
elif field == "cwd":
    print(data.get("cwd", ""))
elif field == "success":
    ok = tool_response.get("success", True)
    print("true" if bool(ok) else "false")
else:
    print("")
' "$field"
}

TOOL_NAME="$(extract_field "$HOOK_INPUT" "tool_name")"
FILE_PATH_RAW="$(extract_field "$HOOK_INPUT" "file_path")"
CWD_RAW="$(extract_field "$HOOK_INPUT" "cwd")"
SUCCESS="$(extract_field "$HOOK_INPUT" "success")"

[[ "$SUCCESS" == "true" ]] || exit 0
[[ -n "$FILE_PATH_RAW" ]] || exit 0

FILE_PATH="$(to_posix_path "$FILE_PATH_RAW")"
CWD="$(to_posix_path "$CWD_RAW")"

if [[ "$FILE_PATH" != /* && -n "$CWD" ]]; then
    FILE_PATH="$CWD/$FILE_PATH"
fi

PROJECT_ROOT_RAW="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PROJECT_ROOT="$(to_posix_path "$PROJECT_ROOT_RAW")"
USER_DATA_ROOT="$PROJECT_ROOT/.claude/skills/pensieve"

if [[ "$FILE_PATH" != "$USER_DATA_ROOT" && "$FILE_PATH" != "$USER_DATA_ROOT/"* ]]; then
    exit 0
fi

REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"
case "$REL_PATH" in
    .claude/skills/pensieve/maxims/*|.claude/skills/pensieve/decisions/*|.claude/skills/pensieve/knowledge/*|.claude/skills/pensieve/pipelines/*)
        ;;
    *)
        exit 0
        ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT_RAW="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PLUGIN_ROOT="$(to_posix_path "$PLUGIN_ROOT_RAW")"
MAINTAIN_SCRIPT="$PLUGIN_ROOT/skills/pensieve/tools/project-skill/scripts/maintain-project-skill.sh"

[[ -x "$MAINTAIN_SCRIPT" ]] || exit 0

NOTE="posttooluse ${TOOL_NAME:-unknown}: ${REL_PATH}"
bash "$MAINTAIN_SCRIPT" --event sync --note "$NOTE" >/dev/null 2>&1 || true

exit 0
