---
id: knowledge-readme
type: knowledge
title: Knowledge Specification
status: active
created: 2026-02-28
updated: 2026-02-28
tags: [pensieve, knowledge, spec]
---

# Knowledge

External reference material: technical docs, API references, best practices, etc.

## Purpose

The core value of knowledge is to **reduce execution friction**.

Without this knowledge, where does the model get stuck, and how costly is that?

### Three Types of Friction

| Friction type | Characteristics | Examples |
|--------------|-----------------|----------|
| Time gap | Knowledge newer than model training cutoff | Next.js 15 APIs, new Claude Code features |
| Implicit knowledge | Must be inferred from structure, not explicit | Naming conventions, architectural rationale |
| Scattered knowledge | Exists but retrieval cost is high | GitHub issues, mailing lists, source comments |

## Capture Criteria

Core question: **If we don't write this down, what execution friction will it cause?**

| Friction level | Action |
|---------------|--------|
| High-frequency blocker with high recovery cost | Must capture |
| Occasional blocker, quickly searchable | Don't capture; keep a link only |
| One-off issue | Don't capture |

### Capture Signals

| Signal | Explanation |
|--------|-------------|
| The model keeps asking the same question | Time gap or missing implicit knowledge |
| Search results are inaccurate or outdated | Time gap |
| Must infer a convention from code every time | Implicit knowledge not made explicit |
| A pipeline depends on external standards | Should be captured as reusable reference |

## Semantic Positioning (IS Layer)

`knowledge` only carries IS (fact layer): system current state, mechanism boundaries, verifiable behavior -- i.e., "this is how it is."

When a task's primary cost is exploration and locating information, and the content belongs to IS, consider capturing:

1. **State transitions**: after an action triggers, how data/behavior changes
2. **Symptom -> root cause -> locating**: what phenomenon is observed, where to look, why
3. **Boundaries and ownership**: who can modify, who can only call, how cross-module flows work
4. **Does not exist / removed**: which capabilities are not in the current system, to avoid repeated exploration
5. **Anti-patterns**: paths that look feasible but will fail

> Principle: determine the semantic layer first, then decide the type. `knowledge`=IS, `decision`=WANT, `maxim`=MUST, `pipeline`=HOW.

## Relationships & Evolution

| Direction | Description |
|-----------|-------------|
| Knowledge -> Decision | External knowledge + project practice forms decisions |
| Knowledge -> Pipeline | External standards inform pipeline execution |
| Knowledge -> Maxim | Best practices internalized into maxims |

### Knowledge vs Decision

| Type | Essence | Test |
|------|---------|------|
| Knowledge | External input | "This is how the world works" |
| Decision | Internal output | "We chose to do this" |

Edge case:
- Framework constraint "documented but hard to find" -> Knowledge (scattered)
- Not documented, learned by pain -> Decision (internal experience)

## Writing Guide

### Directory Structure

```
.claude/skills/pensieve/knowledge/{name}/
├── content.md      # Knowledge content
└── source/         # Supporting source files (optional)
```

### File Format

```markdown
# {Knowledge Title}

## Source
[Original link or reference source]

## Summary
[One-sentence summary]

## Content
[Knowledge body -- excerpt or synthesis]

## When to Use
[When to consult this knowledge]

## Context Links (Recommended)
- Based on: [[prerequisite knowledge or decision]]
- Leads to: [[decisions or workflows it affects]]
- Related: [[related topics]]
```

### Exploration-Type Knowledge Template (Recommended)

```markdown
# {Topic}

## Source
[Source: codebase / documentation / conversation]

## Summary
[One sentence explaining what exploration cost this knowledge saves]

## State Transitions
[Action -> state change -> observable result]

## Symptom -> Root Cause -> Locating
- **[Symptom]**: [Root cause] -> [File / module / entry point]

## Boundaries and Ownership
- [Module A is responsible for what]
- [Module B is read-only / call-only, does not write directly]

## Anti-Patterns (Do Not)
- [Do not do this + reason]

## Verification Signals
- [Logs / tests / runtime behavior]

## When to Use
[Next time you encounter this situation, read this first]
```

### Example

```markdown
# Agent Design Best Practices

## Source
https://www.anthropic.com/engineering/advanced-tool-use

## Summary
Anthropic's official agent tool design guide.

## Content
- Tool Search Tool: discover tools dynamically, reduce token consumption
- Programmatic Tool Calling: orchestrate tool calls with code, reduce context noise
- Tool Use Examples: improve parameter call accuracy through examples

## When to Use
When designing agents, optimizing tool calls, or reducing token usage.
```

## Notes

- Knowledge is **input**, not **output**
- Prefer linking original sources; avoid unnecessary copying
- If you need a local copy, use file copy/move commands, not manual rewriting
- Periodically clean outdated knowledge
- Links are recommended (not mandatory); keep them only when they improve retrieval value

## System Knowledge vs Project Knowledge

- System knowledge: `skills/pensieve/knowledge/` (updated via plugin)
- Project knowledge: `.claude/skills/pensieve/knowledge/` (never overwritten)
