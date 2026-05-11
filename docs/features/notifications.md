# Feature: Task Deadline Notifications
- **Goal:** Show local push notifications for task deadlines and open the corresponding task in UI when notification is tapped.
- **UseCases:** Schedule reminders 30 minutes before deadline, schedule reminder at deadline, cancel/reschedule reminders on task changes, navigate to task list and expand target task after tap.
- **State:** `TaskBloc` stores one-time UI focus trigger (`highlightedTaskId`, `highlightedTaskVersion`) used by `MainScreen` and `HomeTasksScreen`.
- **API Endpoints:** None (local notifications via `flutter_local_notifications`).
