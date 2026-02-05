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
TOOLS_ROOT="$SYSTEM_SKILL_ROOT/tools"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
USER_DATA_ROOT="$PROJECT_ROOT/.claude/pensieve"

if [[ ! -d "$SYSTEM_SKILL_ROOT" ]]; then
    # 保险：插件内容不完整时，不要影响会话
    exit 0
fi

# 清理无效的 loop marker（避免 /tmp 堆积）
get_claude_pid() {
    local pid="$$"
    while [[ "$pid" -gt 1 ]]; do
        local comm
        comm=$(ps -o comm= -p "$pid" 2>/dev/null | sed 's/^[[:space:]]*//')
        comm=$(basename "$comm")
        if [[ "$comm" == "claude" ]]; then
            echo "$pid"
            return 0
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        [[ -z "$pid" ]] && break
    done
    return 1
}

for marker in /tmp/pensieve-loop-*; do
    [[ -f "$marker" ]] || continue
    marker_claude_pid=$(jq -r '.claude_pid // empty' "$marker" 2>/dev/null) || true
    [[ -n "$marker_claude_pid" ]] || continue
    if ! kill -0 "$marker_claude_pid" 2>/dev/null; then
        rm -f "$marker" 2>/dev/null || true
    fi
done

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

# 系统 Tools
if [[ -d "$TOOLS_ROOT" ]]; then
    CONTEXT+="## 系统 Tools"
    CONTEXT+=$'\n\n'
    for d in "$TOOLS_ROOT"/*/; do
        [[ -d "$d" ]] || continue
        tool_name=$(basename "$d")
        CONTEXT+="- \`$tool_name/\`"

        # 列出入口文件（优先 _*.md）
        entry_files=()
        for f in "$d"/_*.md; do
            [[ -f "$f" ]] && entry_files+=("$(basename "$f")")
        done
        if [[ "${#entry_files[@]}" -gt 0 ]]; then
            CONTEXT+=" (入口: ${entry_files[*]})"
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

    if [[ -d "$USER_DATA_ROOT/pipelines" ]]; then
        pipeline_count=$(find "$USER_DATA_ROOT/pipelines" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        CONTEXT+="- pipelines: $pipeline_count 个文件"
        CONTEXT+=$'\n'
    else
        CONTEXT+="- pipelines: (未创建)"
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
    CONTEXT+="\`$SYSTEM_SKILL_ROOT/tools/loop/scripts/init-project-data.sh\`"
    CONTEXT+=$'\n\n'
fi

CONTEXT+="使用方式：说出 pipeline 名称或相关意图，我会读取并执行对应流程。"

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
