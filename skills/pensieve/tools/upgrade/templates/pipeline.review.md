---
name: review
description: |
  Code review pipeline. Based on Linus Torvalds' taste philosophy, John Ousterhout's design principles, and Google Code Review standards.

  Use this pipeline when:
  - The user requests a code review
  - The user says "review", "code review", or "check my code"
  - You need to assess code quality or design decisions

  Examples:
  <example>
  User: "Review this code for me"
  -> trigger this pipeline
  </example>
  <example>
  User: "Check this PR"
  -> trigger this pipeline
  </example>

signals: ["review", "code review", "check code", "code quality"]
stages: [tasks]
gate: auto
---

# Code Review Pipeline

This pipeline maps code review directly into an executable task list. All criteria and deeper rationale live in Knowledge.

**Knowledge reference**: `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

---

## Task Blueprint (Create in order)

### Task 1: Prepare Review Context

**Goal**: Clarify review boundaries and avoid missing scope

**Read Inputs**:
1. User-provided files / commits / PR scope
2. `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

**Steps**:
1. Confirm review scope (files / commits / snippets)
2. Identify technical constraints, business constraints, and risk points
3. Output a prioritized review file list

**Done When**: Scope is clear and the review file list is executable

---

### Task 2: Review Files and Capture Evidence

**Goal**: Produce per-file conclusions against a unified standard

**Read Inputs**:
1. Review file list from Task 1
2. `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

**Steps**:
1. Apply the review checklist to each file (do not repeat theory here)
2. Record results with severity: PASS / WARNING / CRITICAL
3. Cite exact code locations for each WARNING/CRITICAL
4. Record user-visible behavior change risks (if any)

**Done When**: Each file has evidence-backed conclusions and high-risk issues are locatable

---

### Task 3: Produce Actionable Review Report

**Goal**: Deliver actionable fixes and clear priority

**Read Inputs**:
1. Review notes from Task 2

**Steps**:
1. Summarize key issues by severity
2. Provide concrete fix suggestions or rewrite options
3. Explicitly call out user-visible behavior and regression risks
4. Provide recommended fix order (CRITICAL first, then WARNING)

**Done When**: Report includes findings, evidence, fix suggestions, and clear priority

---

## Execution Rules (for loop)

1. When this pipeline is selected, create tasks in Task 1 -> Task 2 -> Task 3 order.
2. Default to a 1:1 mapping. Do not merge or skip tasks.
3. If information is missing, fill it inside the current mapped task instead of creating extra phases.
