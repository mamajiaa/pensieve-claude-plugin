# Decisions

Record project choices made in specific contexts: in what situation, why was what chosen.

## Purpose

The core value of a decision is to **reduce repeated mistakes**.
The secondary value is to **reduce repeated questions and repeated exploration**.

When similar problems arise again, the team should be able to quickly answer:
- What choice was made
- Why it was chosen
- Why other options were rejected
- What inquiry/exploration steps can be skipped next time

## Exploration Reduction Principle (Cross-Project)

A good decision does not merely "record history" -- it **compresses future exploration paths**.

Minimum requirements:
1. Clear "trigger conditions" (when to directly apply this decision)
2. Clear "skip items" (which questions need not be asked again, which paths need not be explored again)
3. Clear "boundary conditions" (when this decision becomes invalid)

## Semantic Positioning (WANT Layer)

`decision` carries WANT (preference layer): the project's desired direction, trade-offs, and strategy -- i.e., "I want it this way."

Key criteria:
- Not "objective facts about the world" (that is `knowledge`)
- Not "non-negotiable bottom lines" (that is `maxim`)
- It is an actively chosen approach in the current project context

## Capture Criteria

### Core Standard

> A decision belongs in global `decisions/` only if it clearly reduces regression risk, improves readability or collaboration, and can be distilled into a "reusable pattern."

### Three Golden Questions

1. **If we delete this, will we be more likely to make mistakes later?**
2. **Would someone three months later make a better choice after reading it?**
3. **Can it be explained clearly and reused?**

Any clear "yes" -> worth capturing.
All "uncertain" -> keep in loop temporary directory.

### Five Value Dimensions

| Dimension | Question |
|----------|----------|
| Long-term impact | Does it reduce a class of bugs? |
| Readability | Can it be distilled into a transferable "code taste"? |
| Locality | Does it define module boundaries or responsibilities? |
| Collaboration signal | Was it explicitly decided by the user or repeatedly confirmed? |
| Noise check | Does it pass the three golden questions above? |

## Relationships & Evolution

| Direction | Description |
|-----------|-------------|
| Decision -> Maxim | Repeated decisions can be elevated into maxims |
| Knowledge -> Decision | External knowledge combined with project practice forms decisions |
| Loop -> Decision | Temporary loop decisions are filtered and promoted |

### Storage Locations

| Stage | Location | Notes |
|-------|----------|-------|
| During loop | `.claude/skills/pensieve/loop/{name}/_decisions/` | Temporary; tied to loop lifecycle |
| After loop | `.claude/skills/pensieve/decisions/` | Project user data (never overwritten) |

### Decision Levels

| Level | Characteristics | Scope |
|-------|-----------------|-------|
| Hard rule | Violating it causes regressions | Cross-project universal |
| Coding taste | Reduces special cases; easier to reason about | Implementation guidance |
| Team preference | Depends on team context | Must be explicitly labeled |

## Link Rules (Mandatory)

Decisions are the backbone of the knowledge network. Every decision must include context links.

Link fields:
- `Based on`: which prerequisite contexts it depends on
- `Leads to`: what subsequent changes it triggers
- `Related`: parallel topics recommended to read together

Hard rule:
- At least one of the three fields must contain a valid `[[linked-note]]`.

## Writing Guide

### Directory Structure

```
.claude/skills/pensieve/decisions/{date}-{statement}.md
```

Naming rules:
- Filename is a one-sentence conclusion (declarative statement)
- The filename answers "what was decided"
- The file content explains "why it was decided"

Examples:
- `2026-01-22-ban-javascript-in-core-module.md`
- `2026-01-22-do-not-break-user-visible-behavior.md`

### File Format

```markdown
# {Decision Title}

## One-Line Conclusion
> [State the final decision in one sentence]

## Context Links
- Based on: [[prerequisite decision or knowledge]]
- Leads to: [[subsequent impact or workflow]]
- Related: [[related topic]]

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

## Exploration Reduction
- What questions can be skipped next time:
- What searches can be skipped next time:
- Invalidation conditions (must re-evaluate when these appear):

## Key Files
- `path/to/file` - Related implementation or documentation
```

### Example

```markdown
# Avoid special-case branches when deleting linked-list nodes

## Context
While maintaining legacy code, the deletion logic had a "head-node special case" branch.

## Problem
This approach has two issues:
- The logic splits into two paths; reviewers must mentally merge them to verify correctness.
- Any subsequent change must cover both "head node" and "non-head node" paths, increasing error rates.

## Alternatives Considered
- Keep the current implementation: continue maintaining the special-case branch.
- Use pointer-to-pointer: let all nodes follow the same path.

## Decision
Rewrite using pointer-to-pointer to eliminate the head-node special case.

## Consequence
- Deletion paths are unified, making review easier.
- Maintainers no longer need to mentally simulate two branches.
```

## Notes

- Decisions are **context-dependent** and must include Context
- A decision without Alternatives Considered is typically incomplete
- Team-preference decisions must be explicitly labeled to avoid being mistaken as universal rules
- If you cannot clearly state "what questions/searches to skip next time," the content is more likely a discussion record and should not be promoted to `decisions/`
