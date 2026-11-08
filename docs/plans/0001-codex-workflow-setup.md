# Plan: Codex Workflow Setup

- **ID:** 0001
- **Status:** Complete
- **Created:** 2026-11-08
- **Goal:** Configure the approved lightweight Codex workflow for this repository without changing product code.

## Scope

- Add repository guidance and project-scoped Codex configuration for one primary writer and optional read-only
  subagents.
- Add plan, ADR, memory, and handoff documentation conventions.
- Correct the UI label in the architecture diagram and make feature test coverage component-specific.
- Do not change application source code, dependencies, generated files, or platform folders.

## Files in scope

| File                                                                | Intended change                                                           |
|:--------------------------------------------------------------------|:--------------------------------------------------------------------------|
| `AGENTS.md`                                                         | Add concise routing to the approved Codex workflow.                       |
| `.codex/config.toml`                                                | Limit concurrency to one optional subagent.                               |
| `.codex/agents/repo-scout.toml`                                     | Define read-only exploration role.                                        |
| `.codex/agents/reviewer.toml`                                       | Define read-only review role.                                             |
| `docs/codex-workflow.md`                                            | Document approvals, plans, tests, ADRs, memory, handoff, and delegation.  |
| `docs/architecture.md`                                              | Replace the incorrect Jetpack Compose diagram label with Flutter Widgets. |
| `docs/features/template.md`                                         | Map behavior-bearing components to applicable test paths and scenarios.   |
| `docs/plans/README.md`, `TEMPLATE.md`                               | Define plan naming, lifecycle, and template.                              |
| `docs/adr/README.md`, `TEMPLATE.md`, `0001-adopt-codex-workflow.md` | Adopt the approved workflow as an accepted durable process decision.      |
| `docs/memory/MEMORY.md`, `project.md`, `handoff.md`                 | Add concise project memory index, stable facts, and recovery status.      |
| `docs/plans/0001-codex-workflow-setup.md`                           | Record and complete this setup plan.                                      |

## Steps

- [x] Inspect repository guidance, documentation structure, existing tests, and current worktree status.
- [x] Interview the user and obtain approval for this exact scope, including ADR 0001 acceptance.
- [x] Create the approved documentation and Codex configuration files; preserve existing project rules.
- [x] Validate TOML syntax, referenced paths, and the final diff; confirm no product code changed.
- [x] Dry-run the workflow on a representative multi-file feature without editing files.

## Acceptance checks

- [x] All new workflow and feature documentation is in English.
- [x] Primary agent is the only writer; custom agents are optional read-only roles and require a read-only parent
  session.
- [x] Feature template maps each applicable behavior-bearing component to test paths and cases, including Drift
  migration coverage when relevant.
- [x] ADR 0001 is Accepted as explicitly approved by the user.
- [x] TOML parses, all referenced workflow files exist, and no product code changed.
- [x] Dry-run states the relevant reads, approvals, agents, tests, and recovery checkpoint.

## Dry run

**Scenario:** Add a priority filter to the task list. This is a representative feature expected to touch more than three
files.

1. At session start, Codex follows the loaded `AGENTS.md`, then reads `docs/memory/handoff.md`, `docs/memory/MEMORY.md`,
   and the linked active plan. It reads `docs/architecture.md` and `docs/features/template.md` because they define the
   affected architecture and required feature documentation.
2. The primary agent inspects the relevant enum/use case, task Bloc, home screen components, and existing Bloc/widget
   tests. Likely starting points include `lib/core/enums/task_filter_type.dart`,
   `lib/features/tasks/domain/use_cases/filter_and_sort_tasks_use_case.dart`, `lib/features/tasks/ui/blocs/task_bloc/`,
   `lib/features/tasks/ui/screens/home_screen/`, and `test/ui/blocs/task_bloc_test.dart` /
   `test/ui/screens/home_tasks_screen_test.dart`.
3. Before saving a task plan, the primary agent presents its scope and waits for approval. After the plan is saved, it
   waits for separate approval to implement. It identifies applicable domain/use-case, Bloc, and widget tests and
   records test cases in the feature document. Drift migration tests are required only if persistence schema changes.
4. No subagent is needed by default. A bounded `repo_scout` could help only if independent exploration is useful and the
   parent IDE session is technically in read-only mode. A `reviewer` can be used after an implementation step under the
   same read-only-parent condition; the primary agent remains the sole writer.
5. The task plan records completed steps, acceptance checks, tests run, and failures. `docs/memory/handoff.md` points to
   that plan and records the last completed step and next action after each approved step, making a fresh session
   resumable from the working tree.

This dry run is a protocol walkthrough only; it makes no feature changes and runs no application tests.

## Recovery checkpoint

- **Last completed step:** Created and validated the approved workflow files; completed the dry run.
- **Next action:** Start a new task; read this handoff and the linked active plan before continuing interrupted work.
- **Changed or uncommitted files:** See the approved file list under `Files in scope`; no changes were staged or
  committed.
- **Known failures or blockers:** None.
- **Manual step for first use:** Trust this repository in Codex Desktop, then open a fresh project chat so
  project-scoped settings and custom agents load.
