# Self-Improve Pipeline

---
description: Knowledge capture workflow. Trigger when loop completes or user says "capture", "record", or "save".
---

You are helping capture learnings and patterns into Pensieve's knowledge system.

**System prompts** (tools/scripts/system knowledge) live in the plugin and are updated only via plugin updates.

**User data** lives in project-level `.claude/pensieve/` and is never overwritten by the plugin.

Determine what's worth preserving, categorize it correctly, and write it in the proper format.

## Core Principles

- **User confirmation required**: Never auto-capture — always ask first
- **Read before write**: Must read the target README before creating any file
- **Deletion over addition**: Simpler system is more reliable
- **Right category**: Match content to the correct knowledge type

---

## Phase 1: Understand Intent

**Goal**: Clarify what the user wants to capture

**Actions**:
1. Identify the source:
   - Loop deviation (expected vs actual)
   - Discovered pattern during work
   - Explicit user instruction
   - External reference material

2. Ask clarifying questions if needed:
   - What specific insight should be captured?
   - What triggered this realization?
   - How general is this learning?

---

## Phase 2: Audit Existing Pensieve (Optional)

**Goal**: Find improvement opportunities in current project Pensieve data

**Actions**:
1. Ask the user if they want a Pensieve audit:
   - "Want me to review your current `.claude/pensieve/` contents for improvements?"
2. If yes:
   - Read each category README:
     - `<SYSTEM_SKILL_ROOT>/maxims/README.md`
     - `<SYSTEM_SKILL_ROOT>/decisions/README.md`
     - `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
     - `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
   - Review the corresponding project files under `.claude/pensieve/`
   - Flag format violations, missing fields, outdated content, or mis‑categorized items
   - Provide a concise review report with suggested fixes
3. **Do not edit anything without explicit user approval**

If the user declines, skip this phase and continue.

---

## Phase 3: Categorize

**Goal**: Determine the correct knowledge type

**Actions**:
1. Evaluate content against each category:

| Type | Characteristics | README |
|------|-----------------|--------|
| **maxim** | Universal principles — applies across projects, languages, domains | `maxims/README.md` |
| **decision** | Context-dependent choices — specific to situation or project | `decisions/README.md` |
| **pipeline** | Executable workflows — repeatable process with clear steps | `pipelines/README.md` |
| **knowledge** | External references — docs, tutorials, specifications | `knowledge/README.md` |

2. **Present categorization to user**:
   ```markdown
   ## Capture Recommendation

   [Content summary] → Recommend **[type]**

   Reason: [Explanation based on README criteria]

   Do you agree?
   ```

**CRITICAL**: Wait for user confirmation before proceeding.

---

## Phase 4: Read Target README

**Goal**: Understand the exact format and criteria for the chosen category

**DO NOT SKIP**: This phase is mandatory. The README defines:
- Capture criteria (what's worth capturing)
- File format requirements
- Naming conventions
- Examples

**Actions**:
1. Read the corresponding README:
   ```
   Read <SYSTEM_SKILL_ROOT>/{type}/README.md
   ```

2. Verify the content meets the capture criteria defined in README

3. If content doesn't meet criteria, explain to user and ask how to proceed

---

## Phase 5: Draft Content

**Goal**: Write content following the README format exactly

**Actions**:
1. Draft the file content following README specifications

2. Choose the target location:
   - **pipeline** → `.claude/pensieve/pipelines/{name}.md` (project user data)
   - **maxim** → `.claude/pensieve/maxims/{name}.md` (project user data)
   - **decision** → `.claude/pensieve/decisions/{date}-{conclusion}.md` (project user data)
   - **knowledge** → `.claude/pensieve/knowledge/{name}/content.md` (project user data)

3. **Present draft to user for review**:
   ```markdown
   ## Draft Preview

   File: `{target_path}`

   ---
   [draft content]
   ---

   Write it?
   ```

**CRITICAL**: Wait for user approval before writing.

---

## Phase 6: Write

**Goal**: Persist the knowledge

**DO NOT START WITHOUT USER APPROVAL** from Phase 4.

**Actions**:
1. Write the file to `{target_path}`
2. Confirm successful write to user
3. Suggest any related follow-up actions (e.g., update other files that reference this)

---

## Knowledge Evolution

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐  │
│  │   maxims/   │   │ decisions/  │   │ pipelines/  │   │ knowledge/  │  │
│  │  future guide│ ←│ past lessons│   │ workflows   │   │ external in │  │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘

Evolution path: decision → repeated pattern → maxim → guides → pipeline
```

---

## Related Files

- `maxims/README.md` — Maxim format and criteria
- `decisions/README.md` — Decision format and criteria
- `pipelines/README.md` — Pipeline format and criteria
- `knowledge/README.md` — Knowledge format and criteria
