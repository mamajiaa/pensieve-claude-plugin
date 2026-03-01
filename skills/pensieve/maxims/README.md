# Maxims

Long-term action principles that apply across projects, scenarios, and contexts.

## Purpose

A maxim is not a technical detail, but an abstraction of the team's "default behavior":

- Cross-project: not dependent on a single repository
- Cross-problem: still guides decisions when facing unknown problems
- Transferable: a newcomer can act on it after reading

The value of a maxim is to **reduce decision cost** -- avoiding re-derivation from scratch every time.

> Note: The plugin ships no built-in maxim files. During install/migration, initial maxims are seeded into `.claude/skills/pensieve/maxims/` and users can freely edit them.

## Semantic Positioning (MUST Layer)

`maxim` carries MUST (constraint layer): non-negotiable bottom lines and behavioral constraints -- i.e., "this must be done."

Key criteria:
- Violating it significantly increases regression risk or breaks the collaboration baseline
- Not a one-off project preference (that is `decision`)
- Not an objective mechanism description (that is `knowledge`)

## Capture Criteria

### Self-Check

All of the following must be "yes" for content to qualify as a maxim:

1. **Project-agnostic**: still holds in a different project?
2. **Language-agnostic**: still holds in a different language?
3. **Domain-agnostic**: still holds in a different technical domain?
4. **Future-guiding**: still provides guidance for unknown problems?
5. **Expressible in one sentence**: can be stated clearly and acted upon?

Any "no" -> more appropriate as a `decision`, not a `maxim`.

## Relationships & Evolution

| Direction | Description |
|-----------|-------------|
| Decision -> Maxim | Repeatedly occurring decisions can be elevated into maxims |
| Maxim <-> Knowledge | Maxims can absorb external best practices |

## Writing Guide

### Directory Structure (Project Level)

```
.claude/skills/pensieve/maxims/
├── {maxim-conclusion-a}.md
└── {maxim-conclusion-b}.md
```

Notes:
- No `custom.md` index file required.
- Each maxim is a standalone file.

### Single Maxim File Format (Recommended)

Each maxim should include:
- **Title**: one-sentence conclusion
- **One-line conclusion**: a clear, directly actionable statement
- **Guiding rules / boundaries**: when it applies and when it does not

```markdown
# {One-Sentence Conclusion}

## One-Line Conclusion
> {A directly actionable one-liner for the team}

## Guiding Rules
- Rule 1
- Rule 2

## Boundaries
- Does not apply when...

## Context Links (Recommended)
- Based on: [[related decision or knowledge]]
- Leads to: [[related pipeline or subsequent decision]]
- Related: [[related maxim]]
```

### Conflict Resolution (Index-Free Mode)

When two maxims conflict, resolve in this order:

1. The maxim with the more specific scenario takes priority over the more abstract one
2. The maxim with clear `decision`/`knowledge` traceability evidence takes priority
3. If still in conflict, add a `decision` to explicitly state the current project's priority

### Example

```markdown
# Preserve user-visible behavior as a hard rule

## One-Line Conclusion
> Any unexpected change to user-visible behavior should be treated as a defect.

## Guiding Rules
- Keep user-visible behavior stable during refactoring.
- If behavior must change, it must be explicitly stated and reviewed.

## Boundaries
- Behavior changes are allowed only when the user has explicitly approved the change.
```

## Notes

- Maxims should be **scarce** -- do not add frequently
- If a maxim is frequently rewritten, the abstraction level may be wrong
- Links are recommended (not mandatory), but preserving provenance is encouraged

Recommended traceability format:

```markdown
Derived from: [[2026-01-22-do-not-break-user-visible-behavior]], [[knowledge/taste-review/content]]
```

---

## Maxim File Location

- Project-level entries: `.claude/skills/pensieve/maxims/*.md` (never overwritten)
