#!/bin/bash
# SessionStart hook: 扫描目录结构，动态生成可用资源列表
# 通过 JSON additionalContext 注入

set -e

# 加载共享函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载 _lib.sh（从 skill 目录）
# 先尝试找到 skill 目录
find_skill_root() {
    if [[ -d "$PWD/.claude/skills/pensieve" ]]; then
        echo "$PWD/.claude/skills/pensieve"
        return 0
    fi
    if [[ -d "$HOME/.claude/skills/pensieve" ]]; then
        echo "$HOME/.claude/skills/pensieve"
        return 0
    fi
    return 1
}

SKILL_ROOT="$(find_skill_root || true)"

if [[ -z "$SKILL_ROOT" || ! -d "$SKILL_ROOT" ]]; then
    # Skill 未安装，输出提示
    CONTEXT="# Pensieve Skill 未安装"
    CONTEXT+=$'\n\n'
    CONTEXT+="请先安装 Pensieve Skill 到 \`.claude/skills/pensieve/\` 目录。"
    CONTEXT+=$'\n\n'
    CONTEXT+="安装方法："
    CONTEXT+=$'\n'
    CONTEXT+="1. 克隆仓库: \`git clone https://github.com/kingkongshot/Pensieve.git /tmp/pensieve\`"
    CONTEXT+=$'\n'
    CONTEXT+="2. 复制 skill: \`cp -r /tmp/pensieve/skills/pensieve .claude/skills/\`"
    CONTEXT+=$'\n'
    CONTEXT+="3. 清理: \`rm -rf /tmp/pensieve\`"

    if command -v jq &> /dev/null; then
        jq -n --arg ctx "$CONTEXT" '{
            hookSpecificOutput: {
                hookEventName: "SessionStart",
                additionalContext: $ctx
            }
        }'
    fi
    exit 0
fi

# 构建 context 内容
CONTEXT="# Pensieve 可用资源（动态扫描）"
CONTEXT+=$'\n\n'
CONTEXT+="Skill 路径: \`$SKILL_ROOT\`"
CONTEXT+=$'\n\n'

# Pipelines
if [[ -d "$SKILL_ROOT/pipelines" ]]; then
    CONTEXT+="## Pipelines (\`pipelines/\`)"
    CONTEXT+=$'\n\n'
    for f in "$SKILL_ROOT/pipelines"/*.md; do
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

# Knowledge
if [[ -d "$SKILL_ROOT/knowledge" ]]; then
    has_knowledge=false
    for d in "$SKILL_ROOT/knowledge"/*/; do
        [[ -d "$d" ]] && has_knowledge=true && break
    done
    if $has_knowledge; then
        CONTEXT+="## Knowledge (\`knowledge/\`)"
        CONTEXT+=$'\n\n'
        for d in "$SKILL_ROOT/knowledge"/*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            CONTEXT+="- \`$name/\`"
            CONTEXT+=$'\n'
        done
        CONTEXT+=$'\n'
    fi
fi

# Decisions
if [[ -d "$SKILL_ROOT/decisions" ]]; then
    count=$(find "$SKILL_ROOT/decisions" -name "*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
        CONTEXT+="## Decisions (\`decisions/\`)"
        CONTEXT+=$'\n\n'
        for f in "$SKILL_ROOT/decisions"/*.md; do
            [[ -f "$f" ]] || continue
            name=$(basename "$f" .md)
            [[ "$name" == "README" ]] && continue
            CONTEXT+="- \`$name.md\`"
            CONTEXT+=$'\n'
        done
        CONTEXT+=$'\n'
    fi
fi

CONTEXT+="使用方式：说出 pipeline 名称或相关意图，我会读取并执行对应流程。"

# 同时更新 SKILL.md（方便人类查阅）
SKILL_FILE="$SKILL_ROOT/SKILL.md"
if [[ -f "$SKILL_FILE" ]]; then
    # 读取 frontmatter 和基础内容（到 <!-- AUTO-GENERATED --> 之前）
    STATIC_CONTENT=$(sed '/<!-- AUTO-GENERATED -->/,$d' "$SKILL_FILE")

    # 写入更新后的 SKILL.md
    cat > "$SKILL_FILE" << SKILL_EOF
$STATIC_CONTENT
<!-- AUTO-GENERATED -->
<!-- 以下内容由 SessionStart hook 自动生成，请勿手动编辑 -->

$CONTEXT
SKILL_EOF
fi

# 用 jq 生成正确的 JSON
if command -v jq &> /dev/null; then
    jq -n --arg ctx "$CONTEXT" '{
        hookSpecificOutput: {
            hookEventName: "SessionStart",
            additionalContext: $ctx
        }
    }'
else
    # fallback: 手动转义
    ESCAPED=$(printf '%s' "$CONTEXT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED
  }
}
EOF
fi

exit 0
