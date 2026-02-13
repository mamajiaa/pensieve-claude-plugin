#!/bin/bash
# 初始化项目级 pensieve 用户数据目录：
#   <project>/.claude/pensieve/
#
# 该目录由用户拥有，插件更新永不覆盖。
#
# 可重复执行（幂等）。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

PROJECT_ROOT="$(project_root)"
DATA_ROOT="$PROJECT_ROOT/.claude/pensieve"

PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
TEMPLATES_ROOT="$PLUGIN_ROOT/skills/pensieve/tools/upgrade/templates"
SYSTEM_KNOWLEDGE_ROOT="$PLUGIN_ROOT/skills/pensieve/knowledge"

mkdir -p "$DATA_ROOT"/{maxims,decisions,knowledge,loop,pipelines}

TEMPLATE_MAXIMS_DIR="$TEMPLATES_ROOT/maxims"
if [[ -d "$TEMPLATE_MAXIMS_DIR" ]]; then
  for template_maxim in "$TEMPLATE_MAXIMS_DIR"/*.md; do
    [[ -f "$template_maxim" ]] || continue
    target_maxim="$DATA_ROOT/maxims/$(basename "$template_maxim")"
    if [[ ! -f "$target_maxim" ]]; then
      cp "$template_maxim" "$target_maxim"
    fi
  done
fi

KNOWLEDGE_SEEDED_COUNT=0
if [[ -d "$SYSTEM_KNOWLEDGE_ROOT" ]]; then
  while IFS= read -r source_file; do
    [[ -f "$source_file" ]] || continue
    rel_path="${source_file#$SYSTEM_KNOWLEDGE_ROOT/}"
    target_file="$DATA_ROOT/knowledge/$rel_path"
    mkdir -p "$(dirname "$target_file")"
    if [[ ! -f "$target_file" ]]; then
      cp "$source_file" "$target_file"
      ((KNOWLEDGE_SEEDED_COUNT++)) || true
    fi
  done < <(find "$SYSTEM_KNOWLEDGE_ROOT" -type f | LC_ALL=C sort)
fi

README="$DATA_ROOT/README.md"
if [[ ! -f "$README" ]]; then
  cat > "$README" << 'EOF'
# .claude/pensieve (User Data)

This directory is the project‑level Pensieve user data area:
- **NEVER** overwritten by plugin updates
- Safe to commit for team sharing, or ignore as needed

## Structure

- `maxims/`: your maxims (one maxim per file)
- `decisions/`: decision records (format: `<SYSTEM_SKILL_ROOT>/decisions/README.md`)
- `knowledge/`: external knowledge (format: `<SYSTEM_SKILL_ROOT>/knowledge/README.md`)
- `loop/`: loop runs (one folder per loop)
- `pipelines/`: project‑level pipelines (seeded at install)
EOF
fi
REVIEW_PIPELINE="$DATA_ROOT/pipelines/run-when-reviewing-code.md"
if [[ ! -f "$REVIEW_PIPELINE" ]]; then
  cp "$TEMPLATES_ROOT/pipeline.run-when-reviewing-code.md" "$REVIEW_PIPELINE"
fi

echo "✅ Initialization complete: $DATA_ROOT"
MAXIM_COUNT=0
if [[ -d "$DATA_ROOT/maxims" ]]; then
  MAXIM_COUNT="$(find "$DATA_ROOT/maxims" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
fi
echo "  - maxims/*.md: $MAXIM_COUNT files present"
echo "  - knowledge/*: seeded $KNOWLEDGE_SEEDED_COUNT new file(s)"
