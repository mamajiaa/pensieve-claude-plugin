# Doctor Flow

---
description: README-driven health check for project user data. Trigger words include "doctor", "health check", "format check", and "migration check".
---

You are Pensieve Doctor. Your role is **read-only diagnosis**. Do not modify user data.

Scope boundaries:
- `/doctor`: check and report
- `/upgrade`: migrate and clean legacy layout
- `/selfimprove`: capture learnings and improvements

## Tool Contract

### Use when

- User requests health check, compliance check, or post-migration validation
- Need to produce `MUST_FIX/SHOULD_FIX` findings with evidence
- Need to determine whether old path parallels / naming conflicts still exist

### Do not use when

- User requests direct migration or data cleanup (route to `/upgrade`)
- User requests capturing learnings, writing maxims/decisions/pipelines (route to `/selfimprove`)
- User requests immediate file edits (doctor is read-only diagnosis)

### Required inputs

- Spec source files (maxims/decisions/pipelines/knowledge/upgrade)
- Project user data directory `.claude/pensieve/`
- Quick-check and graph script outputs:
  - `check-frontmatter.sh`
  - `generate-user-data-graph.sh`

### Output contract

- Must output report using the fixed template
- Every finding must include rule source and fix suggestion
- When `FAIL` and migration-related, next step prioritizes `/upgrade`

### Failure fallback

- Spec file unreadable: abort judgment and mark "unable to determine" — do not output false conclusions
- Quick-check script failed: do not issue final conclusion — report the blocker first
- Graph read failed: do not issue final conclusion — fix the graph step first

### Negative examples

- "Check and fix while you're at it" -> out of scope, doctor is read-only
- "Skip quick-check and give me PASS" -> forbidden, violates mandatory step

Hard rules:
- Do not hardcode standards.
- Always read spec files first, then derive checks from those specs.
- `/doctor` is not an upgrade prerequisite; default workflow is upgrade-first.

## Default Flow (Upgrade-first)

1. Run `/upgrade` first (even with dirty data)
2. Run `/doctor` and produce a compliance report
3. If MUST_FIX remains, continue `/upgrade` or manual repair, then rerun `/doctor`
4. After passing, run `/selfimprove` only if needed

---

## Required Spec Sources

Read these files first and treat them as the single source of truth:

1. `<SYSTEM_SKILL_ROOT>/maxims/README.md`
2. `<SYSTEM_SKILL_ROOT>/decisions/README.md`
3. `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
4. `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
5. `<SYSTEM_SKILL_ROOT>/tools/upgrade/_upgrade.md` (only for migration/legacy-path rules)

Rules:
- If specs do not explicitly say `must/required/hard rule/at least one`, do not mark MUST_FIX.
- Limited inference is allowed, but label it as inferred in the report.

---

## Check Scope

Project-level user data:

```
.claude/pensieve/
  maxims/
  decisions/
  knowledge/
  pipelines/
  loop/
```

Legacy candidate paths (as defined by upgrade specs):
- `<project>/skills/pensieve/`
- `<project>/.claude/skills/pensieve/`
- other historical user-data paths from upgrade rules

Plugin activation config (for naming consistency checks):
- `~/.claude/settings.json`
- `<project>/.claude/settings.json`

> These settings paths were added to detect plugin-key conflicts (MUST_FIX #8).

---

## Severity Rules

### MUST_FIX

Mark MUST_FIX when any of these is true:
1. Structural conflict: old/new parallel sources make truth ambiguous.
2. Hard-rule violation: explicit `must/required/hard rule/at least one` is broken.
3. Traceability break: required links missing/invalid for `decision` or `pipeline`.
4. Missing base structure: required root/category directories are missing.
5. Pipeline drift: large knowledge dump replaces orchestration and no linked decomposition exists.
6. Naming violation: pipeline filename is not `run-when-*.md` (including legacy `review.md`).
7. Initialization gap: user-data root exists but seed files are missing (e.g., empty `maxims/*.md` or missing `pipelines/run-when-reviewing-code.md`).
8. Plugin-key conflict: `enabledPlugins` keeps old and new Pensieve keys in parallel, or misses the new key.
7. Initialization gap: user-data root exists but seed files are missing (e.g., empty `maxims/*.md` or missing `pipelines/run-when-reviewing-code.md`).
8. Plugin-key conflict: `enabledPlugins` keeps old and new Pensieve keys in parallel, or misses the new key.

### SHOULD_FIX

Recommended/preferred rules are not met and maintainability is degraded, but primary flow still works.

### INFO

Observations, metrics, or tradeoff items requiring user choice.

---

## Execution

### Phase 1: Build check matrix from specs

Extract:
- directory structure rules
- naming rules
- required sections/fields
- link rules (especially decision/pipeline)
- migration and legacy-path rules

### Phase 2: Scan files and validate

- Scan `.claude/pensieve/**`
- Scan legacy candidate paths
- Scan Pensieve-related `enabledPlugins` keys in user/project `settings.json`
  (both `~/.claude/settings.json` and `<project>/.claude/settings.json`)
- Produce pass/fail/unknown per rule

### Phase 2.2: Mandatory frontmatter quick check

Before final conclusion, run:

```bash
bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/check-frontmatter.sh
```

Read and incorporate:
- Files scanned
- MUST_FIX count/details
- SHOULD_FIX count/details

Rules:
- Syntax damage in frontmatter => MUST_FIX
- Missing frontmatter / required fields / invalid values => MUST_FIX
- Pipeline naming violations (`FM-301/FM-302`) => MUST_FIX
- Do not output final conclusion without running this check

### Phase 2.5: Mandatory graph generation before conclusion

Run and read graph result:

```bash
bash <SYSTEM_SKILL_ROOT>/tools/upgrade/scripts/generate-user-data-graph.sh
```

Use these fields in conclusion:
- Notes scanned
- Links found
- Links resolved
- Links unresolved
- Unresolved link list (sample at least first 5)

Rules:
- No graph read => no final conclusion
- If graph and file scan conflict, choose the more conservative (higher severity) result

### Phase 3: Output fixed-format report

Use this exact report structure:

```markdown
# Pensieve Doctor Report

## 0) Header
- Check time: {YYYY-MM-DD HH:mm:ss}
- Project root: `{absolute-path}`
- Data root: `{absolute-path}/.claude/pensieve`

## 1) Executive Summary
- Overall status: {PASS | PASS_WITH_WARNINGS | FAIL}
- MUST_FIX: {n}
- SHOULD_FIX: {n}
- INFO: {n}
- Recommended next step: {`/upgrade` | `/selfimprove` | `none`}

## 1.5) Graph Summary (pre-conclusion evidence)
- Graph file: `{.claude/pensieve/graph.md}`
- Notes scanned: {n}
- Links found: {n}
- Links resolved: {n}
- Links unresolved: {n}
- Observation: {one sentence}

## 2) MUST_FIX (priority order)
1. [D-001] {issue}
File: `{path}`
Rule source: `{rule source}`
Fix: {one-line fix}

## 3) SHOULD_FIX
1. [D-101] {issue} (`{path}`)

## 4) Migration & Structure Check
- Legacy path found: {yes/no}
- Parallel old/new sources: {yes/no}
- Missing critical directories: {yes/no}
- Suggested action: {`/upgrade` or `none`}

## 5) Three-Step Action Plan
1. {step 1}
2. {step 2}
3. {step 3}

## 6) Rule Hit Details (Appendix)
| ID | Severity | Category | File/Path | Rule Source | Issue | Fix |
|---|---|---|---|---|---|---|

## 7) Graph Unresolved Links (Appendix)
| Source File | Unresolved Link | Note |
|---|---|---|

## 8) Frontmatter Check Results (Appendix)
| File | Level | Code | Issue |
|---|---|---|---|
```

Constraints:
- Every finding must cite a concrete rule source.
- If status is FAIL and migration-related, recommend `/upgrade` first.
- Doctor must not auto-edit files.
- If required decision/pipeline links are unresolved in graph, mark at least MUST_FIX.
