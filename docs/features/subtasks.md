# Subtasks

## Goal
Add optional subtasks inside a task with completion checkbox support and confirmation dialogs for deletion.

## Behavior
- A task can have zero or more subtasks.
- Subtasks can be added, renamed, and removed in the task dialog.
- Subtask completion checkbox is editable in task edit mode.
- When a task card is expanded, its subtasks are shown with completed/incomplete state.
- When a subtask is deleted, a confirmation dialog appears asking for user confirmation.

## Data
- Domain model: `TaskSubtask { id, title, isCompleted }`.
- `Task` now contains `List<TaskSubtask> subtasks`.
- `TaskDraft` now contains `List<TaskSubtask> subtasks`.
- Local DB stores subtasks in `task_entity.task_subtasks` as JSON list.

## State Management
- Subtask removal is managed through a reusable `ConfirmationDialogBloc` which handles confirmation dialog state.
- The dialog is generic and can be reused for other deletion confirmations (files, etc.).
- `TaskDialog` provides the `ConfirmationDialogBloc` via `BlocProvider` to all child widgets.

## Migration
- Drift schema upgraded to version `8`.
- Migration `from < 8` adds `task_subtasks` column with default `[]`.

## Localization
- `confirmDeleteSubtask`: "Are you sure you want to delete the subtask?" (en) / "Вы уверены, что хотите удалить подтаск?" (ru) / "Ви впевнені, що хочете видалити підзадачу?" (uk)

