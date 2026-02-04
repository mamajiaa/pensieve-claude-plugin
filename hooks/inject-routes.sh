#!/bin/bash
# SessionStart hook: 注入 Pensieve 的“系统能力 + 项目级用户数据”资源概览
#
# 约定：
# - 系统能力（pipelines/knowledge/scripts/maxims-format 等）随插件更新，位于插件内部
# - 用户数据永不由插件覆盖，位于项目级：<project>/.claude/pensieve/
#
# 输出：hookSpecificOutput.additionalContext（字符串）

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
USER_DATA_ROOT="$PROJECT_ROOT/.claude/pensieve"

if [[ ! -d "$SYSTEM_SKILL_ROOT" ]]; then
    # 保险：插件内容不完整时，不要影响会话
    exit 0
fi

# 构建 context 内容
CONTEXT="# Pensieve 可用资源"
CONTEXT+=$'\n\n'
CONTEXT+="## 路径"
CONTEXT+=$'\n\n'
CONTEXT+="- 插件根目录（系统能力）: \`$PLUGIN_ROOT\`"
CONTEXT+=$'\n'
CONTEXT+="- 系统 Skill: \`$SYSTEM_SKILL_ROOT\`"
CONTEXT+=$'\n'
CONTEXT+="- 项目级用户数据: \`$USER_DATA_ROOT\`"
CONTEXT+=$'\n\n'

# 系统 Pipelines
if [[ -d "$SYSTEM_SKILL_ROOT/pipelines" ]]; then
    CONTEXT+="## 系统 Pipelines"
    CONTEXT+=$'\n\n'
    for f in "$SYSTEM_SKILL_ROOT/pipelines"/*.md; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .md)
        [[ "$name" == "README" ]] && continue
        if [[ "$name" == _* ]]; then
            CONTEXT+="- \`$name.md\` (内置)"
        else
            CONTEXT+="- \`$name.md\`"
        fi
        CONTEXT+=$'\n'
    done
    CONTEXT+=$'\n'
fi

# 系统 Knowledge
if [[ -d "$SYSTEM_SKILL_ROOT/knowledge" ]]; then
    has_knowledge=false
    for d in "$SYSTEM_SKILL_ROOT/knowledge"/*/; do
        [[ -d "$d" ]] && has_knowledge=true && break
    done
    if $has_knowledge; then
        CONTEXT+="## 系统 Knowledge"
        CONTEXT+=$'\n\n'
        for d in "$SYSTEM_SKILL_ROOT/knowledge"/*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            CONTEXT+="- \`$name/\`"
            CONTEXT+=$'\n'
        done
        CONTEXT+=$'\n'
    fi
fi

# 用户数据概览（项目级）
if [[ -d "$USER_DATA_ROOT" ]]; then
    CONTEXT+="## 项目级用户数据"
    CONTEXT+=$'\n\n'

    if [[ -d "$USER_DATA_ROOT/maxims" ]]; then
        custom_count=$(find "$USER_DATA_ROOT/maxims" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- maxims: $custom_count 个文件"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- maxims: (未创建)"
        CONTEXT+=$'\n'
    fi

    if [[ -d "$USER_DATA_ROOT/decisions" ]]; then
        decision_count=$(find "$USER_DATA_ROOT/decisions" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- decisions: $decision_count 个文件"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- decisions: (未创建)"
        CONTEXT+=$'\n'
    fi

    if [[ -d "$USER_DATA_ROOT/knowledge" ]]; then
        knowledge_count=$(find "$USER_DATA_ROOT/knowledge" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- knowledge: $knowledge_count 个目录"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- knowledge: (未创建)"
        CONTEXT+=$'\n'
    fi

    if [[ -d "$USER_DATA_ROOT/loop" ]]; then
        loop_count=$(find "$USER_DATA_ROOT/loop" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- loop: $loop_count 个执行目录"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- loop: (未创建)"
        CONTEXT+=$'\n'
    fi

    CONTEXT+=$'\n'
else
    CONTEXT+="## 项目级用户数据（未初始化）"
    CONTEXT+=$'\n\n'
    CONTEXT+="建议创建目录（不会被插件更新覆盖）："
    CONTEXT+=$'\n'
    CONTEXT+="\`mkdir -p .claude/pensieve/{maxims,decisions,knowledge,loop}\`"
    CONTEXT+=$'\n'
    CONTEXT+="可选：运行初始化脚本："
    CONTEXT+=$'\n'
    CONTEXT+="\`$SYSTEM_SKILL_ROOT/scripts/init-project-data.sh\`"
    CONTEXT+=$'\n\n'
fi

CONTEXT+="使用方式：说出 pipeline 名称或相关意图，我会读取并执行对应流程。"

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
