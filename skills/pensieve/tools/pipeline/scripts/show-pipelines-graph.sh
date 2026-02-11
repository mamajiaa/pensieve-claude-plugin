#!/bin/bash
# Graph-first output for /pipeline: show graph summary, then pipeline list.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../loop/scripts/_lib.sh"

PROJECT_ROOT="$(project_root)"
USER_DATA_ROOT="$PROJECT_ROOT/.claude/pensieve"
PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
GRAPH_SCRIPT="$PLUGIN_ROOT/skills/pensieve/tools/upgrade/scripts/generate-user-data-graph.sh"
GRAPH_FILE="$USER_DATA_ROOT/graph.md"

if [[ -d "$USER_DATA_ROOT" && -f "$GRAPH_SCRIPT" ]]; then
  bash "$GRAPH_SCRIPT" --root "$USER_DATA_ROOT" --output "$GRAPH_FILE" >/dev/null 2>&1 || true
fi

echo "## User Data Graph"
if [[ -f "$GRAPH_FILE" ]]; then
  notes_count="$(sed -n 's/^- Notes scanned: //p' "$GRAPH_FILE" | head -n 1)"
  links_found="$(sed -n 's/^- Links found: //p' "$GRAPH_FILE" | head -n 1)"
  links_resolved="$(sed -n 's/^- Links resolved: //p' "$GRAPH_FILE" | head -n 1)"
  links_unresolved="$(sed -n 's/^- Links unresolved: //p' "$GRAPH_FILE" | head -n 1)"

  echo "- Graph file: $GRAPH_FILE"
  [[ -n "$notes_count" ]] && echo "- Notes scanned: $notes_count"
  [[ -n "$links_found" ]] && echo "- Links found: $links_found"
  [[ -n "$links_resolved" ]] && echo "- Links resolved: $links_resolved"
  [[ -n "$links_unresolved" ]] && echo "- Links unresolved: $links_unresolved"
else
  echo "- Graph file: (not generated)"
fi

echo
echo "## Pipelines"
"$SCRIPT_DIR/list-pipelines.sh"
