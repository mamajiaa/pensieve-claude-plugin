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
.claude/pensieve/maxims/custom.md
```

### File Format

Each maxim includes:
- **Title line**: maxim name + core quote
- **Expanded points**: guidance, examples, boundaries

```markdown
1. "Maxim Name" - Label "Core quote"

Classic example: XXX
Guidance point
Guidance point
Boundary note
```

### Example

```markdown
1. "Good Taste" — Your first maxim: "Rewrite it so the special case goes away and becomes the normal case."

Classic example: linked‑list deletion — reduce 10 lines with ifs to 4 lines without conditionals
Eliminate edge cases rather than adding conditionals
Good taste is intuition built from experience

2. "Never break userspace" — Your iron rule: "We do not break user‑visible behavior!"

Any code that unexpectedly changes user‑visible behavior is a bug
The kernel serves users, it does not educate them
```

## Notes

- Maxims are **scarce** — do not add frequently
- When adding, consider insertion position (it indicates priority)
- Once established, maxims should rarely change — frequent edits imply weak abstraction

---

## Maxim Files

- Project‑level custom: `.claude/pensieve/maxims/custom.md` (never overwritten)
