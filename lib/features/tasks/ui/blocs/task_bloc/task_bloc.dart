import 'dart:async';

import 'package:collab_tasks/core/enums/task_error_type.dart';
import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/settings/domain/models/task_view_preferences.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_task_view_preferences_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_task_view_preferences_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/add_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/cancel_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/consume_initial_notification_payload_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/get_notification_tap_stream_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/schedule_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/sync_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/update_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/watch_tasks_use_case.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final WatchTasksUseCase watchTasksUseCase;
  final AddTaskUseCase addTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final GetTaskViewPreferencesUseCase getTaskViewPreferencesUseCase;
  final SetTaskViewPreferencesUseCase setTaskViewPreferencesUseCase;
  final ScheduleTaskNotificationsUseCase scheduleTaskNotificationsUseCase;
  final CancelTaskNotificationsUseCase cancelTaskNotificationsUseCase;
  final SyncTaskNotificationsUseCase syncTaskNotificationsUseCase;
  final GetNotificationTapStreamUseCase getNotificationTapStreamUseCase;
  final ConsumeInitialNotificationPayloadUseCase consumeInitialNotificationPayloadUseCase;
  final String notificationReminderTitle;
  final String notificationDeadlineTitle;

  StreamSubscription? _notificationTapSubscription;

  TaskBloc({
    required this.watchTasksUseCase,
    required this.addTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.getTaskViewPreferencesUseCase,
    required this.setTaskViewPreferencesUseCase,
    required this.scheduleTaskNotificationsUseCase,
    required this.cancelTaskNotificationsUseCase,
    required this.syncTaskNotificationsUseCase,
    required this.getNotificationTapStreamUseCase,
    required this.consumeInitialNotificationPayloadUseCase,
    required this.notificationReminderTitle,
    required this.notificationDeadlineTitle,
  }) : super(const TaskState()) {
    // 1. Main Event: Base Surveillance Launch
    on<LoadTasksStarted>(_onLoadTasks);
    // 2. The remaining events now only perform an Action.
    on<TaskAdded>(_onAddTask);
    on<TaskUpdated>(_onUpdateTask);
    on<TaskDeleted>(_onDeleteTask);
    on<TaskPinToggled>(_onToggleTaskPin);
    // UI events
    on<SortChanged>(_onSortChanged);
    on<FilterChanged>(_onFilterChanged);
    on<SearchChanged>((event, emit) => emit(state.copyWith(searchQuery: event.query)));
    on<ErrorCleared>((event, emit) => emit(state.copyWith(errorType: null)));
    on<ActionCleared>(
      (event, emit) => emit(state.copyWith(lastAction: TaskAction.none, lastActionTaskTitle: null)),
    );
    on<NotificationTaskOpened>(_onNotificationTaskOpened);

    _initNotificationListeners();
  }

  void _initNotificationListeners() {
    if (isClosed) return;

    _notificationTapSubscription = getNotificationTapStreamUseCase().listen((payload) {
      if (!isClosed) {
        add(NotificationTaskOpened(payload.taskId));
      }
    });

    final initialPayload = consumeInitialNotificationPayloadUseCase();
    if (!isClosed && initialPayload != null) {
      add(NotificationTaskOpened(initialPayload.taskId));
    }
  }

  Future<void> _onLoadTasks(LoadTasksStarted event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.loading));
    try {
      final preferences = await getTaskViewPreferencesUseCase();
      // We set the initial settings
      emit(
        state.copyWith(
          sortType: preferences.sortType,
          sortDirection: preferences.sortDirection,
          filterType: preferences.filterType,
        ),
      );

      // SUBSCRIBE TO STREAM
      // This block will work forever as long as Bloc is alive.
      // Every change in the database will call this code.
      await emit.forEach<List<Task>>(
        watchTasksUseCase(),
        onData: (tasks) {
          // With each database update, we synchronize notifications and update the state
          _syncNotifications(tasks);

          debugPrint('TaskBloc.loadTasks SUCCESS: ${state.tasks}');

          return state.copyWith(
            status: TaskStatus.success,
            tasks: _sortTasks(tasks, state.sortType, state.sortDirection),
          );
        },
        onError: (e, s) {
          _logError('watchTasks', e, s);
          return state.copyWith(status: TaskStatus.failure, errorType: TaskErrorType.load);
        },
      );
    } catch (e, s) {
      _logError('loadTasks', e, s);
      emit(state.copyWith(status: TaskStatus.failure, errorType: TaskErrorType.load));
    }
  }

  Future<void> _onAddTask(TaskAdded event, Emitter<TaskState> emit) async {
    final task = Task(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      title: event.draft.title,
      description: event.draft.descriptionJson,
      priority: event.draft.priority,
      attachments: event.draft.attachments,
      subtasks: event.draft.subtasks,
      isCompleted: event.draft.isCompleted,
      deadline: event.draft.deadline,
    );

    try {
      await addTaskUseCase(task);
      try {
        await scheduleTaskNotificationsUseCase(
          task,
          reminderTitle: notificationReminderTitle,
          deadlineTitle: notificationDeadlineTitle,
        );
      } catch (e, s) {
        _logError('syncNotifications', e, s);
      }

      // With the watcher we only notify about the fact of the action
      emit(state.copyWith(lastAction: TaskAction.add, lastActionTaskTitle: task.title));
    } catch (e, s) {
      _logError('_onAddTask', e, s);
      emit(state.copyWith(errorType: TaskErrorType.add, status: TaskStatus.failure));
    }
  }

  Future<void> _onUpdateTask(TaskUpdated event, Emitter<TaskState> emit) async {
    try {
      // 1. Find the old task to save the 'isPinned' status (if it's not in the Draft)
      // Do this BEFORE updating to avoid a StateError if the stream updates too quickly
      final taskToUpdate = state.tasks.cast<Task?>().firstWhere(
        (t) => t?.id == event.id,
        orElse: () => null,
      );

      if (taskToUpdate == null) return;
      // 2. We are creating an updated model
      final updatedTask = Task(
        id: event.id,
        createdAt: event.createdAt,
        title: event.draft.title,
        description: event.draft.descriptionJson,
        priority: event.draft.priority,
        attachments: event.draft.attachments,
        subtasks: event.draft.subtasks,
        isCompleted: event.draft.isCompleted,
        deadline: event.draft.deadline,
        isPinned: taskToUpdate.isPinned,
      );

      // 3. Sending to the database via UseCase
      await updateTaskUseCase(updatedTask);
      // 4. Synchronizing notifications
      await scheduleTaskNotificationsUseCase(
        updatedTask,
        reminderTitle: notificationReminderTitle,
        deadlineTitle: notificationDeadlineTitle,
      );

      // 5. We only notify about the fact of the action for the UI (for example, to show the Snack bar)
      // The tasks list will be updated automatically via WatchTasksUseCase
      emit(state.copyWith(lastAction: TaskAction.update, lastActionTaskTitle: updatedTask.title));
    } catch (e, s) {
      _logError('updateTask', e, s);
      emit(state.copyWith(errorType: TaskErrorType.update, status: TaskStatus.failure));
    }
  }

  Future<void> _onDeleteTask(TaskDeleted event, Emitter<TaskState> emit) async {
    try {
      final taskToDelete = state.tasks.cast<Task?>().firstWhere(
        (t) => t?.id == event.id,
        orElse: () => null,
      );

      if (taskToDelete == null) return;
      final taskTitle = taskToDelete.title;

      await deleteTaskUseCase(event.id);
      await cancelTaskNotificationsUseCase(event.id);

      emit(state.copyWith(lastAction: TaskAction.delete, lastActionTaskTitle: taskTitle));
    } catch (e, s) {
      _logError('deleteTask', e, s);
      emit(state.copyWith(errorType: TaskErrorType.delete, status: TaskStatus.failure));
    }
  }

  Future<void> _onToggleTaskPin(TaskPinToggled event, Emitter<TaskState> emit) async {
    try {
      final task = state.tasks.firstWhere((t) => t.id == event.id);
      final updatedTask = task.copyWith(isPinned: !task.isPinned);

      // just update BD
      await updateTaskUseCase(updatedTask);
    } catch (e, s) {
      _logError('toggleTaskPin', e, s);
      emit(state.copyWith(errorType: TaskErrorType.update, status: TaskStatus.failure));
    }
  }

  Future<void> _onSortChanged(SortChanged event, Emitter<TaskState> emit) async {
    TaskSortDirection newDirection = state.sortDirection;
    if (state.sortType == event.sortType) {
      newDirection = state.sortDirection.isAscending
          ? TaskSortDirection.bottomToTop
          : TaskSortDirection.topToBottom;
    } else {
      newDirection = TaskSortDirection.topToBottom;
    }

    emit(
      state.copyWith(
        sortType: event.sortType,
        sortDirection: newDirection,
        tasks: _sortTasks(state.tasks, event.sortType, newDirection),
        lastAction: TaskAction.none,
        lastActionTaskTitle: null,
      ),
    );

    await _saveTaskViewPreferences(
      sortType: event.sortType,
      sortDirection: newDirection,
      filterType: state.filterType,
    );
  }

  Future<void> _onFilterChanged(FilterChanged event, Emitter<TaskState> emit) async {
    emit(state.copyWith(filterType: event.filterType));
    await _saveTaskViewPreferences(
      sortType: state.sortType,
      sortDirection: state.sortDirection,
      filterType: event.filterType,
    );
  }

  Future<void> _onNotificationTaskOpened(
    NotificationTaskOpened event,
    Emitter<TaskState> emit,
  ) async {
    emit(
      state.copyWith(
        filterType: TaskFilterType.all,
        searchQuery: '',
        highlightedTaskId: event.taskId,
        highlightedTaskVersion: state.highlightedTaskVersion + 1,
      ),
    );
  }

  Future<void> _saveTaskViewPreferences({
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
    required TaskFilterType filterType,
  }) async {
    try {
      await setTaskViewPreferencesUseCase(
        TaskViewPreferences(
          sortType: sortType,
          sortDirection: sortDirection,
          filterType: filterType,
        ),
      );
    } catch (e, s) {
      _logError('saveTaskViewPreferences', e, s);
    }
  }

  List<Task> _sortTasks(List<Task> tasks, TaskSortType type, TaskSortDirection dir) {
    final pinned = tasks.where((t) => t.isPinned).toList();
    final others = tasks.where((t) => !t.isPinned).toList();

    int compare<T extends Comparable>(T a, T b) {
      return dir.isAscending ? b.compareTo(a) : a.compareTo(b);
    }

    void sortList(List<Task> list) {
      switch (type) {
        case TaskSortType.byDateCreated:
          list.sort((a, b) => compare(a.createdAt, b.createdAt));
        case TaskSortType.byPriority:
          list.sort((a, b) => compare(a.priority, b.priority));
        case TaskSortType.byTitle:
          list.sort((a, b) => compare(a.title, b.title));
      }
    }

    sortList(pinned);
    sortList(others);

    return [...pinned, ...others];
  }

  Future<void> _syncNotifications(List<Task> tasks) async {
    try {
      await syncTaskNotificationsUseCase(
        tasks,
        reminderTitle: notificationReminderTitle,
        deadlineTitle: notificationDeadlineTitle,
      );
    } catch (e, s) {
      _logError('syncNotifications', e, s);
    }
  }

  void _logError(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint(
      'TaskBloc.$context ERROR: $error'
      '${stackTrace != null ? '\n$stackTrace' : ''}',
    );
  }

  @override
  Future<void> close() {
    _notificationTapSubscription?.cancel();
    return super.close();
  }
}
