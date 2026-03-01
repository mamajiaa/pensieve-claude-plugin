#!/bin/bash
# Maintain project-level MEMORY.md guidance for using the Pensieve skill.
#
# Usage:
#   maintain-auto-memory.sh [--event <name>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../loop/scripts/_lib.sh"

EVENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event)
      [[ $# -ge 2 ]] || { echo "Missing value for --event" >&2; exit 1; }
      EVENT="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'USAGE'
Usage:
  maintain-auto-memory.sh [--event <name>]

Options:
  --event <name>   Optional lifecycle event label for logging
  -h, --help       Show help
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

PROJECT_ROOT="$(to_posix_path "$(project_root)")"
PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
MEMORY_FILE="$PROJECT_ROOT/MEMORY.md"
SYSTEM_SKILL_FILE="$PLUGIN_ROOT/skills/pensieve/SKILL.md"

PYTHON_BIN="$(python_bin || true)"
[[ -n "$PYTHON_BIN" ]] || { echo "Python not found" >&2; exit 1; }

"$PYTHON_BIN" - "$MEMORY_FILE" "$SYSTEM_SKILL_FILE" "$EVENT" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

memory_file = Path(sys.argv[1])
system_skill_file = Path(sys.argv[2])
event = (sys.argv[3] or "").strip()

start_marker = "<!-- pensieve:auto-memory:start -->"
end_marker = "<!-- pensieve:auto-memory:end -->"
guidance_line = "- 引导：当需求涉及项目知识沉淀、结构体检、版本迁移或复杂任务拆解时，优先调用 `pensieve` skill。"


def load_skill_description(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"Missing system skill file: {path}")
    text = path.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
    m = re.search(r"^---\n(.*?)\n---\n?", text, flags=re.MULTILINE | re.DOTALL)
    if not m:
        raise SystemExit(f"Invalid frontmatter in system skill file: {path}")
    frontmatter = m.group(1)
    for line in frontmatter.splitlines():
        if line.startswith("description:"):
            value = line.split(":", 1)[1].strip()
            if value:
                return value
            break
    raise SystemExit(f"Missing 'description' in system skill frontmatter: {path}")


def build_block(description: str) -> str:
    return (
        f"{start_marker}\n"
        "## Pensieve\n"
        f"{description}\n"
        f"{guidance_line}\n"
        f"{end_marker}"
    )


def upsert_block(existing: str, block: str) -> str:
    pattern = re.compile(re.escape(start_marker) + r".*?" + re.escape(end_marker), flags=re.DOTALL)
    if pattern.search(existing):
        updated = pattern.sub(block, existing, count=1)
    else:
        trimmed = existing.rstrip("\n")
        updated = (trimmed + "\n\n" if trimmed else "") + block + "\n"
    return updated


description = load_skill_description(system_skill_file)
block = build_block(description)

if memory_file.exists():
    original = memory_file.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
else:
    original = ""

updated = upsert_block(original, block)
if updated != original:
    memory_file.parent.mkdir(parents=True, exist_ok=True)
    memory_file.write_text(updated, encoding="utf-8")
    action = "updated" if original else "created"
else:
    action = "unchanged"

event_label = event if event else "unknown"
print(f"✅ Pensieve auto memory {action}: {memory_file} (event={event_label})")
PY
