#!/bin/bash
# 列出项目级 pipelines 及描述

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../loop/scripts/_lib.sh"

pipeline_dir="$(user_data_root)/pipelines"

if [[ ! -d "$pipeline_dir" ]]; then
  echo "No project pipelines found"
  echo "Create the directory: mkdir -p .claude/skills/pensieve/pipelines"
  exit 0
fi

shopt -s nullglob
pipeline_files=("$pipeline_dir"/*.md)

if [[ "${#pipeline_files[@]}" -eq 0 ]]; then
  echo "No project pipelines found"
  echo "Create the directory: mkdir -p .claude/skills/pensieve/pipelines"
  exit 0
fi

echo "| Pipeline | 描述 |"
echo "|----------|------|"

for pipeline_file in "${pipeline_files[@]}"; do
  description="$(awk '
    function ltrim(s) { sub(/^[[:space:]]+/, "", s); return s }
    function rtrim(s) { sub(/[[:space:]]+$/, "", s); return s }
    function trim(s) { return rtrim(ltrim(s)) }
    NR==1 && $0=="---" {in_yaml=1; next}
    in_yaml==1 && $0=="---" {exit}
    in_yaml==1 {
      if (capture_desc==1) {
        if ($0 ~ /^[[:space:]][[:space:]]/) {
          line=$0
          sub(/^[[:space:]]+/, "", line)
          line=trim(line)
          if (line != "") {
            desc=line
            exit
          }
          next
        } else if ($0 ~ /^[[:space:]]*$/) {
          next
        } else {
          capture_desc=0
        }
      }

      if ($0 ~ /^description:[[:space:]]*/) {
        line=$0
        sub(/^description:[[:space:]]*/, "", line)
        line=trim(line)
        if (line ~ /^[|>][-+]?$/ || line == "") {
          capture_desc=1
          next
        }
        desc=line
        exit
      }
    }
    END { print desc }
  ' "$pipeline_file")"

  if [[ -z "$description" ]]; then
    description="(no description)"
  fi

  echo "| $pipeline_file | $description |"
done
