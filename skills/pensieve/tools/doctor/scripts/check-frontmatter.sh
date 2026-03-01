#!/bin/bash
# Quick frontmatter + structural validator for project-level Pensieve user data.
# No external dependency; uses Python stdlib only.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../loop/scripts/_lib.sh"

ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -ge 2 ]] || { echo "Missing value for --root" >&2; exit 1; }
      ROOT="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'USAGE'
Usage:
  check-frontmatter.sh [--root <path>]

Options:
  --root <path>   Scan root. Default: <project>/.claude/skills/pensieve
  -h, --help      Show help
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  ROOT="$(user_data_root)"
fi
ROOT="$(to_posix_path "$ROOT")"

PYTHON_BIN="$(python_bin || true)"
[[ -n "$PYTHON_BIN" ]] || { echo "Python not found" >&2; exit 1; }

"$PYTHON_BIN" - "$ROOT" <<'PY'
from __future__ import annotations

import datetime as dt
import re
import sys
from dataclasses import dataclass
from pathlib import Path

root = Path(sys.argv[1])

allowed_types = {"maxim", "decision", "knowledge", "pipeline"}
allowed_status = {"draft", "active", "archived"}
required_keys = ["id", "type", "title", "status", "created", "updated", "tags"]
id_re = re.compile(r"^[a-z0-9][a-z0-9-]*$")
date_re = re.compile(r"^\d{4}-\d{2}-\d{2}$")
pipeline_name_re = re.compile(r"^run-when-[a-z0-9-]+\.md$")


@dataclass
class Issue:
    level: str  # MUST_FIX / SHOULD_FIX
    code: str
    path: str
    message: str


def list_markdown_files(base: Path) -> list[Path]:
    if not base.exists():
        return []
    files: list[Path] = []
    for cat in ["maxims", "decisions", "knowledge", "pipelines"]:
        cat_dir = base / cat
        if not cat_dir.exists():
            continue
        for p in cat_dir.rglob("*.md"):
            if p.name.startswith("graph"):
                continue
            if cat == "maxims" and p.name == "custom.md":
                # Legacy maxim index; not part of current required model.
                continue
            files.append(p)
    return sorted(files)


def parse_frontmatter(text: str) -> tuple[dict[str, object] | None, list[str], str | None]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, [], None

    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break
    if end_idx is None:
        return None, [], "unclosed"

    fm_lines = lines[1:end_idx]
    data: dict[str, object] = {}
    errors: list[str] = []

    current_key: str | None = None
    mode: str | None = None  # None | list | block

    i = 0
    while i < len(fm_lines):
        line = fm_lines[i].rstrip("\n")
        stripped = line.strip()

        if mode == "block":
            if line.startswith(" ") or line.startswith("\t") or stripped == "":
                if stripped:
                    prev = data.get(current_key or "", "")
                    assert isinstance(prev, str)
                    data[current_key or ""] = (prev + "\n" if prev else "") + line.lstrip()
                i += 1
                continue
            mode = None
            current_key = None
            continue  # reprocess current line

        if mode == "list":
            if line.lstrip().startswith("- "):
                item = line.split("- ", 1)[1].strip()
                cast = data.get(current_key or "")
                if not isinstance(cast, list):
                    errors.append(f"malformed list item: {line}")
                elif item:
                    cast.append(item)
                i += 1
                continue
            if line.startswith(" ") or line.startswith("\t"):
                errors.append(f"malformed list item: {line}")
                i += 1
                continue
            mode = None
            current_key = None
            continue  # reprocess current line

        if not stripped or stripped.startswith("#"):
            i += 1
            continue

        if ":" not in line:
            errors.append(f"malformed line: {line}")
            i += 1
            continue

        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()

        if not key:
            errors.append(f"empty key line: {line}")
            i += 1
            continue
        if key in data:
            errors.append(f"duplicate key: {key}")
            i += 1
            continue

        if value in {"|", ">", "|-", ">-", "|+", ">+"}:
            data[key] = ""
            current_key = key
            mode = "block"
            i += 1
            continue

        if value == "":
            data[key] = []
            current_key = key
            mode = "list"
            i += 1
            continue

        if value.startswith("[") and value.endswith("]"):
            inner = value[1:-1].strip()
            items = [] if inner == "" else [x.strip().strip('"').strip("'") for x in inner.split(",")]
            data[key] = [x for x in items if x]
            current_key = key
            mode = None
            i += 1
            continue

        data[key] = value.strip('"').strip("'")
        current_key = key
        mode = None
        i += 1

    return data, errors, None


def body_without_frontmatter(text: str) -> str:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return text
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return "\n".join(lines[i + 1 :])
    return text


def valid_date(s: str) -> bool:
    if not date_re.match(s):
        return False
    try:
        dt.date.fromisoformat(s)
    except ValueError:
        return False
    return True


issues: list[Issue] = []
files = list_markdown_files(root)

if not root.exists():
    issues.append(Issue("MUST_FIX", "FM-000", str(root), "User data root directory does not exist"))

for p in files:
    rel = str(p.relative_to(root))

    if rel.startswith("pipelines/"):
        if p.name == "review.md":
            issues.append(
                Issue(
                    "MUST_FIX",
                    "FM-301",
                    rel,
                    "Legacy pipeline filename `review.md` is deprecated; rename to `run-when-*.md` (recommended: `run-when-reviewing-code.md`)",
                )
            )
        elif not pipeline_name_re.match(p.name):
            issues.append(
                Issue(
                    "MUST_FIX",
                    "FM-302",
                    rel,
                    "Pipeline filename must match `run-when-*.md` so invocation intent is clear from the name",
                )
            )

    text = p.read_text(encoding="utf-8", errors="replace")
    fm, parse_errors, fm_state = parse_frontmatter(text)

    if fm is None:
        if fm_state == "unclosed":
            issues.append(Issue("MUST_FIX", "FM-101", rel, "frontmatter starts but is not closed (missing ending ---)"))
        else:
            issues.append(Issue("MUST_FIX", "FM-102", rel, "missing frontmatter (required unified top-level metadata)"))
        continue

    for err in parse_errors:
        issues.append(Issue("MUST_FIX", "FM-103", rel, f"frontmatter syntax error: {err}"))

    missing = [k for k in required_keys if k not in fm]
    if missing:
        issues.append(Issue("MUST_FIX", "FM-104", rel, f"missing required fields: {', '.join(missing)}"))

    v_type = fm.get("type")
    if isinstance(v_type, str) and v_type and v_type not in allowed_types:
        issues.append(Issue("MUST_FIX", "FM-201", rel, f"invalid type: {v_type} (allowed: {', '.join(sorted(allowed_types))})"))

    v_status = fm.get("status")
    if isinstance(v_status, str) and v_status and v_status not in allowed_status:
        issues.append(Issue("MUST_FIX", "FM-202", rel, f"invalid status: {v_status} (allowed: {', '.join(sorted(allowed_status))})"))

    v_id = fm.get("id")
    if isinstance(v_id, str) and v_id and not id_re.match(v_id):
        issues.append(Issue("MUST_FIX", "FM-203", rel, "invalid id (allow only lowercase letters/digits/hyphen; cannot start with hyphen)"))

    for key in ["created", "updated"]:
        v = fm.get(key)
        if isinstance(v, str) and v and not valid_date(v):
            issues.append(Issue("MUST_FIX", "FM-204", rel, f"{key} is invalid (must be YYYY-MM-DD)"))

    v_tags = fm.get("tags")
    if v_tags is not None and not isinstance(v_tags, list):
        issues.append(Issue("MUST_FIX", "FM-205", rel, "invalid tags (must be an array, e.g. [pensieve, maxim])"))

    if rel.startswith("decisions/"):
        body = body_without_frontmatter(text)
        if not re.search(r"^\s*##\s*Exploration Shortcut\s*$", body, flags=re.MULTILINE):
            issues.append(
                Issue(
                    "SHOULD_FIX",
                    "FM-401",
                    rel,
                    "decision should include an `## Exploration Shortcut` section to clarify how to reduce inquiry and exploration cost next time",
                )
            )
        else:
            if "What to ask less next time" not in body:
                issues.append(
                    Issue(
                        "SHOULD_FIX",
                        "FM-402",
                        rel,
                        "decision `Exploration Shortcut` section is missing a 'What to ask less next time' entry",
                    )
                )
            if "What to look up less next time" not in body:
                issues.append(
                    Issue(
                        "SHOULD_FIX",
                        "FM-403",
                        rel,
                        "decision `Exploration Shortcut` section is missing a 'What to look up less next time' entry",
                    )
                )
            if "Invalidation conditions" not in body:
                issues.append(
                    Issue(
                        "SHOULD_FIX",
                        "FM-404",
                        rel,
                        "decision `Exploration Shortcut` section is missing an 'Invalidation conditions (when to re-evaluate)' entry",
                    )
                )

must_fix = [x for x in issues if x.level == "MUST_FIX"]
should_fix = [x for x in issues if x.level == "SHOULD_FIX"]

print("# Frontmatter Quick Check Report")
print()
print(f"- Root: `{root}`")
print(f"- Files scanned: {len(files)}")
print(f"- MUST_FIX: {len(must_fix)}")
print(f"- SHOULD_FIX: {len(should_fix)}")
print()

print("## MUST_FIX")
if not must_fix:
    print("- (none)")
else:
    for i in must_fix:
        print(f"- [{i.code}] `{i.path}`: {i.message}")
print()

print("## SHOULD_FIX")
if not should_fix:
    print("- (none)")
else:
    for i in should_fix:
        print(f"- [{i.code}] `{i.path}`: {i.message}")
PY
