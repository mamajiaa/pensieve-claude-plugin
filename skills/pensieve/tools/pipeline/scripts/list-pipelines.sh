#!/bin/bash
# List project-level pipelines and descriptions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../loop/scripts/_lib.sh"

project_root_path="$(project_root)"
pipeline_dir="$project_root_path/.claude/pensieve/pipelines"

if [[ ! -d "$pipeline_dir" ]]; then
  echo "No project pipelines found"
  echo "Create the directory: mkdir -p .claude/pensieve/pipelines"
  exit 0
fi

shopt -s nullglob
pipeline_files=("$pipeline_dir"/*.md)

if [[ "${#pipeline_files[@]}" -eq 0 ]]; then
  echo "No project pipelines found"
  echo "Create the directory: mkdir -p .claude/pensieve/pipelines"
  exit 0
fi

echo "| Pipeline | Description |"
echo "|----------|-------------|"

for pipeline_file in "${pipeline_files[@]}"; do
  description="$(awk '
    NR==1 && $0=="---" {in_yaml=1; next}
    in_yaml==1 && $0=="---" {exit}
    in_yaml==1 && $0 ~ /^description:/ {sub(/^description:[[:space:]]*/, "", $0); print $0; exit}
  ' "$pipeline_file")"

  if [[ -z "$description" ]]; then
    description="(no description)"
  fi

  echo "| $pipeline_file | $description |"
done
