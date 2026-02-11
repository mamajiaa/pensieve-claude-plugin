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

echo "## 用户数据图谱"
if [[ -f "$GRAPH_FILE" ]]; then
  notes_count="$(sed -n 's/^- 扫描笔记数: //p' "$GRAPH_FILE" | head -n 1)"
  links_found="$(sed -n 's/^- 发现链接数: //p' "$GRAPH_FILE" | head -n 1)"
  links_resolved="$(sed -n 's/^- 已解析链接: //p' "$GRAPH_FILE" | head -n 1)"
  links_unresolved="$(sed -n 's/^- 未解析链接: //p' "$GRAPH_FILE" | head -n 1)"

  echo "- 图谱文件: $GRAPH_FILE"
  [[ -n "$notes_count" ]] && echo "- 扫描笔记数: $notes_count"
  [[ -n "$links_found" ]] && echo "- 发现链接数: $links_found"
  [[ -n "$links_resolved" ]] && echo "- 已解析链接: $links_resolved"
  [[ -n "$links_unresolved" ]] && echo "- 未解析链接: $links_unresolved"
else
  echo "- 图谱文件: (未生成)"
fi

echo
echo "## Pipelines 列表"
"$SCRIPT_DIR/list-pipelines.sh"
