# Pipelines

Executable workflows that define a full loop from input to validation.

> Note: Built‑in tools were moved to `tools/`; the plugin no longer ships pipelines. Initial pipelines are seeded at install/migration into `.claude/pensieve/pipelines/` and are user‑editable.

## Purpose

Pipelines exist to **build verifiable execution loops and deterministic task blueprints**.

**Pipelines orchestrate flow — they do not aggregate information.**  
All background information should live elsewhere and be **referenced**:

- **Knowledge**: external references, checklists, best practices
- **Maxims**: universal principles and values
- **Decisions**: context‑specific choices and rationale
- **External skills/tools**: heavy instructions or specialized workflows

A pipeline is not a checklist; it's a closed‑loop system that matches how LLMs work:

```
Input → Execute → Validate → Output
         ↑      ↓
         └── Feedback ──┘
```

### What makes a good pipeline

| Trait | Why it matters (LLM view) |
|-------|----------------------------|
| **Closed loop** | LLMs drift; they need a clear start and end |
| **Real signals** | Validate via actual outputs, not code inference |
| **File‑based logs** | Traceable; errors map to concrete steps |
| **Testable** | Verifies correctness without "feelings" |
| **Tool‑friendly** | Identify steps where tools remove uncertainty |

### Validation must be based on real feedback

**Anti‑pattern**: read code → "seems correct" → continue

**Correct**: execute code → get real output → read output → validate

| Validation type | Real feedback source |
|-----------------|----------------------|
| Build | Compiler output, build logs |
| Tests | Test results, coverage reports |
| Runtime | App logs, error stacks |
| Integration | API responses, DB state |

**Key**: Use real runtime feedback, not model inference. Systems don't lie; model inference does.

## Capture Criteria

Ask yourself: **If this workflow isn't solidified, what decisions will be repeated?**

### Do we need a new pipeline?

**First ask**: Can we solve this by composing existing pipelines?

| Situation | Action |
|-----------|--------|
| Existing pipeline combo works | Re‑order/compose; do not add |
| Missing a validation step | Add to an existing pipeline |
| Entirely different execution loop | Create a new pipeline |

### Signals that it's worth capturing

| Signal | Explanation |
|--------|-------------|
| Multiple loops share similar task structure | Steps stabilized; extract a pipeline |
| A step is repeatedly missed | Use a pipeline to enforce completeness |
| Execution depends on multiple knowledge sources | Pipeline should stitch them together |

### Evolution path

```
Reach baseline → refine (tools, sequencing)
```

1. **Baseline**: It runs, with basic validation—even if manual
2. **Tooling**: Turn repeated/fragile steps into tools
3. **Sequencing**: Reorder steps to reduce backtracking

**Anti‑pattern**: Perfectionism up front; optimizing before it ever runs.

## Relationships & Evolution

| Direction | Description |
|-----------|-------------|
| Pipeline ← Knowledge | External standards guide execution |
| Pipeline → Tasks | Pipeline defines the loop; tasks are concrete actions |
| Pipeline ↔ Decision | Decisions formed during execution can refine pipelines |

### Pipeline vs Tasks

| Type | Essence | Focus |
|------|---------|-------|
| Pipeline | Task blueprint + validation loop | "What to create and in which order" |
| Tasks | Runtime instances | "Execute this specific step now" |

Pipelines should directly provide task templates; runtime tasks are instantiated from that template.

## Writing Guide

### Directory Structure

```
.claude/pensieve/pipelines/
├── run-when-*.md
```

### Naming Convention

Hard rules:
- pipeline filenames must use the invocation-intent pattern: `run-when-*.md`
- legacy names are not kept for compatibility (`review.md` must be renamed)

| Pattern | Type | Notes |
|--------|------|------|
| `run-when-*.md` | user-defined | filename should reveal when to call it |
| `_*.md` | forbidden | reserved for legacy system naming |

### File Format

```markdown
# Pipeline Name

---
id: run-when-xxx
type: pipeline
title: Pipeline Name
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [pensieve, pipeline]
description: Short summary. Triggered when user says "trigger1", "trigger2".
---

Role: You are [doing what]...

## Core Principles

- **Principle 1**: short, operational
- **Principle 2**: short, operational

---

## Task Blueprint

### Task 1: Task Name

**Goal**: What this task should achieve

**Read Inputs**:
1. Required file/path
2. Required file/path

**Steps**:
1. Specific action
2. Specific action

**Done When**: Objective completion criteria

---

### Task 2: Task Name

**Goal**: What this task should achieve

**Read Inputs**:
1. Previous task output

**CRITICAL**: Key warning (if any)

**Steps**:
1. Specific action
2. **Present to user and wait for confirmation**

**Done When**: Objective completion criteria

---

## Related Files

- `path/to/file` — description
```

### Format Checklist

| Element | Notes |
|---------|------|
| Filename | Must match `run-when-*.md` and indicate invocation intent |
| Required frontmatter | `id/type/title/status/created/updated/tags/description` |
| `description` | In frontmatter; include trigger words |
| Role line | Starts with "You are..." and defines Claude's role |
| Core Principles | 1–3 short operational rules |
| No knowledge dump | Long background belongs in Knowledge/Maxims/Decisions/Skills |
| Task Blueprint | Must include explicit `Task 1/2/3...` in order |
| **Goal** | Every task must have a goal |
| **Read Inputs** | Required files/paths must be explicit |
| **Steps** | Numbered, concrete steps |
| **Done When** | Completion criteria must be testable |
| **CRITICAL** / **DO NOT SKIP** | Strong markers for key steps |
| User confirmation | Explicit "Wait for confirmation" |

### Example

```markdown
# Review Pipeline

---
description: Code review flow. Triggered by "review code", "review", "check this change".
---

You are conducting a systematic code review, balancing thoroughness with pragmatism.

## Core Principles

- **Evidence‑based**: Every issue must cite specific code
- **Severity‑aware**: Distinguish critical bugs from nitpicks
- **Actionable**: Provide concrete fix suggestions

---

## Task Blueprint

### Task 1: Understand Changes

**Goal**: Get a complete picture of what changed

**Read Inputs**:
1. User-provided diff/commit/PR scope
2. `knowledge/taste-review/content.md`

**Steps**:
1. Read the diff or specified commits
2. List all modified files
3. Identify scope (feature, refactor, bugfix, etc.)

**Done When**: Can list all modified files and change types

---

### Task 2: Systematic Review

**Goal**: Check each file against review criteria

**Read Inputs**:
1. Task 1 output file list
2. `knowledge/taste-review/content.md`

**CRITICAL**: Every WARNING/CRITICAL must cite specific line numbers.

**Steps**:
1. Apply the checklist from knowledge (no extra theory here)
2. Record findings with severity: PASS / WARNING / CRITICAL
3. Track user-visible behavior change risk

**Done When**: Each file has evidence-backed conclusion

---

### Task 3: Report

**Goal**: Deliver an actionable review summary

**Read Inputs**:
1. Task 2 findings

**Steps**:
1. Summarize findings by severity
2. Provide overall assessment and concrete fix suggestions
3. **Present the report to the user and wait for confirmation**

**Done When**: Report includes all findings and prioritized fixes

---

## Related Files

- `knowledge/taste-review/` — Review criteria and checklist
```

## Notes

- Pipelines must **fit the project** — there is no universal best pipeline
- Early projects: simple pipelines, loose validation
- Mature projects: refined pipelines, strict validation
- Improvements come from real execution feedback, not speculation
