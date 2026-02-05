#!/bin/bash
# 列出项目级 pipelines 及描述

set -euo pipefail

project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
pipeline_dir="$project_root/.claude/pensieve/pipelines"

if [[ ! -d "$pipeline_dir" ]]; then
  echo "当前项目没有 pipelines"
  echo "创建目录: mkdir -p .claude/pensieve/pipelines"
  exit 0
fi

shopt -s nullglob
pipeline_files=("$pipeline_dir"/*.md)

if [[ "${#pipeline_files[@]}" -eq 0 ]]; then
  echo "当前项目没有 pipelines"
  echo "创建目录: mkdir -p .claude/pensieve/pipelines"
  exit 0
fi

echo "| Pipeline | 描述 |"
echo "|----------|------|"

for pipeline_file in "${pipeline_files[@]}"; do
  description="$(awk '
    NR==1 && $0=="---" {in_yaml=1; next}
    in_yaml==1 && $0=="---" {exit}
    in_yaml==1 && $0 ~ /^description:/ {sub(/^description:[[:space:]]*/, "", $0); print $0; exit}
  ' "$pipeline_file")"

  if [[ -z "$description" ]]; then
    description="(无描述)"
  fi

  echo "| $pipeline_file | $description |"
done
