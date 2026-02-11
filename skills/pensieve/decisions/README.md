# Decisions

Historical choices made in specific situations. Capture: "In X context, we chose Y because Z."

## Purpose

Decisions exist to **avoid repeating mistakes**.

Recording past choices and reasons ensures that when similar situations arise:
- You know what was chosen
- You know why it was chosen
- You know why alternatives were rejected

## Capture Criteria

### Core Standard

> A decision belongs in global decisions/ only if it clearly reduces future regression risk, improves readability or collaboration, and can be taught as a "simple, testable, reusable pattern."

### Three Golden Questions

1. **If we delete this, will we be more likely to make mistakes later?**
2. **Would someone three months later make a better choice after reading it?**
3. **Can it be taught as a reusable pattern?**

Any clear "yes" → worth capturing  
All "uncertain" → keep in loop directory

### Five Value Dimensions

| Dimension | Question |
|----------|----------|
| Long‑term impact | Does it reduce a class of bugs? |
| Readability | Does it create a transferable taste rule? |
| Locality | Does it define module boundaries or responsibilities? |
| Collaboration signal | Was it explicitly decided by the user or repeatedly confirmed? |
| Noise check | The three golden questions above |

## Relationships & Evolution

| Direction | Description |
|-----------|-------------|
| Decision → Maxim | Repeated decisions → distilled into maxims |
| Knowledge → Decision | External knowledge + project practice → decisions |
| Loop → Decision | Temporary loop decisions → filtered and promoted |

### Storage Locations

| Stage | Location | Notes |
|-------|----------|-------|
| During loop | `.claude/pensieve/loop/{name}/_decisions/` | Temporary; tied to loop lifecycle |
| After loop | `.claude/pensieve/decisions/` | Project user data (never overwritten) |

### Decision Levels

| Level | Characteristics | Scope |
|-------|-----------------|-------|
| Hard rule | Violating it causes regressions | Cross‑project universal |
| Coding taste | Reduces special cases; easier to reason | Implementation guidance |
| Team preference | Depends on context | Team‑level; must be labeled |

## Linking Rule (Required)

Decisions are the backbone of project knowledge. Every decision note must include links to related context.

Use these link fields:
- `基于`：what prior context this decision depends on
- `导致`：what this decision changes or triggers
- `相关`：parallel topics worth checking together

Hard rule:
- At least one of the three fields must contain a valid `[[linked-note]]`.

## Writing Guide

### Directory Structure

```
.claude/pensieve/decisions/{date}-{statement}.md
```

Naming rules:
- Filename is a one‑sentence conclusion (declarative)
- The filename tells "what was decided"
- The file explains "why it was decided"

Examples:
- `2026-01-22-ban-javascript-in-core-module.md`
- `2026-01-22-do-not-break-user-visible-behavior.md`

### File Format

```markdown
# {Decision Title}

## One-line Conclusion
> [State the final decision in one sentence]

## 上下文链接
- 基于：[[前置决策或知识]]
- 导致：[[后续影响或流程]]
- 相关：[[相关主题]]

## Context
What situation triggered this decision?

## Problem
What real problem does it solve? (not imagined)

## Alternatives Considered
- Option A: xxx (why not)
- Option B: xxx (why not)

## Decision
What was chosen, and why?

## Consequence
- What risks are reduced?
- What better choices can future maintainers make?

## Key Files
- `path/to/file` - related implementation/document
```

### Example

```markdown
# Avoid special‑case branches when deleting linked‑list nodes

## Context
While maintaining legacy code, the list deletion logic had a typical "head‑node special case" branch.

## Problem
This approach has two issues:
- The logic splits into two paths; readers must mentally merge them to verify correctness.
- Any change must consider both "head node" and "non‑head node" versions, increasing errors.

## Alternatives Considered
- Keep the current implementation: maintain a loop with special‑case branches.
- Rewrite using a pointer‑to‑pointer so all nodes follow the same path.

## Decision
Rewrite using a pointer‑to‑pointer to eliminate the head‑node special case.

## Consequence
- Every deletion path uses the same logic, easier to review.
- Future maintainers don’t need to simulate two code paths.
```

## Notes

- Decisions are **context‑dependent** and must include Context
- A decision without Alternatives Considered is incomplete — it means no real trade‑off was considered
- Team‑preference decisions must be labeled to avoid being mistaken as universal rules
