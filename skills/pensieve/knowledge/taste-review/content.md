# Taste Review Knowledge Base

Core philosophy, warning signs, and classic examples for code review.

## Sources

- Linus Torvalds TED Talk + Linux Kernel Coding Style
- John Ousterhout — "A Philosophy of Software Design"
- Google Engineering Practices

## Supporting Resources

The `source/` directory can hold project‑specific references. Pull language‑specific style guides from the official repository:

**Google Style Guides**: https://github.com/google/styleguide

| Language | File |
|----------|------|
| C++ | `cppguide.html` |
| Java | `javaguide.html` |
| Python | `pyguide.md` |
| JavaScript | `jsguide.html` |
| TypeScript | `tsguide.html` |
| Shell | `shellguide.md` |
| C# | `csharp-style.md` |

Example: if the project uses Python and TypeScript, you can pull the guides:
```bash
mkdir -p source/google-style-guides
curl -o source/google-style-guides/pyguide.md https://raw.githubusercontent.com/google/styleguide/gh-pages/pyguide.md
curl -o source/google-style-guides/tsguide.html https://raw.githubusercontent.com/google/styleguide/gh-pages/tsguide.html
```

## Summary

Code review references from three sources: Linus’ taste philosophy, Ousterhout’s complexity management, and Google’s code health standards.

## When to Use

- You need theoretical grounding for code review
- You need classic quotes to explain issues
- You need good/bad code comparisons

---

## Core Philosophy

### Linus Torvalds: Good Taste

> "Sometimes you can see a problem in a different way and rewrite it so that the special case goes away and becomes the normal case."

**Core principles**:
1. **Eliminate special cases**: design away edge cases rather than patch with conditionals
2. **Data structures first**: good programmers worry about data structures; bad ones worry about code
3. **Nesting limits**: more than 3 levels suggests refactoring
4. **Short functions**: do one thing well
5. **Local variable limits**: more than 5–10 locals suggests splitting
6. **Never break userspace**: user‑visible behavior must not change
7. **Expose problems early**: avoid fallbacks/compat code; let upstream issues show in tests

### John Ousterhout: Managing Complexity

> "Complexity is anything related to the structure of a software system that makes it hard to understand and modify."

**15 design principles**:

| # | Principle | Notes |
|---|----------|------|
| 1 | Complexity grows gradually | Small issues accumulate into big ones |
| 2 | Working code isn't enough | Quality matters |
| 3 | Make continual small investments | Improve design incrementally |
| 4 | Modules should be deep | Simple interface + powerful functionality |
| 5 | Simplify common use cases | Make the common case easy |
| 6 | Interface simplicity > implementation simplicity | Prefer complex internals over complex APIs |
| 7 | General‑purpose modules are deeper | Reusability increases depth |
| 8 | Separate general vs special‑purpose code | Avoid mixing |
| 9 | Different layers need different abstractions | Layered clarity |
| 10 | Pull complexity downward | Keep higher levels simple |
| 11 | Define errors out of existence | Design to eliminate error cases |
| 12 | **Design it twice** | Consider at least two approaches |
| 13 | Comment non‑obvious things | Don't restate code |
| 14 | Design for reading | Optimize for readers, not writers |
| 15 | Increments should be abstractions | Not just new features |

**Three symptoms of complexity**:
1. **Change amplification**: simple change touches many places
2. **Cognitive load**: too much to understand to make a change
3. **Unknown unknowns**: unclear where changes must be made

**Module depth**:
- **Deep modules**: simple interface + powerful functionality
- **Shallow modules**: complex interface + limited functionality

### Google Code Review: Code Health

> "A CL that improves the overall code health of the system should not be delayed for perfection."

**Review order**: Design → Functionality → Complexity → Tests → Naming → Comments → Style → Docs

**Small CLs**:
- 100 lines is usually reasonable
- 1000 lines is usually too large
- A CL should be **one self‑contained change**

---

## Warning Sign Checklist

### Ousterhout's 14 Warning Signs

| # | Warning sign | Description | Severity |
|---|--------------|-------------|----------|
| 1 | Shallow module | Interface complexity = implementation complexity | CRITICAL |
| 2 | Information leakage | Design decisions exposed across modules | CRITICAL |
| 3 | Temporal decomposition | Structure follows time order rather than information hiding | WARNING |
| 4 | Overexposure | Common tasks require rare details | WARNING |
| 5 | Pass‑through method | Almost just forwards parameters | WARNING |
| 6 | Code duplication | Non‑trivial code copied repeatedly | CRITICAL |
| 7 | Special/general mix | Specialized and general code not separated | WARNING |
| 8 | Conjoined methods | Two methods tightly coupled | WARNING |
| 9 | Comment repeats code | Comments restate code | WARNING |
| 10 | Implementation leaked in interface | Interface comments mention irrelevant internals | WARNING |
| 11 | Vague names | Names are imprecise or unhelpful | WARNING |
| 12 | Hard to name | Hard to find a precise, intuitive name | WARNING |
| 13 | Hard to describe | Full documentation is lengthy | CRITICAL |
| 14 | Non‑obvious code | Behavior/meaning is hard to infer | CRITICAL |

### Code Structure Warning Signs

| Signal | Threshold | Severity |
|--------|-----------|----------|
| Nesting depth | > 3 levels | CRITICAL |
| Function length | > 100 lines | CRITICAL |
| Local variables | > 10 | WARNING |
| No centralized cleanup | Multiple exits with separate cleanup | WARNING |

### Error Handling Warning Signs

| Signal | Description | Severity |
|--------|-------------|----------|
| Defensive defaults | `?? 0` or `|| defaultValue` | WARNING |
| Too many exceptions | try‑catch outweighs business logic | CRITICAL |
| Fallback code | Masks upstream problems | WARNING |

---

## Classic Quotes

### Linus Torvalds

| Context | Quote |
|---------|-------|
| Defensive code | "Bad programmers worry about the code. Good programmers worry about data structures." |
| Deep nesting | "If you need more than 3 levels of indentation, you're screwed anyway." |
| Over‑design | "Theory and practice sometimes clash. Theory loses. Every single time." |
| Special cases | "Sometimes you can see a problem in a different way and rewrite it so that the special case goes away." |

### John Ousterhout

| Context | Quote |
|---------|-------|
| Shallow modules | "Shallow modules don't help much in the battle against complexity." |
| Too many exceptions | "The best way to eliminate exception handling complexity is to define your APIs so that there are no exceptions to handle." |
| Classitis | "Classes are good, so more classes are better — this is a mistake." |
| Design | "Design it twice. You'll end up with a much better result." |

### Google Code Review

| Context | Quote |
|---------|-------|
| Evaluate changes | "A CL that improves the overall code health of the system should not be delayed for perfection." |
| Over‑engineering | "Encourage developers to solve the problem they know needs to be solved now, not the problem they speculate might need to be solved in the future." |
| Large CLs | "100 lines is usually a reasonable size for a CL, and 1000 lines is usually too large." |

---

## Classic Examples

### 1. Linus Classic: Linked‑List Deletion

**Bad taste (10 lines)**:
```c
void remove_list_entry(List *list, Entry *entry) {
    Entry *prev = NULL;
    Entry *walk = list->head;
    while (walk != entry) {
        prev = walk;
        walk = walk->next;
    }
    if (prev == NULL) {
        list->head = entry->next;  // special case: deleting head
    } else {
        prev->next = entry->next;
    }
}
```

**Good taste (4 lines)**:
```c
void remove_list_entry(List *list, Entry *entry) {
    Entry **indirect = &list->head;
    while (*indirect != entry)
        indirect = &(*indirect)->next;
    *indirect = entry->next;
}
```

**Key point**: Use an indirect pointer so "delete head" and "delete middle" are the same operation. Special cases disappear.

### 2. Deep vs Shallow Modules

**Deep module (Unix I/O)**:
```c
int fd = open("/path/to/file", O_RDONLY);
char buf[1024];
ssize_t n = read(fd, buf, sizeof(buf));
close(fd);
```
Five basic calls handle all I/O, hiding filesystem, buffering, permissions, etc.

**Shallow module (Java file I/O)**:
```java
FileInputStream fileStream = new FileInputStream(fileName);
BufferedInputStream bufferedStream = new BufferedInputStream(fileStream);
ObjectInputStream objectStream = new ObjectInputStream(bufferedStream);
```
You must understand 3 classes to read a file; interface complexity = implementation complexity.

### 3. Defensive Code vs Fail Fast

**Bad**:
```typescript
function processUser(user: User | null) {
    const name = user?.name ?? "Unknown";
    const email = user?.email ?? "";
    sendEmail(email, `Hello ${name}`);  // send to empty address?
}
```

**Good**:
```typescript
function processUser(user: User) {
    sendEmail(user.email, `Hello ${user.name}`);
}
```

**Key point**: Don't accept null; let the type system enforce. If upstream passes null, tests should fail.

### 4. goto Centralized Cleanup

**Bad (scattered cleanup)**:
```c
int bad_init(void) {
    struct foo *foo = kmalloc(sizeof(*foo), GFP_KERNEL);
    if (!foo)
        return -ENOMEM;
    foo->bar = kmalloc(sizeof(*foo->bar), GFP_KERNEL);
    if (!foo->bar) {
        kfree(foo);  // cleanup 1
        return -ENOMEM;
    }
    if (some_error) {
        kfree(foo->bar);  // cleanup 2
        kfree(foo);
        return -EINVAL;
    }
    return 0;
}
```

**Good (centralized cleanup)**:
```c
int good_init(void) {
    int result = 0;
    struct foo *foo = kmalloc(sizeof(*foo), GFP_KERNEL);
    if (!foo) { result = -ENOMEM; goto out; }
    foo->bar = kmalloc(sizeof(*foo->bar), GFP_KERNEL);
    if (!foo->bar) { result = -ENOMEM; goto out_free_foo; }
    if (some_error) { result = -EINVAL; goto out_free_bar; }
    return 0;
out_free_bar:
    kfree(foo->bar);
out_free_foo:
    kfree(foo);
out:
    return result;
}
```

### 5. Different Layers, Different Abstractions

**Bad (pass‑through)**:
```typescript
// UI Layer
async function handleFileUploadButton() { await uploadFile(file); }
// Service Layer - just pass-through!
async function uploadFile(file: File) { await saveFile(file); }
// Data Layer - still pass-through!
async function saveFile(file: File) { await fs.writeFile(file.path, file.data); }
```

**Good (distinct abstractions)**:
```typescript
// UI Layer - user interaction
async function handleFileUploadButton() { /* progress, error display */ }
// Service Layer - business logic
async function storeDocument(file: File) { /* validate, compress, encrypt, index */ }
// Storage Layer - persistence
async function save(data: Buffer) { /* generate ID, write backend */ }
```

---

## Scoring Criteria

| Level | Criteria |
|-------|----------|
| **Good taste** | All checks pass or at most 1 WARNING; functions < 50 lines, nesting <= 2 |
| **OK** | 2–3 WARNINGs, no CRITICAL; functions 50–100 lines, nesting = 3 |
| **Bad** | Any CRITICAL or >= 4 WARNINGs; functions > 100 lines or nesting > 3 |
