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

mkdir -p "$DATA_ROOT"/{maxims,decisions,knowledge,loop,pipelines}

CUSTOM_MAXIMS="$DATA_ROOT/maxims/custom.md"
if [[ ! -f "$CUSTOM_MAXIMS" ]]; then
  cp "$TEMPLATES_ROOT/maxims.initial.md" "$CUSTOM_MAXIMS"
fi

README="$DATA_ROOT/README.md"
if [[ ! -f "$README" ]]; then
  cat > "$README" << 'EOF'
# .claude/pensieve（用户数据）

这个目录是项目级的 Pensieve 用户数据区：
- **永不**由插件更新覆盖
- 适合提交到仓库（团队共享），也可以按需忽略

## 结构

- `maxims/`：你的准则（建议维护 `custom.md`）
- `decisions/`：决策记录（按 `<SYSTEM_SKILL_ROOT>/decisions/README.md` 的格式）
- `knowledge/`：外部知识（按 `<SYSTEM_SKILL_ROOT>/knowledge/README.md` 的格式）
- `loop/`：Loop 运行目录（每次 loop 一个子目录）
- `pipelines/`：项目级自定义流程（安装时写入初始 pipeline）
EOF
fi
REVIEW_PIPELINE="$DATA_ROOT/pipelines/review.md"
if [[ ! -f "$REVIEW_PIPELINE" ]]; then
  cp "$TEMPLATES_ROOT/pipeline.review.md" "$REVIEW_PIPELINE"
fi

echo "✅ 初始化完成: $DATA_ROOT"
echo "  - maxims/custom.md: $([[ -f "$CUSTOM_MAXIMS" ]] && echo 已存在 || echo 已创建)"
