# Plan: Shared AI Instructions

- **ID:** 0002
- **Status:** Complete
- **Created:** 2026-11-08
- **Goal:** Remove duplicated shared project rules across Codex, Antigravity/Gemini, and GitHub Copilot while keeping
  Codex-only workflow guidance specific to Codex.

## Scope

- Keep shared project and architecture rules in the root `AGENTS.md`.
- Move the Codex Workflow instructions from `AGENTS.md` into the project-scoped `.codex/config.toml` using
  `developer_instructions`.
- Keep `GEMINI.md` and `.github/copilot-instructions.md` as files for agent-specific additions, with comments pointing
  to `AGENTS.md` and explaining why it must not be imported there.
- Document the source-of-truth arrangement in `docs/codex-workflow.md`.
- Do not modify application code, dependencies, generated files, or platform directories.

## Files in scope

| File                                        | Intended change                                                                                                                                                                       |
|:--------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `AGENTS.md`                                 | Keep the shared project rules as the canonical source; confirm no Codex-only workflow section remains.                                                                                |
| `.codex/config.toml`                        | Add Codex-only instructions through `developer_instructions`; preserve the existing agent concurrency setting.                                                                        |
| `GEMINI.md`                                 | Replace duplicated common rules with a comment explaining that shared rules are loaded from `AGENTS.md`; leave room for Gemini/Antigravity-specific rules; do not import `AGENTS.md`. |
| `.github/copilot-instructions.md`           | Replace duplicated common rules with a comment explaining that shared rules are in `AGENTS.md`; leave room for Copilot-specific rules; do not import `AGENTS.md`.                     |
| `docs/codex-workflow.md`                    | Document the shared and Codex-specific instruction sources and the no-import convention.                                                                                              |
| `docs/memory/handoff.md`                    | Track the active plan and update the recovery checkpoint after the approved implementation step.                                                                                      |
| `docs/plans/0002-shared-ai-instructions.md` | Track scope, approvals, implementation, and validation.                                                                                                                               |

## Steps

- [x] Implement the instruction-source changes and documentation updates in the listed files; update the handoff in the
  same approved step.
- [x] Validate the TOML structure and review the final diff for duplicate shared rules, correct comments, and unchanged
  project agent settings. No application tests or builds are needed for this configuration and documentation-only
  change.
- [x] Mark the plan complete and return the handoff to idle.

## Acceptance checks

- [x] Shared rules appear in one authoritative project file: root `AGENTS.md`.
- [x] Codex-only workflow instructions are supplied through `.codex/config.toml` and are absent from Gemini and Copilot
  instructions.
- [x] `GEMINI.md` and `.github/copilot-instructions.md` remain present, explain that shared rules come from `AGENTS.md`,
  and contain no active import directive.
- [x] `docs/codex-workflow.md` describes the arrangement and its rationale.
- [x] `.codex/config.toml` remains valid and retains `max_concurrent_threads_per_session = 1`.
- [x] No application tests, builds, or generated code changes are introduced.

## Recovery checkpoint

- **Last completed step:** Implemented the approved shared instruction source and Codex-specific project configuration;
  validated the TOML and reviewed the diff.
- **Next action:** None.
- **Changed or uncommitted files:** `AGENTS.md`, `.codex/config.toml`, `GEMINI.md`, `.github/copilot-instructions.md`,
  `docs/codex-workflow.md`, `docs/plans/0002-shared-ai-instructions.md`, `docs/memory/handoff.md`.
- **Known failures or blockers:** None.
