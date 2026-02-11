# Maxims

Universal guiding principles that apply across projects and contexts.

## Purpose

Maxims are **character**, not technical details:

- Cross‑project: not tied to a specific stack
- Cross‑problem: guide unknown future problems
- Transcendent: abstract enough to apply broadly

Maxims exist to **reduce decision cost**. When facing new problems, they provide direction without re‑deriving from scratch.

> **Note**: The plugin ships no maxim files. Install/migration seeds initial maxims in `.claude/pensieve/maxims/` that users can freely edit.

## Capture Criteria

### Self‑check

All must be "yes" to qualify as a maxim:

1. **Project‑agnostic**: Would this still apply in a different project?
2. **Language‑agnostic**: Would this still apply in a different language?
3. **Domain‑agnostic**: Would this still apply in a different technical domain?
4. **Future‑guiding**: Would it guide decisions for unknown problems?
5. **Sayable**: Can it be expressed clearly in one sentence?

Any "no" → capture as a decision, not a maxim.

### Writing Philosophy (Wittgenstein)

- **The limits of my language mean the limits of my world** — maxims must be precise
- **Whereof one cannot speak, thereof one must be silent** — don’t capture what you cannot express clearly
- **Meaning is use** — the value of a maxim is whether it guides action

## Relationships & Evolution

| Direction | Description |
|-----------|-------------|
| Decision → Maxim | Repeated decisions → distilled into maxims |
| Maxim ↔ Knowledge | Maxims can internalize external best practices |

**Order equals priority**: Maxims are ordered top‑to‑bottom; when they conflict, earlier ones win.

## Writing Guide

### Directory Structure (Project Level)

```
.claude/pensieve/maxims/
├── custom.md                     # Index + priority order
├── {maxim-conclusion-a}.md       # One maxim per file
└── {maxim-conclusion-b}.md
```

### Index File (`custom.md`)

Use `custom.md` as an index, not as the full content container:

```markdown
# Maxims Index

## Priority Order
1. [[eliminate-special-cases-by-redesigning-data-flow]]
2. [[preserve-user-visible-behavior-as-a-hard-rule]]
3. [[prefer-pragmatic-solutions-over-theoretical-completeness]]

## Notes
- Earlier items have higher priority when maxims conflict.
```

### Maxim File Format (one file per maxim)

Each maxim includes:
- **Title**: one-sentence conclusion
- **One-line conclusion**: explicit, testable statement
- **Guidance / boundaries**: operational rules and limits

```markdown
# {One-sentence conclusion}

## One-line Conclusion
> {One sentence that the team can apply directly}

## Guidance
- Rule 1
- Rule 2

## Boundaries
- This does not apply when...

## 上下文链接（recommended）
- 基于：[[相关 decision 或 knowledge]]
- 导致：[[相关 pipeline 或后续 decision]]
- 相关：[[相关 maxim]]
```

### Example

```markdown
# Preserve user-visible behavior as a hard rule

## One-line Conclusion
> Any unexpected user-visible behavior change is treated as a bug.

## Guidance
- Keep existing user-facing behavior stable during refactors.
- If behavior must change, make it explicit and reviewed.

## Boundaries
- Expected behavior changes are allowed only with explicit user approval.
```

## Notes

- Maxims are **scarce** — do not add frequently
- When adding, consider insertion position (it indicates priority)
- Once established, maxims should rarely change — frequent edits imply weak abstraction
- Linking is recommended (not required): when useful, show which decisions/knowledge items the maxim comes from

Recommended trace format:

```markdown
Derived from: [[2026-01-22-do-not-break-user-visible-behavior]], [[knowledge/taste-review/content]]
```

---

## Maxim Files

- Project‑level index: `.claude/pensieve/maxims/custom.md` (never overwritten)
- Project‑level maxim notes: `.claude/pensieve/maxims/*.md` (never overwritten)
