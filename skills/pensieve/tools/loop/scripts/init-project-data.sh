#!/bin/bash
# 初始化项目级 pensieve 用户数据目录：
#   <project>/.claude/skills/pensieve/
#
# 该目录由用户拥有，插件更新永不覆盖。
#
# 可重复执行（幂等）。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

is_readme_file() {
  case "$(basename "$1")" in
    [Rr][Ee][Aa][Dd][Mm][Ee]|[Rr][Ee][Aa][Dd][Mm][Ee].md)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

PROJECT_ROOT="$(project_root)"
DATA_ROOT="$(user_data_root)"

PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
TEMPLATES_ROOT="$PLUGIN_ROOT/skills/pensieve/tools/upgrade/templates"
SYSTEM_KNOWLEDGE_ROOT="$PLUGIN_ROOT/skills/pensieve/knowledge"
PROJECT_SKILL_SCRIPT="$PLUGIN_ROOT/skills/pensieve/tools/project-skill/scripts/maintain-project-skill.sh"

mkdir -p "$DATA_ROOT"/{maxims,decisions,knowledge,loop,pipelines}

TEMPLATE_MAXIMS_DIR="$TEMPLATES_ROOT/maxims"
if [[ -d "$TEMPLATE_MAXIMS_DIR" ]]; then
  for template_maxim in "$TEMPLATE_MAXIMS_DIR"/*.md; do
    [[ -f "$template_maxim" ]] || continue
    is_readme_file "$template_maxim" && continue
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
    is_readme_file "$source_file" && continue
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
# .claude/skills/pensieve (Project Skill Data)

This directory is the project‑level Pensieve user data area:
- **NEVER** overwritten by plugin updates
- Safe to commit for team sharing, or ignore as needed

## Structure

- `maxims/`: your maxims (one maxim per file)
- `decisions/`: decision records (format: `<SYSTEM_SKILL_ROOT>/decisions/README.md`)
- `knowledge/`: external knowledge (format: `<SYSTEM_SKILL_ROOT>/knowledge/README.md`)
- `loop/`: loop runs (one folder per loop)
- `pipelines/`: project‑level pipelines (seeded at install)
- `SKILL.md`: project-level skill route + graph (auto-generated, do not edit manually)
EOF
fi
PIPELINE_SEEDED_COUNT=0
for template_pipeline in "$TEMPLATES_ROOT"/pipeline.run-when-*.md; do
  [[ -f "$template_pipeline" ]] || continue
  is_readme_file "$template_pipeline" && continue
  pipeline_name="$(basename "$template_pipeline" | sed 's/^pipeline\.//')"
  target_pipeline="$DATA_ROOT/pipelines/$pipeline_name"
  if [[ ! -f "$target_pipeline" ]]; then
    cp "$template_pipeline" "$target_pipeline"
    ((PIPELINE_SEEDED_COUNT++)) || true
  fi
done

echo "✅ Initialization complete: $DATA_ROOT"
MAXIM_COUNT=0
if [[ -d "$DATA_ROOT/maxims" ]]; then
  MAXIM_COUNT="$(find "$DATA_ROOT/maxims" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
fi
echo "  - maxims/*.md: $MAXIM_COUNT files present"
echo "  - knowledge/*: seeded $KNOWLEDGE_SEEDED_COUNT new file(s)"
echo "  - pipelines/*: seeded $PIPELINE_SEEDED_COUNT new file(s)"

if [[ -x "$PROJECT_SKILL_SCRIPT" ]]; then
  if ! bash "$PROJECT_SKILL_SCRIPT" --event install --note "seeded project skill data via init-project-data.sh"; then
    echo "⚠️  Project skill update skipped: failed to run maintain-project-skill.sh" >&2
  fi
fi
