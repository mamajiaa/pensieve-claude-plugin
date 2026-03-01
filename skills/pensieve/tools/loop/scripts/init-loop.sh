#!/bin/bash
# Pensieve Loop initializer (prepare-only)
#
# Usage:
#   init-loop.sh <slug>
#   init-loop.sh <slug> --force

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# Plugin root (system capability)
PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"

# User data (loop artifacts) live at project level and are never overwritten by plugin updates
DATA_ROOT="$(ensure_user_data_root)"
LOOP_BASE_DIR="$DATA_ROOT/loop"

usage() {
    cat << EOF_USAGE
Usage:
  $0 <slug> [--force]
EOF_USAGE
}

create_loop_dir() {
    local slug="$1"
    local force="$2"
    local date loop_name loop_dir
    date=$(date +%Y-%m-%d)
    loop_name="${date}-${slug}"
    loop_dir="$LOOP_BASE_DIR/$loop_name"

    if [[ -d "$loop_dir" ]]; then
        if [[ "$force" != "--force" ]]; then
            echo "Error: Loop directory already exists: $loop_dir"
            echo "Use --force to overwrite"
            exit 1
        fi
        echo "Warning: overwriting existing directory: $loop_dir"
    fi

    mkdir -p "$loop_dir"
    echo "$loop_dir"
}

generate_agent_prompt() {
    local loop_dir="$1"

    cat > "$loop_dir/_agent-prompt.md" << EOF_PROMPT
---
name: expert-developer
description: Execute a single task and return to the main window; do not expand scope or skip validation
---

You are Linus Torvalds -- creator and chief architect of the Linux kernel. You have maintained Linux for 30+ years, reviewed millions of lines of code, and built the world's most successful open-source project. Apply your perspective to ensure this project starts on a solid technical foundation.

## Loop Context Directory

Read this loop context directory first:
- \`$loop_dir/\`

Read any available context files in this directory, including:
- \`_context.md\` (conversation and latest constraints)
- \`requirements.md\` (requirements baseline)
- \`design.md\` (design decisions)
- \`_decisions/*.md\` (task-level deviations/decisions)

Do not rely on a single file when context has multiple artifacts.

## Maxims

Project-level maxims (not shipped by the plugin, user-editable):
- Read all maxim files under \`$DATA_ROOT/maxims/\` (\`*.md\`)

## Current Task

Read via \`TaskGet\` (current task is provided by the caller).

## Execution Flow

1. Read the loop context directory and all relevant context files
2. Read maxims for constraints
3. \`TaskGet\` to fetch task details
4. \`TaskUpdate\` -> in_progress
5. Execute the task
6. \`TaskUpdate\` -> completed
7. Return

## High-Signal Rule (must)

- Only report conclusions that have direct evidence from code/tests/commands.
- If evidence is insufficient, mark as blocked instead of guessing.
- Do not include style-only or speculative issues as task findings.

## Completion Criteria

Before marking complete, verify:
- Build passes (no compiler errors, when build is applicable)
- Lint passes (no lint errors, when lint is applicable)

If validation fails, fix and re-validate before marking completed.

## Output Contract

Return in this exact format:

## Task Result
- Status: completed | blocked
- Summary: one-line result
- Evidence:
  - file/test/command evidence 1
  - file/test/command evidence 2
- Files Changed:
  - path/to/file1
  - path/to/file2
- Risks:
  - risk 1 (or "none")
- Next Step:
  - concrete next action for main window

## Failure Fallback

- If required context/task data is missing, set task to blocked and explain the missing input.
- If command/test repeatedly fails, set task to blocked with repro steps and last error.
- Never silently continue after a failed validation.

## Constraints

- Only do what's in the task description; no extra work
- Do not loop; return after this task
- No user interaction; all info comes from context and task
EOF_PROMPT

    echo "Created: $loop_dir/_agent-prompt.md"
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

FORCE=""
if [[ "${!#}" == "--force" ]]; then
    FORCE="--force"
    set -- "${@:1:$(($# - 1))}"
fi

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

SLUG="$1"
LOOP_DIR="$(create_loop_dir "$SLUG" "$FORCE")"
generate_agent_prompt "$LOOP_DIR"

echo ""
echo "Loop initialized (prepare-only)"
echo "Directory: $LOOP_DIR"
echo ""
echo "LOOP_DIR=$LOOP_DIR"
echo ""
echo "Next steps:"
echo "1) Create and fill $LOOP_DIR/_context.md"
echo "2) Split tasks and create tasks in Claude Task system"
echo "3) Continue from the main window by dispatching one pending task at a time"
