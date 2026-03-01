# Tool Boundaries

Each tool has a clear responsibility boundary. When a request is routed to the wrong tool, redirect according to this table.

## Responsibility Scope

| Tool | Responsible for | Not responsible for |
|------|----------------|---------------------|
| `upgrade` | Version sync + structural migration | Does not issue PASS/FAIL, does not perform per-file semantic review |
| `doctor` | Read-only checks + compliance reports | Does not modify user data files, does not perform migration (only auto-maintains `SKILL.md` and auto memory `MEMORY.md` guidance block) |
| `self-improve` | Archive experience into four user data categories | Does not perform migration/checks |
| `init` | Initialize project directory + seed files + baseline exploration and code review (read-only) | Does not perform migration cleanup, does not directly write archived content |
| `loop` | Decompose complex tasks + sub-agent iterative execution | Small tasks should be completed directly, do not open a loop |

## Routing Quick Reference

| User intent | Correct tool | Common misroute |
|-------------|-------------|-----------------|
| Update plugin version / migrate legacy data / clean up old paths | `upgrade` | `init`, `doctor` |
| First-time project onboarding / seed missing files / generate initial review baseline | `init` | `upgrade` (unless legacy data exists) |
| Post-init compliance recheck | `doctor` (mandatory) | Skipping doctor and going straight to development |
| Compliance check / PASS-FAIL graded report | `doctor` | `upgrade`, `self-improve` |
| Archive experience / write maxim / decision / pipeline | `self-improve` | `doctor`, `upgrade` |
| Complex task decomposition with auto-execution | `loop` | Direct execution (for small tasks) |
| Execute a specific pipeline | `loop` (load pipeline) | Direct execution (should go through loop) |

## Negative Examples

| User says | Should NOT | Should redirect to |
|-----------|-----------|-------------------|
| "There's an old skills/pensieve/ in the project, migrate it for me" | Continue with init | `upgrade` |
| "Give me a PASS/FAIL check result first" | Let init or upgrade produce conclusions | `doctor` |
| "After init, write the candidates directly into knowledge/decision" | Let init write directly | `self-improve` |
| "Run doctor first, then decide whether to upgrade" | Skip version confirmation | `upgrade` (do version check first; if no new version, then ask whether to run `doctor`) |
| "Check and fix issues at the same time" | Let doctor batch-modify user data files | Run `doctor` for the report first, then fix manually (only `SKILL.md`/auto memory auto-maintenance is allowed) |
| "Just archive everything from this session automatically, no need to confirm" | Auto-archive without routing | `self-improve` (may write directly) |
| "Fix 1 copy file, and also run loop" | Open a loop | Complete directly |
| "Version is already current, still proceed to migration" | Bypass version check | Stop at asking about `doctor` self-check |
| "Skip the quick check and just give me PASS" | Skip frontmatter quick check | Must run `check-frontmatter.sh` first |
| "Haven't confirmed requirements yet, create 10 tasks first" | Skip confirmation and split directly | Confirm the goal first, then generate tasks |
| "While you're at it, migrate the old directory too" | Let self-improve do migration | `upgrade` |
| "During migration, also give me PASS/FAIL results" | Let upgrade produce compliance conclusions | Run `upgrade` first, then `doctor` |
