#!/bin/bash
# Generate a Mermaid graph for project-level Pensieve user data.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../loop/scripts/_lib.sh"

usage() {
    cat <<'USAGE'
Usage:
  generate-user-data-graph.sh [--root <path>] [--output <path>] [--include-loop]

Options:
  --root <path>      Scan root. Default: <project>/.claude/pensieve
  --output <path>    Output markdown file. Default: <root>/graph.md
  --include-loop     Include .claude/pensieve/loop/** in the graph
  -h, --help         Show this help
USAGE
}

ROOT=""
OUTPUT=""
INCLUDE_LOOP=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            [[ $# -ge 2 ]] || { echo "Missing value for --root" >&2; exit 1; }
            ROOT="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { echo "Missing value for --output" >&2; exit 1; }
            OUTPUT="$2"
            shift 2
            ;;
        --include-loop)
            INCLUDE_LOOP=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

PROJECT_ROOT="$(project_root)"
if [[ -z "$ROOT" ]]; then
    ROOT="$(user_data_root)"
fi
ROOT="$(to_posix_path "$ROOT")"

if [[ ! -d "$ROOT" ]]; then
    echo "Scan root does not exist: $ROOT" >&2
    exit 1
fi

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="$ROOT/graph.md"
else
    OUTPUT="$(to_posix_path "$OUTPUT")"
    if [[ "$OUTPUT" != /* ]]; then
        OUTPUT="$PROJECT_ROOT/$OUTPUT"
    fi
fi

mkdir -p "$(dirname "$OUTPUT")"
GENERATED_AT="$(date '+%Y-%m-%d %H:%M:%S')"

# Build a stable file list without relying on GNU-only flags (e.g., sort -z).
files=()
while IFS= read -r file; do
    files+=("$file")
done < <(find "$ROOT" -type f -name '*.md' | LC_ALL=C sort)

run_awk() {
awk \
    -v root="$ROOT" \
    -v output="$OUTPUT" \
    -v generated_at="$GENERATED_AT" \
    -v include_loop="$INCLUDE_LOOP" '
function trim(s) {
    sub(/^[[:space:]]+/, "", s)
    sub(/[[:space:]]+$/, "", s)
    return s
}
function relpath(path, r) {
    if (index(path, r "/") == 1) return substr(path, length(r) + 2)
    if (path == r) return ""
    return path
}
function category(rel, arr, n) {
    n = split(rel, arr, "/")
    if (n <= 1) return "root"
    return arr[1]
}
function allowed(cat) {
    if (cat == "root" || cat == "maxims" || cat == "decisions" || cat == "knowledge" || cat == "pipelines") return 1
    if (include_loop == "1" && cat == "loop") return 1
    return 0
}
function basename_noext(path, arr, n) {
    n = split(path, arr, "/")
    return arr[n]
}
function add_member(cat, rel, key) {
    key = cat SUBSEP rel
    if (!(key in member_seen)) {
        member_seen[key] = 1
        member_list[cat] = member_list[cat] rel "\n"
        node_count++
        node_order[node_count] = rel
        node_cat[rel] = cat
    }
}
function is_generated_graph(rel) {
    return (rel ~ /^graph(\.[^\/]+)?\.md$/)
}
BEGIN {
    node_count = 0
    edge_count = 0
    cats[1] = "root";      cat_title["root"] = "根目录"
    cats[2] = "maxims";    cat_title["maxims"] = "准则"
    cats[3] = "decisions"; cat_title["decisions"] = "决策"
    cats[4] = "knowledge"; cat_title["knowledge"] = "知识"
    cats[5] = "pipelines"; cat_title["pipelines"] = "流程"
    cats[6] = "loop";      cat_title["loop"] = "循环"
}
{
    if (FNR == 1) {
        file_allowed = 0
        if (FILENAME == output) {
            next
        }
        current_rel = relpath(FILENAME, root)
        if (is_generated_graph(current_rel)) {
            next
        }
        current_cat = category(current_rel)
        if (allowed(current_cat)) {
            add_member(current_cat, current_rel)
            file_allowed = 1
        }
    }
    if (!file_allowed) next

    line = $0
    label = "link"
    if (index(line, "基于") > 0) label = "基于"
    else if (index(line, "导致") > 0) label = "导致"
    else if (index(line, "相关") > 0) label = "相关"

    s = line
    while (match(s, /\[\[[^][]+\]\]/)) {
        tok = substr(s, RSTART + 2, RLENGTH - 4)
        sub(/\|.*/, "", tok)
        sub(/#.*/, "", tok)
        tok = trim(tok)
        if (tok != "") {
            edge_count++
            edge_from[edge_count] = current_rel
            edge_to_raw[edge_count] = tok
            edge_label[edge_count] = label
        }
        s = substr(s, RSTART + RLENGTH)
    }
}
END {
    for (i = 1; i <= node_count; i++) {
        rel = node_order[i]
        ids[rel] = "n" i

        rel_noext = rel
        sub(/\.md$/, "", rel_noext)
        noext_map[rel_noext] = rel

        base = basename_noext(rel_noext)
        base_count[base]++
        if (base_count[base] == 1) base_map[base] = rel
        else base_map[base] = ""
    }

    print "# Pensieve 用户数据图谱"
    print ""
    print "- 生成时间: " generated_at
    print "- 根目录: `" root "`"
    if (include_loop == "1") print "- 包含分类: maxims, decisions, knowledge, pipelines, loop"
    else print "- 包含分类: maxims, decisions, knowledge, pipelines"
    print ""
    print "```mermaid"
    print "graph LR"

    max_cat = (include_loop == "1" ? 6 : 5)
    for (ci = 1; ci <= max_cat; ci++) {
        cat = cats[ci]
        if (!(cat in member_list) || member_list[cat] == "") continue

        print "  subgraph \"" cat_title[cat] "\""
        n = split(member_list[cat], members, "\n")
        for (j = 1; j <= n; j++) {
            rel = members[j]
            if (rel == "") continue
            label_txt = rel
            gsub(/"/, "\\\"", label_txt)
            print "    " ids[rel] "[\"" label_txt "\"]"
        }
        print "  end"
    }

    resolved = 0
    unresolved = 0
    for (i = 1; i <= edge_count; i++) {
        src = edge_from[i]
        tok = edge_to_raw[i]
        lbl = edge_label[i]

        if (!(src in ids)) continue

        t = tok
        if (index(t, ".claude/pensieve/") == 1) t = substr(t, 18)
        if (substr(t, 1, 1) == "/") t = substr(t, 2)
        sub(/\.md$/, "", t)

        tgt = ""
        if (t in noext_map) tgt = noext_map[t]
        else if (index(t, "/") == 0 && base_count[t] == 1) tgt = base_map[t]

        if (tgt != "" && (tgt in ids)) {
            edge_key = src SUBSEP lbl SUBSEP tgt
            if (!(edge_key in edge_seen)) {
                edge_seen[edge_key] = 1
                if (lbl == "link") print "  " ids[src] " --> " ids[tgt]
                else print "  " ids[src] " -->|" lbl "| " ids[tgt]
                resolved++
            }
        } else {
            unresolved_key = src SUBSEP tok
            if (!(unresolved_key in unresolved_seen)) {
                unresolved_seen[unresolved_key] = 1
                unresolved++
                unresolved_src[unresolved] = src
                unresolved_tok[unresolved] = tok
            }
        }
    }

    print "```"
    print ""
    print "## 摘要"
    print ""
    print "- 扫描笔记数: " node_count
    print "- 发现链接数: " edge_count
    print "- 已解析链接: " resolved
    print "- 未解析链接: " unresolved

    if (unresolved > 0) {
        print ""
        print "## 未解析链接"
        print ""
        for (i = 1; i <= unresolved; i++) {
            print "- `" unresolved_src[i] "` -> `[[" unresolved_tok[i] "]]`"
        }
    }
}
' "$@"
}

if [[ ${#files[@]} -eq 0 ]]; then
    run_awk < /dev/null > "$OUTPUT"
else
    run_awk "${files[@]}" > "$OUTPUT"
fi

echo "✅ Graph generated: $OUTPUT"
