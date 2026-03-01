---
id: taste-review-content
type: knowledge
title: Code Taste Review Knowledge Base
status: active
created: 2026-02-28
updated: 2026-02-28
tags: [pensieve, knowledge, review, taste]
---

# Code Taste Review Knowledge Base

Core philosophy, warning signs, and classic examples for code review.

## Sources

- Linus Torvalds public talks and Linux Kernel coding style
- John Ousterhout "A Philosophy of Software Design"
- Google Engineering Practices (Code Review guide)

## Supporting Resources

The `source/` directory can hold project-specific references. Pull language-specific style guides from the official repository:

- Google Style Guides: https://github.com/google/styleguide

Example (project uses Python + TypeScript):

```bash
mkdir -p source/google-style-guides
curl -o source/google-style-guides/pyguide.md https://raw.githubusercontent.com/google/styleguide/gh-pages/pyguide.md
curl -o source/google-style-guides/tsguide.html https://raw.githubusercontent.com/google/styleguide/gh-pages/tsguide.html
```

## Summary

This knowledge base fuses three threads:

1. Linus: eliminate special-case branches through data structures and rewrites
2. Ousterhout: manage complexity through module depth and abstraction
3. Google: review by priority with code health as the goal

## When to Use

- Need theoretical grounding for review comments
- Need to identify implementations that "work but are unmaintainable"
- Need to align the team's judgment of complexity and code health

---

## Core Principles

### 1) Linus: Good Taste

Core ideas:
- Eliminate special cases by refactoring, not by stacking conditionals
- Think about data structures first, then control flow
- Keep nesting depth and function length under control
- User-visible behavior is a hard boundary (do not change it casually)

### 2) Ousterhout: Complexity Management

Three symptoms of complexity:

1. **Change amplification**: a small change ripples across many places
2. **Cognitive load**: too much prerequisite knowledge needed before making a change
3. **Unknown unknowns**: unclear where else changes are needed

Design principles:
- Interfaces should be simple; modules should be "deep"
- Push complexity down into lower layers as much as possible
- Design it twice -- compare at least two designs

### 3) Google: Code Health First

Recommended review order:

`Design -> Functionality -> Complexity -> Tests -> Naming -> Comments -> Style -> Docs`

Key practices:
- Small, self-contained changes are easier to review at high quality
- Changes that improve code health should not be blocked indefinitely in pursuit of "perfection"

---

## Warning Sign Checklist

### Structure Warning Signs

| Signal | Threshold | Severity |
|--------|-----------|----------|
| Nesting depth | > 3 levels | CRITICAL |
| Function length | > 100 lines | CRITICAL |
| Local variable count | > 10 | WARNING |
| Resource cleanup paths | Multiple exits with scattered cleanup | WARNING |

### Error Handling Warning Signs

| Signal | Description | Severity |
|--------|-------------|----------|
| Defensive defaults everywhere | e.g. `?? 0` / `|| default` scattered throughout | WARNING |
| Exception handling outweighs main logic | try/catch blocks outnumber business code | CRITICAL |
| Fallback masks upstream problems | Issues never surface | WARNING |

### Module and Interface Warning Signs

| Signal | Description | Severity |
|--------|-------------|----------|
| Shallow module | Interface complexity approaches implementation complexity | CRITICAL |
| Information leakage | Internal module decisions exposed externally | CRITICAL |
| Hard to name | Difficult to name or explain | WARNING |

---

## Classic Quotes (Original)

### Linus Torvalds

- "Bad programmers worry about the code. Good programmers worry about data structures."
- "If you need more than 3 levels of indentation, you're screwed anyway."
- "Sometimes you can see a problem in a different way and rewrite it so that the special case goes away."

### John Ousterhout

- "Shallow modules don't help much in the battle against complexity."
- "Design it twice. You'll end up with a much better result."

### Google Code Review

- "A CL that improves the overall code health of the system should not be delayed for perfection."

---

## Classic Examples

### 1) Linked-List Deletion: Eliminating Special-Case Branches

**Bad taste (head-node special case exists)**:

```c
void remove_list_entry(List *list, Entry *entry) {
    Entry *prev = NULL;
    Entry *walk = list->head;
    while (walk != entry) {
        prev = walk;
        walk = walk->next;
    }
    if (prev == NULL) {
        list->head = entry->next;
    } else {
        prev->next = entry->next;
    }
}
```

**Good taste (unified path)**:

```c
void remove_list_entry(List *list, Entry *entry) {
    Entry **indirect = &list->head;
    while (*indirect != entry)
        indirect = &(*indirect)->next;
    *indirect = entry->next;
}
```

Key point: with an indirect pointer, "delete head" and "delete middle" become the same operation.

### 2) Defensive Defaults vs Fail Fast

**Not recommended**:

```typescript
function processUser(user: User | null) {
    const name = user?.name ?? "Unknown";
    const email = user?.email ?? "";
    sendEmail(email, `Hello ${name}`);
}
```

**Recommended**:

```typescript
function processUser(user: User) {
    sendEmail(user.email, `Hello ${user.name}`);
}
```

Key point: do not swallow upstream errors; let the type system and tests surface problems early.

---

## Review Practical Recommendations

- Look at design and complexity first, then style details
- Catch issues that cause regressions first, then address optional optimizations
- All review comments should be backed by "verifiable evidence" (logs, tests, behavior)
- Distill reusable conclusions into `decision` or `maxim` in a timely manner
