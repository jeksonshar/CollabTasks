# Subtasks

## Goal
Add optional subtasks inside a task with completion checkbox support.

## Behavior
- A task can have zero or more subtasks.
- Subtasks can be added, renamed, and removed in the task dialog.
- Subtask completion checkbox is editable in task edit mode.
- When a task card is expanded, its subtasks are shown with completed/incomplete state.

## Data
- Domain model: `TaskSubtask { id, title, isCompleted }`.
- `Task` now contains `List<TaskSubtask> subtasks`.
- `TaskDraft` now contains `List<TaskSubtask> subtasks`.
- Local DB stores subtasks in `task_entity.task_subtasks` as JSON list.

## Migration
- Drift schema upgraded to version `8`.
- Migration `from < 8` adds `task_subtasks` column with default `[]`.
