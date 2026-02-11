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

## Linking Rule (Required for Pipelines)

Every pipeline should include at least one explicit link in its body so readers can trace why the flow exists.

Recommended fields:
- `基于`：which decision/knowledge this pipeline depends on
- `导致`：which outputs/follow-up workflows this pipeline triggers
- `相关`：nearby pipelines or references

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
├── {name}.md
```

### Naming Convention

| Prefix | Type | Notes |
|--------|------|------|
| `_` | discouraged | plugin no longer ships pipelines |
| none | user‑defined | project/business workflows, e.g. `review.md` |

### File Format

```markdown
# Pipeline 名称

---
description: Short summary. Triggered when user says "trigger1", "trigger2".
---

Role: You are [doing what]...

## 核心原则

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

### Task 3: Capture Durable Conclusion (Optional)

**Goal**: Preserve reusable conclusions from this run

**Read Inputs**:
1. Previous task outputs

**Steps**:
1. If the conclusion is a project choice, capture/update a `decision`
2. If the conclusion is external/reference knowledge, capture/update `knowledge`
3. Add links using `基于/导致/相关`
4. If no durable conclusion exists, record \"no capture\"

**Done When**: Capture result is explicit (written or skipped with reason)

---

## 相关文件

- `path/to/file` — description
```

### Format Checklist

| Element | Notes |
|---------|------|
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
| Links | Pipeline body should include at least one meaningful link |

### Example

```markdown
# 代码审查 Pipeline

---
description: Code review flow. Triggered by "review code", "review", "check this change".
---

你正在进行系统性的代码审查，在彻底性与务实性之间平衡。

## 核心原则

- **Evidence‑based**: Every issue must cite specific code
- **Severity‑aware**: Distinguish critical bugs from nitpicks
- **Actionable**: Provide concrete fix suggestions

---

## Task Blueprint

### Task 1: 理解变更范围

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

### Task 2: 系统化审查

**Goal**: 逐文件对照审查标准

**Read Inputs**:
1. Task 1 output file list
2. `knowledge/taste-review/content.md`

**CRITICAL**：每个 WARNING/CRITICAL 必须引用具体行号。

**Steps**:
1. Apply the checklist from knowledge (no extra theory here)
2. Record findings with severity: PASS / WARNING / CRITICAL
3. Track user-visible behavior change risk

**Done When**: Each file has evidence-backed conclusion

---

### Task 3: 报告

**Goal**: Deliver an actionable review summary

**Read Inputs**:
1. Task 2 findings

**Steps**:
1. 按严重性汇总发现
2. 给出整体评估和修复建议
3. **向用户呈现报告并等待确认**

**Done When**: Report includes all findings and prioritized fixes

---

## 相关文件

- `knowledge/taste-review/` — 审查标准与清单
```

## Notes

- Pipelines must **fit the project** — there is no universal best pipeline
- Early projects: simple pipelines, loose validation
- Mature projects: refined pipelines, strict validation
- Improvements come from real execution feedback, not speculation
