# Knowledge

External reference material: technical docs, API references, best practices, etc.

## Purpose

Knowledge exists to **reduce execution friction**.

Without this knowledge, where does the model get stuck, and how costly is that?

### Three sources of friction

| Friction type | Characteristics | Examples |
|--------------|-----------------|----------|
| **Time gap** | New knowledge after model training cutoff | Next.js 15 APIs, new Claude Code features |
| **Implicit knowledge** | Must be inferred from structure, not explicit | Naming conventions, architectural rationale |
| **Scattered knowledge** | Exists but hard to retrieve | GitHub issues, mailing lists, source comments |

## Capture Criteria

Ask yourself: **If we don't write this down, what friction will it cause?**

| Friction level | Action |
|---------------|--------|
| Always blocks, high recovery cost | Must capture |
| Sometimes blocks, searchable | Don't capture; keep a link |
| One‑off issue | Don't capture |

### Capture signals

| Signal | Explanation |
|--------|-------------|
| The model keeps asking the same question | Time gap or missing implicit knowledge |
| Search results are inaccurate or outdated | Time gap |
| Must infer a convention from code every time | Implicit knowledge not made explicit |
| A pipeline depends on external standards | Should be captured for reference |

## Relationships & Evolution

| Direction | Description |
|-----------|-------------|
| Knowledge → Decision | External knowledge + practice → decisions |
| Knowledge → Pipeline | External standards inform pipeline execution |
| Knowledge → Maxim | Best practices internalized into maxims |

### Knowledge vs Decision

| Type | Essence | Test |
|------|---------|------|
| Knowledge | External input | "This is how the world works" |
| Decision | Internal output | "We chose to do this" |

**Edge case**: discovering hidden framework constraints
- Documented but hard to find → Knowledge (scattered)
- Not documented, learned by pain → Decision (internal experience)

## Writing Guide

### Directory Structure

```
.claude/pensieve/knowledge/{name}/
├── content.md      # knowledge content
└── source/         # supporting source files (optional)
```

### File Format

```markdown
# {Knowledge Title}

## Source
[Original link or reference]

## Summary
[One‑sentence summary]

## Content
[Knowledge body — excerpt or synthesis]

## When to Use
[When to consult this knowledge]
```

### Example

```markdown
# Agent Design Best Practices

## Source
https://www.anthropic.com/engineering/advanced-tool-use

## Summary
Anthropic’s official guide to agent tool design.

## Content
- Tool Search Tool: discover tools dynamically, reduce tokens
- Programmatic Tool Calling: orchestrate with code, keep intermediates out of context
- Tool Use Examples: teach with examples, improve parameter accuracy

## When to Use
Designing agents, optimizing tool calls, reducing token usage
```

## Notes

- Knowledge is **input**, not **output**
- Prefer linking originals; avoid copying — link content to source
- If you need a local copy, use file copy/move commands, not re‑writing
- Periodically clean outdated knowledge

## System Knowledge vs Project Knowledge

- System knowledge lives at: `skills/pensieve/knowledge/` (updated via plugin)
- Project knowledge lives at: `.claude/pensieve/knowledge/` (never overwritten)
