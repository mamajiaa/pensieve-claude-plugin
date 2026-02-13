---
id: run-when-reviewing-code
type: pipeline
title: Code Review Pipeline
status: active
created: 2026-02-11
updated: 2026-02-11
tags: [pensieve, pipeline, review]
name: run-when-reviewing-code
description: Run when a code review is requested. Trigger words: review / code review / check code.
stages: [tasks]
gate: auto
---

# Code Review Pipeline

This pipeline focuses on orchestration only. Keep theory and deeper criteria in linked knowledge files.

**Knowledge reference**: `.claude/pensieve/knowledge/taste-review/content.md`

**Context links (at least one)**:
- Based on: [[knowledge/taste-review/content]]
- Leads to: [[decisions/2026-xx-xx-review-policy]]
- Related: [[decisions/2026-xx-xx-review-strategy]]

---

## Task Blueprint (Create in order)

### Task 1: Prepare Review Context

**Goal**: Clarify boundaries and avoid scope misses.

**Read Inputs**:
1. User-provided files / commits / PR scope
2. `.claude/pensieve/knowledge/taste-review/content.md`

**Steps**:
1. Confirm review scope (files / commits / snippets)
2. Identify technical/business constraints and risk points
3. Output a prioritized review file list

**Done When**: Scope is clear and review file list is executable.

---

### Task 2: Review Files and Capture Evidence

**Goal**: Produce per-file conclusions with evidence.

**Read Inputs**:
1. Review file list from Task 1
2. `.claude/pensieve/knowledge/taste-review/content.md`

**Steps**:
1. Apply checklist to each file (no duplicated theory here)
2. Record severity: PASS / WARNING / CRITICAL
3. Cite exact code locations for WARNING/CRITICAL
4. Record user-visible behavior change risk (if any)

**Done When**: Each file has evidence-backed conclusions and locatable high-risk issues.

---

### Task 3: Produce Actionable Report

**Goal**: Deliver actionable fixes and clear priority.

**Read Inputs**:
1. Review notes from Task 2

**Steps**:
1. Summarize key issues by severity
2. Provide concrete fix suggestions or rewrite options
3. Call out user-visible behavior and regression risks
4. Recommend fix order (CRITICAL first, then WARNING)

**Done When**: Report includes findings, evidence, fix suggestions, and clear priority.

---

### Task 4: Capture Reusable Outcomes (Optional)

**Goal**: Convert reusable outcomes into existing four categories.

**Read Inputs**:
1. Report from Task 3

**Steps**:
1. If outcome is project choice, capture in `decision`
2. If outcome is general external method, capture in `knowledge`
3. Add at least one `Based on/Leads to/Related` link (required for decision)
4. If no reusable output, explicitly record "no capture"

**Done When**: Capture result is explicit (written or explicitly skipped).

---

## Execution Rules (for loop)

1. Create tasks strictly in order: Task 1 -> Task 2 -> Task 3 -> Task 4.
2. Keep default 1:1 mapping; do not merge or skip tasks.
3. If context is missing, fill it inside current task instead of adding extra phase.
