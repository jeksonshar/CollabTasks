# ADR 0001: Adopt a Repository-Scoped Codex Workflow

- **Status:** Accepted
- **Date:** 2026-11-08
- **Accepted by:** User approval in the Codex workflow setup session
- **Supersedes:** None
- **Superseded by:** None

## Context

Codex work spans small changes and larger multi-file features. The user needs explicit control over repository writes,
durable checkpoints that survive chat or account switching in the same working tree, and focused feature documentation
with component-level test coverage.

## Decision

Use the repository-scoped workflow in `docs/codex-workflow.md`. The primary agent is the sole writer. Every repository
write requires prior approval of its exact file scope. Work expected to change more than three files requires a reviewed
plan before implementation. Optional `repo_scout` and `reviewer` subagents may only be used under a technically
read-only parent session, one at a time.

Feature changes follow `docs/features/template.md`, which maps behavior-bearing components to applicable tests. Plans
track detailed task progress; handoff records the latest concise recovery point; ADRs preserve hard-to-reverse
decisions; project memory holds stable facts and source links.

## Consequences

- The user reviews exact file scopes before changes, including plan and checkpoint writes.
- Multi-file work requires additional approval gates and can take more turns.
- Subagents are optional and may be unavailable when a read-only parent permission profile is not available.
- Feature documentation and tests must identify the components and behaviors covered.

## Alternatives considered

- Rely only on chat history: rejected because it does not provide a portable repository checkpoint across account
  switches.
- Always delegate implementation to a worker: rejected because it adds token cost and creates overlapping write
  ownership.
- Run subagents without a read-only parent permission boundary: rejected because agent-file instructions alone do not
  technically prevent writes.
