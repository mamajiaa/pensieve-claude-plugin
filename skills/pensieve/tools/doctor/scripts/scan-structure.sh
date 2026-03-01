#!/bin/bash
# Shared structural scanner for project-level Pensieve user data.
# Single source for Doctor/Upgrade structural checks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../loop/scripts/_lib.sh"

usage() {
  cat <<'USAGE'
Usage:
  scan-structure.sh [--root <path>] [--output <path>] [--format <json|text>] [--fail-on-drift]

Options:
  --root <path>       Scan root. Default: <project>/.claude/skills/pensieve
  --output <path>     Output file path. Default: stdout
  --format <fmt>      Output format: json | text. Default: json
  --fail-on-drift     Exit with code 3 when MUST_FIX findings exist
  -h, --help          Show help
USAGE
}

ROOT=""
OUTPUT="-"
FORMAT="json"
FAIL_ON_DRIFT=0

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
    --format)
      [[ $# -ge 2 ]] || { echo "Missing value for --format" >&2; exit 1; }
      FORMAT="$2"
      shift 2
      ;;
    --fail-on-drift)
      FAIL_ON_DRIFT=1
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

case "$FORMAT" in
  json|text)
    ;;
  *)
    echo "Unsupported --format: $FORMAT (expected: json|text)" >&2
    exit 1
    ;;
esac

PROJECT_ROOT="$(to_posix_path "$(project_root)")"
if [[ -z "$ROOT" ]]; then
  ROOT="$(user_data_root)"
fi
ROOT="$(to_posix_path "$ROOT")"
AUTO_MEMORY_FILE="$(to_posix_path "$(auto_memory_file)")"

if [[ "$OUTPUT" != "-" ]]; then
  OUTPUT="$(to_posix_path "$OUTPUT")"
  if [[ "$OUTPUT" != /* ]]; then
    OUTPUT="$PROJECT_ROOT/$OUTPUT"
  fi
  mkdir -p "$(dirname "$OUTPUT")"
fi

PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
HOME_DIR="${HOME:-}"
TIMESTAMP="$(runtime_now_utc)"

PYTHON_BIN="$(python_bin || true)"
[[ -n "$PYTHON_BIN" ]] || { echo "Python not found" >&2; exit 1; }

"$PYTHON_BIN" - "$ROOT" "$PROJECT_ROOT" "$PLUGIN_ROOT" "$HOME_DIR" "$AUTO_MEMORY_FILE" "$FORMAT" "$OUTPUT" "$TIMESTAMP" "$FAIL_ON_DRIFT" <<'PY'
from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Finding:
    finding_id: str
    severity: str
    category: str
    path: str
    message: str
    recommended_action: str

    def as_dict(self) -> dict[str, str]:
        return {
            "id": self.finding_id,
            "severity": self.severity,
            "category": self.category,
            "path": self.path,
            "message": self.message,
            "recommended_action": self.recommended_action,
        }


root = Path(sys.argv[1])
project_root = Path(sys.argv[2])
plugin_root = Path(sys.argv[3])
home_dir = Path(sys.argv[4]) if sys.argv[4] else Path.home()
memory_file = Path(sys.argv[5])
fmt = sys.argv[6]
output = sys.argv[7]
generated_at = sys.argv[8]
fail_on_drift = sys.argv[9] == "1"

findings: list[Finding] = []
dedupe_keys: set[tuple[str, str, str]] = set()

required_dirs = ["maxims", "decisions", "knowledge", "pipelines", "loop"]
critical_files = [
    (
        root / "pipelines" / "run-when-reviewing-code.md",
        plugin_root / "skills" / "pensieve" / "tools" / "upgrade" / "templates" / "pipeline.run-when-reviewing-code.md",
    ),
    (
        root / "pipelines" / "run-when-committing.md",
        plugin_root / "skills" / "pensieve" / "tools" / "upgrade" / "templates" / "pipeline.run-when-committing.md",
    ),
    (
        root / "knowledge" / "taste-review" / "content.md",
        plugin_root / "skills" / "pensieve" / "knowledge" / "taste-review" / "content.md",
    ),
]

legacy_project_paths = [
    project_root / "skills" / "pensieve",
    project_root / ".claude" / "pensieve",
]
legacy_user_paths = [
    home_dir / ".claude" / "skills" / "pensieve",
    home_dir / ".claude" / "pensieve",
]
legacy_graph_patterns = ["_pensieve-graph*.md", "pensieve-graph*.md", "graph*.md"]
legacy_readme_re = re.compile(r"(?i)^readme(?:.*\.md)?$")
# Match plugin-internal knowledge path, but ignore project-scoped ".claude/skills/..." references.
plugin_path_re = re.compile(r"(?<!\.claude/)skills/pensieve/knowledge/")
plugin_skill_root = plugin_root / "skills" / "pensieve"
system_skill_file = plugin_skill_root / "SKILL.md"
memory_start_marker = "<!-- pensieve:auto-memory:start -->"
memory_end_marker = "<!-- pensieve:auto-memory:end -->"
memory_guidance_line = "- Guidance: When needs involve project knowledge retention, structural health checks, version migration, or complex task decomposition, prefer invoking `pensieve` skill."


def add_finding(
    finding_id: str,
    severity: str,
    category: str,
    path: Path | str,
    message: str,
    recommended_action: str,
) -> None:
    path_str = str(path)
    key = (finding_id, severity, path_str)
    if key in dedupe_keys:
        return
    dedupe_keys.add(key)
    findings.append(
        Finding(
            finding_id=finding_id,
            severity=severity,
            category=category,
            path=path_str,
            message=message,
            recommended_action=recommended_action,
        )
    )


def same_path(a: Path, b: Path) -> bool:
    try:
        return a.resolve() == b.resolve()
    except Exception:  # noqa: BLE001
        return False


def read_text_normalized(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")


def has_plugin_knowledge_path_reference(text: str) -> bool:
    if "<SYSTEM_SKILL_ROOT>/knowledge/" in text:
        return True
    return bool(plugin_path_re.search(text))


def load_json(path: Path) -> tuple[dict | None, str | None]:
    if not path.exists():
        return None, None
    try:
        data = json.loads(path.read_text(encoding="utf-8", errors="replace"))
    except Exception as exc:  # noqa: BLE001
        return None, str(exc)
    if not isinstance(data, dict):
        return None, "root must be a JSON object"
    return data, None


def load_system_skill_description(path: Path) -> str | None:
    if not path.is_file():
        return None
    text = read_text_normalized(path)
    m = re.search(r"^---\n(.*?)\n---\n?", text, flags=re.MULTILINE | re.DOTALL)
    if not m:
        return None
    for line in m.group(1).splitlines():
        if line.startswith("description:"):
            value = line.split(":", 1)[1].strip()
            return value if value else None
    return None


def extract_pensieve_memory_block(text: str) -> str:
    pattern = re.compile(
        re.escape(memory_start_marker) + r"(.*?)" + re.escape(memory_end_marker),
        flags=re.DOTALL,
    )
    m = pattern.search(text)
    if not m:
        return text
    return m.group(0)


# --- Check: project-level user data root exists ---
if not root.exists():
    add_finding(
        "STR-001",
        "MUST_FIX",
        "missing_root",
        root,
        "Project-level user data root directory does not exist.",
        "Run init or upgrade to create the .claude/skills/pensieve base structure.",
    )

# --- Check: required category directories ---
for d in required_dirs:
    p = root / d
    if not p.is_dir():
        add_finding(
            "STR-002",
            "MUST_FIX",
            "missing_directory",
            p,
            f"Missing critical directory: {d}/",
            "Run upgrade to create the directory structure, then rerun doctor.",
        )

# --- Check: deprecated legacy paths ---
for p in legacy_project_paths + legacy_user_paths:
    # In plugin source repos, <project>/skills/pensieve can be the active system skill root.
    # Do not treat that specific path as deprecated user-data residue.
    if same_path(p, plugin_skill_root):
        continue
    if p.exists():
        add_finding(
            "STR-101",
            "MUST_FIX",
            "deprecated_path",
            p,
            "Deprecated legacy path co-exists with the active root directory.",
            "Run upgrade to migrate and remove the legacy path, converging to the .claude/skills/pensieve single root.",
        )

# --- Check: standalone legacy graph files ---
if root.is_dir():
    for pattern in legacy_graph_patterns:
        for matched in sorted(root.glob(pattern)):
            if not matched.is_file():
                continue
            add_finding(
                "STR-111",
                "MUST_FIX",
                "legacy_graph_file",
                matched,
                "Found standalone legacy graph file.",
                "Run upgrade to delete standalone graph files; the graph is only kept in SKILL.md#Graph.",
            )

# --- Check: legacy spec README copies in project subdirectories ---
for d in required_dirs:
    cat_dir = root / d
    if not cat_dir.is_dir():
        continue
    for item in sorted(cat_dir.iterdir()):
        if not item.is_file():
            continue
        if legacy_readme_re.match(item.name):
            add_finding(
                "STR-121",
                "MUST_FIX",
                "legacy_spec_readme_copy",
                item,
                "Found legacy spec README copy in project-level subdirectory.",
                "Run upgrade to delete the copy; the spec single source of truth is plugin-side <SYSTEM_SKILL_ROOT>/*/README.md.",
            )

# --- Check: critical seed files and content alignment ---
for target, template in critical_files:
    if not target.is_file():
        add_finding(
            "STR-201",
            "MUST_FIX",
            "missing_critical_file",
            target,
            "Missing critical seed file.",
            "Run upgrade to perform critical file alignment.",
        )
        continue
    if not template.is_file():
        add_finding(
            "STR-901",
            "MUST_FIX",
            "scanner_template_missing",
            template,
            "Scanner template file does not exist; cannot determine if critical file has drifted.",
            "Repair plugin installation or update to a complete version, then retry.",
        )
        continue
    if read_text_normalized(target) != read_text_normalized(template):
        add_finding(
            "STR-202",
            "MUST_FIX",
            "critical_file_drift",
            target,
            "Critical file content does not match the template.",
            "Run upgrade to back up and replace, restoring critical workflow files to match the template.",
        )

# --- Check: review pipeline referencing plugin-internal knowledge path ---
review_pipeline = root / "pipelines" / "run-when-reviewing-code.md"
if review_pipeline.is_file():
    txt = read_text_normalized(review_pipeline)
    if has_plugin_knowledge_path_reference(txt):
        add_finding(
            "STR-301",
            "MUST_FIX",
            "review_pipeline_path_drift",
            review_pipeline,
            "Review pipeline still references plugin-internal knowledge path.",
            "Run upgrade to switch references to project-level .claude/skills/pensieve/knowledge/... paths.",
        )

# --- Check: settings.json enabledPlugins keys ---
settings_paths = [home_dir / ".claude" / "settings.json", project_root / ".claude" / "settings.json"]
old_keys = ["pensieve@Pensieve", "pensieve@pensieve-claude-plugin"]
new_key = "pensieve@kingkongshot-marketplace"
new_key_enabled = False
old_key_hits: list[str] = []

for s in settings_paths:
    parsed, err = load_json(s)
    if err is not None:
        add_finding(
            "STR-401",
            "SHOULD_FIX",
            "settings_parse_error",
            s,
            f"settings.json parse failed; cannot fully verify enabledPlugins: {err}",
            "Fix settings.json syntax and retry.",
        )
        continue
    if parsed is None:
        continue
    enabled = parsed.get("enabledPlugins")
    if not isinstance(enabled, dict):
        continue
    if bool(enabled.get(new_key)):
        new_key_enabled = True
    for k in old_keys:
        if bool(enabled.get(k)):
            old_key_hits.append(f"{s}::{k}")

if old_key_hits:
    add_finding(
        "STR-402",
        "MUST_FIX",
        "legacy_enabled_plugins_key",
        "; ".join(old_key_hits),
        "enabledPlugins still has legacy plugin keys enabled.",
        "Run upgrade to clean legacy keys; keep only pensieve@kingkongshot-marketplace.",
    )

if not new_key_enabled:
    add_finding(
        "STR-403",
        "MUST_FIX",
        "missing_enabled_plugins_key",
        "<user|project>/.claude/settings.json",
        "enabledPlugins is missing the new plugin key or it is not enabled.",
        "Run upgrade to write pensieve@kingkongshot-marketplace: true.",
    )

# --- Check: MEMORY.md Pensieve guidance block ---
system_skill_description = load_system_skill_description(system_skill_file)
if system_skill_description is None:
    add_finding(
        "STR-901",
        "MUST_FIX",
        "scanner_template_missing",
        system_skill_file,
        "System skill description is missing from the scanner; cannot verify the MEMORY.md Pensieve guidance block.",
        "Repair plugin installation or update to a complete version, then retry.",
    )
else:
    if not memory_file.is_file():
        add_finding(
            "STR-501",
            "MUST_FIX",
            "missing_memory_file",
            memory_file,
            "Missing Claude Code auto memory entry MEMORY.md.",
            "Run init/upgrade/doctor to trigger auto memory creation, or write the Pensieve guidance block to ~/.claude/projects/<project>/memory/MEMORY.md.",
        )
    else:
        memory_text = read_text_normalized(memory_file)
        memory_block = extract_pensieve_memory_block(memory_text)
        if system_skill_description not in memory_block or memory_guidance_line not in memory_block:
            add_finding(
                "STR-502",
                "MUST_FIX",
                "memory_content_drift",
                memory_file,
                "MEMORY.md is missing the Pensieve description or content is not aligned with the system skill description.",
                "Run init/upgrade/doctor to trigger auto memory alignment, ensuring ~/.claude/projects/<project>/memory/MEMORY.md matches the skill description and includes the pensieve skill guidance.",
            )

# --- Summary ---
must_fix = sum(1 for f in findings if f.severity == "MUST_FIX")
should_fix = sum(1 for f in findings if f.severity == "SHOULD_FIX")
status = "aligned" if must_fix == 0 else "drift"

flags = {
    "has_missing_root": any(f.finding_id == "STR-001" for f in findings),
    "has_missing_directories": any(f.finding_id == "STR-002" for f in findings),
    "has_deprecated_paths": any(f.finding_id == "STR-101" for f in findings),
    "has_legacy_graph_files": any(f.finding_id == "STR-111" for f in findings),
    "has_legacy_spec_readme_copies": any(f.finding_id == "STR-121" for f in findings),
    "has_missing_critical_files": any(f.finding_id == "STR-201" for f in findings),
    "has_critical_file_drift": any(f.finding_id == "STR-202" for f in findings),
    "has_review_pipeline_path_drift": any(f.finding_id == "STR-301" for f in findings),
    "has_settings_parse_errors": any(f.finding_id == "STR-401" for f in findings),
    "has_legacy_enabled_plugins_key": any(f.finding_id == "STR-402" for f in findings),
    "has_missing_new_enabled_plugins_key": any(f.finding_id == "STR-403" for f in findings),
    "has_missing_memory_file": any(f.finding_id == "STR-501" for f in findings),
    "has_memory_content_drift": any(f.finding_id == "STR-502" for f in findings),
}

report = {
    "generated_at_utc": generated_at,
    "status": status,
    "root": str(root),
    "project_root": str(project_root),
    "plugin_root": str(plugin_root),
    "auto_memory_file": str(memory_file),
    "summary": {
        "must_fix_count": must_fix,
        "should_fix_count": should_fix,
        "total_findings": len(findings),
    },
    "flags": flags,
    "findings": [f.as_dict() for f in findings],
}


def render_text(data: dict) -> str:
    lines: list[str] = []
    lines.append("# Pensieve Structure Scan")
    lines.append("")
    lines.append(f"- status: `{data['status']}`")
    lines.append(f"- generated_at_utc: `{data['generated_at_utc']}`")
    lines.append(f"- root: `{data['root']}`")
    lines.append(f"- must_fix: `{data['summary']['must_fix_count']}`")
    lines.append(f"- should_fix: `{data['summary']['should_fix_count']}`")
    lines.append("")
    lines.append("## Findings")
    if not data["findings"]:
        lines.append("- none")
        return "\n".join(lines) + "\n"
    for item in data["findings"]:
        lines.append(
            f"- [{item['severity']}] {item['id']} | {item['category']} | `{item['path']}` | {item['message']}"
        )
    return "\n".join(lines) + "\n"


if fmt == "json":
    out = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
else:
    out = render_text(report)

if output == "-":
    sys.stdout.write(out)
else:
    Path(output).write_text(out, encoding="utf-8")

if fail_on_drift and must_fix > 0:
    sys.exit(3)
PY
