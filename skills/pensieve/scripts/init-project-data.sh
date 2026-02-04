#!/bin/bash
# Initialize project-level pensieve user data directory:
#   <project>/.claude/pensieve/
#
# This directory is user-owned and is NEVER overwritten by plugin updates.
#
# Safe to run multiple times (idempotent).

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DATA_ROOT="$PROJECT_ROOT/.claude/pensieve"

mkdir -p "$DATA_ROOT"/{maxims,decisions,knowledge,loop}

CUSTOM_MAXIMS="$DATA_ROOT/maxims/custom.md"
if [[ ! -f "$CUSTOM_MAXIMS" ]]; then
  cat > "$CUSTOM_MAXIMS" << 'EOF'
# 自定义准则（项目级）

在此添加你自己的准则。格式参考插件内的系统准则（路径会在 SessionStart 注入）：

- `<SYSTEM_SKILL_ROOT>/maxims/_linus.md`
- `<SYSTEM_SKILL_ROOT>/maxims/README.md`

---

<!-- 示例：
1. "准则名称" - 定位标签 "核心引语"

经典案例：XXX
具体指导要点
边界说明
-->
EOF
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
EOF
fi

echo "✅ 初始化完成: $DATA_ROOT"
echo "  - maxims/custom.md: $([[ -f "$CUSTOM_MAXIMS" ]] && echo exists || echo created)"
