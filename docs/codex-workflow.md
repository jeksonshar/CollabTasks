# Codex Workflow

## Instruction sources

- Keep shared project architecture, scope, and implementation rules in the repository root `AGENTS.md`.
- Keep Codex-only workflow guidance in the project-scoped `developer_instructions` setting in `.codex/config.toml`;
  trusted-project configuration is required for Codex to load it.
- Keep `GEMINI.md` and `.github/copilot-instructions.md` for agent-specific additions. Do not import `AGENTS.md` from
  those files: Antigravity loads both root `AGENTS.md` and `GEMINI.md`, and supported Copilot agent surfaces may combine
  `AGENTS.md` with repository instructions.
- When changing shared rules, edit `AGENTS.md` once. Keep the other files as short agent-specific extension points to
  avoid duplicated shared guidance.

## Ownership and language

- The primary Codex agent owns planning, implementation, documentation, configuration, checks, plans, ADRs, memory, and
  handoffs.
- No planner or worker subagents are used. Optional custom subagents are read-only repository scout and reviewer roles.
- Write new or modified workflow and feature documentation in English. Continue speaking with the user in Russian unless
  asked otherwise.
- Preserve the repository's `AGENTS.md` laws, scope boundaries, generated-file exclusions, and feature documentation
  rules.

## First use in Codex Desktop

- Mark this repository as trusted in Codex Desktop. Codex loads project-scoped `.codex/config.toml` settings and
  `.codex/agents/*.toml` roles only for trusted projects.
- After trusting the project or changing these files, start a fresh project chat so the session loads the current
  configuration. If the custom roles or concurrency cap are unavailable, first check that the project is trusted.

## Session start and context

1. Rely on the applicable `AGENTS.md` instructions already loaded by Codex.
2. Read `docs/memory/handoff.md` and `docs/memory/MEMORY.md`.
3. If handoff links an active plan, read that plan before continuing it.
4. Read `docs/memory/project.md`, `docs/architecture.md`, `docs/features/template.md`, and other documentation only when
   relevant to the task.
5. Keep the same project working tree when resuming across chats or accounts. Repository files preserve checkpoints;
   chat history and local Codex Memory are not the recovery source of truth.

## Approval and write scope

- Before any repository write, show the user the exact file paths and intended changes, then wait for approval.
- For a task expected to change more than three files, first draft the plan and file scope in chat. Ask approval to save
  the plan. After saving it, wait for separate approval of the first implementation step.
- For a task expected to change three or fewer files, present the exact file list and intended changes and wait for
  approval before writing.
- For planned work, each implementation approval covers only the files listed for that step. Include any required
  handoff update in that list. Ask again if the scope or file list expands.
- Ask for explicit approval before migrations, adding dependencies, deleting files, committing, pushing, or deploying.
  Do not stage, commit, or push unless explicitly authorized.
- Approval to change files does not imply approval for unrelated commands or side effects.

## Plans and checkpoints

- Create a plan when more than three files are expected to change. A plan contains the goal, scope, exact files,
  checkbox steps, acceptance checks, applicable tests, and current status.
- Keep detailed task progress in the active plan. Keep handoff concise: active plan link, last completed step, next
  action, changed or uncommitted paths, known failures, and pending checks.
- Update handoff after each completed approved plan step and before long-running commands. Include the handoff write in
  the approved file scope.
- At completion, mark the plan complete and handoff idle or point handoff to the next active plan.

## Feature documentation and tests

- Every feature behavior or architectural shift must be documented under `docs/`. For a new or materially changed
  feature, use `docs/features/template.md`; keep descriptions technical and include Mermaid diagrams where applicable.
- The feature document's test matrix must map every new or changed behavior-bearing component to relevant test file
  paths and scenarios. Cover it directly or explain which higher-level test meaningfully covers it.
- Test the layers that own changed behavior as applicable: domain models and use cases, data mappers and repositories,
  Bloc/Cubit transitions, widget rendering and interactions, and integration behavior.
- When Drift schema or persistence behavior changes, cover persistence behavior and supported migrations. Follow
  `AGENTS.md` for required code generation; do not treat generated files as hand-edited sources.
- For bug fixes, include a regression test at the layer where the behavior is owned when feasible. Do not substitute a
  global coverage percentage for component-level test mapping.
- Run focused checks for changed behavior and report exactly what ran and what did not. Use broader checks only when the
  scope warrants them. Do not run builds, code generation, or application tests for documentation/configuration-only
  changes unless asked.

## ADRs and memory

- Write an ADR for a hard-to-reverse or cross-cutting architectural decision, including persistence/data-model
  boundaries or external contracts when the choice has lasting impact. Do not create ADRs for routine implementation
  details.
- Accepted ADRs are immutable. Record a new ADR that supersedes the old one instead of editing it.
- `docs/memory/MEMORY.md` is a short index (maximum 50 lines). `project.md` stores stable facts and links to their
  source of truth. Never store secrets, transient logs, or task progress in project memory.

## Optional read-only subagents

- Do not spawn a subagent by default. Use `repo_scout` for a bounded, independent codebase investigation and `reviewer`
  for a meaningful or high-risk approved diff.
- Run at most one subagent at a time. Wait for it to finish before the primary agent writes.
- Before spawning, verify that the parent local Codex session is technically in read-only mode. Subagents inherit the
  parent session's sandbox and permissions; instructions inside their TOML files do not enforce read-only access. If the
  UI or active profile does not provide a read-only mode, do not spawn one.
- Keep the result within 15 lines, with file paths and symbols. The primary agent owns any follow-up edits and runs
  approved checks.
