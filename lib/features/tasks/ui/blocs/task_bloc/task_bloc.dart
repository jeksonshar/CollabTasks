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
import 'package:collab_tasks/features/tasks/domain/use_cases/filter_and_sort_tasks_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/get_notification_tap_stream_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/schedule_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/sync_tasks_use_case.dart';
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
  final GetNotificationTapStreamUseCase getNotificationTapStreamUseCase;
  final ConsumeInitialNotificationPayloadUseCase consumeInitialNotificationPayloadUseCase;
  final SyncTasksUseCase syncTasksUseCase;

  final FilterAndSortTasksUseCase filterAndSortTasksUseCase;

  StreamSubscription? _notificationTapSubscription;

  // Кэш для исходного списка из БД, чтобы фильтровать/сортировать его на лету
  List<Task> _rawTasks = [];

  TaskBloc({
    required this.watchTasksUseCase,
    required this.addTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.getTaskViewPreferencesUseCase,
    required this.setTaskViewPreferencesUseCase,
    required this.scheduleTaskNotificationsUseCase,
    required this.cancelTaskNotificationsUseCase,
    required this.getNotificationTapStreamUseCase,
    required this.consumeInitialNotificationPayloadUseCase,
    required this.syncTasksUseCase,
    required this.filterAndSortTasksUseCase,
  }) : super(const TaskState()) {
    on<LoadTasksStarted>(_onLoadTasks);
    on<TasksRefreshRequested>(_onTasksRefreshRequested);
    on<TaskAdded>(_onAddTask);
    on<TaskUpdated>(_onUpdateTask);
    on<TaskDeleted>(_onDeleteTask);
    on<TaskPinToggled>(_onToggleTaskPin);
    on<SortChanged>(_onSortChanged);
    on<FilterChanged>(_onFilterChanged);
    on<SearchChanged>(_onSearchChanged);
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
      emit(
        state.copyWith(
          sortType: preferences.sortType,
          sortDirection: preferences.sortDirection,
          filterType: preferences.filterType,
        ),
      );

      await emit.forEach<List<Task>>(
        watchTasksUseCase(),
        onData: (tasks) {
          // Сохраняем актуальный сырой список из БД в кэш класса
          _rawTasks = tasks;

          // Пропускаем сырые данные через UseCase
          final processedTasks = filterAndSortTasksUseCase(
            tasks: _rawTasks,
            filterType: state.filterType,
            sortType: state.sortType,
            sortDirection: state.sortDirection,
            searchQuery: state.searchQuery,
          );

          return state.copyWith(status: TaskStatus.success, tasks: processedTasks);
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
        await scheduleTaskNotificationsUseCase(task);
      } catch (e, s) {
        _logError('scheduleNotifications', e, s);
      }
      emit(state.copyWith(lastAction: TaskAction.add, lastActionTaskTitle: task.title));
    } catch (e, s) {
      _logError('_onAddTask', e, s);
      emit(state.copyWith(errorType: TaskErrorType.add, status: TaskStatus.failure));
    }
  }

  Future<void> _onUpdateTask(TaskUpdated event, Emitter<TaskState> emit) async {
    try {
      // Ищем в _rawTasks (кэше), чтобы гарантировать точность данных до отправки в БД
      final taskToUpdate = _rawTasks.cast<Task?>().firstWhere(
        (t) => t?.id == event.id,
        orElse: () => null,
      );

      if (taskToUpdate == null) return;

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

      await updateTaskUseCase(updatedTask);
      await scheduleTaskNotificationsUseCase(updatedTask);

      emit(state.copyWith(lastAction: TaskAction.update, lastActionTaskTitle: updatedTask.title));
    } catch (e, s) {
      _logError('updateTask', e, s);
      emit(state.copyWith(errorType: TaskErrorType.update, status: TaskStatus.failure));
    }
  }

  Future<void> _onDeleteTask(TaskDeleted event, Emitter<TaskState> emit) async {
    try {
      final taskToDelete = _rawTasks.cast<Task?>().firstWhere(
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
      final task = _rawTasks.firstWhere((t) => t.id == event.id);
      final updatedTask = task.copyWith(isPinned: !task.isPinned);

      await updateTaskUseCase(updatedTask);
    } catch (e, s) {
      _logError('toggleTaskPin', e, s);
      emit(state.copyWith(errorType: TaskErrorType.update, status: TaskStatus.failure));
    }
  }

  Future<void> _onSortChanged(SortChanged event, Emitter<TaskState> emit) async {
    TaskSortDirection newDirection = state.sortDirection;
    if (state.sortType == event.sortType) {
      newDirection = state.sortDirection == TaskSortDirection.topToBottom
          ? TaskSortDirection.bottomToTop
          : TaskSortDirection.topToBottom;
    } else {
      newDirection = TaskSortDirection.topToBottom;
    }

    final processedTasks = filterAndSortTasksUseCase(
      tasks: _rawTasks,
      filterType: state.filterType,
      sortType: event.sortType,
      sortDirection: newDirection,
      searchQuery: state.searchQuery,
    );

    emit(
      state.copyWith(
        sortType: event.sortType,
        sortDirection: newDirection,
        tasks: processedTasks,
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
    final processedTasks = filterAndSortTasksUseCase(
      tasks: _rawTasks,
      filterType: event.filterType,
      sortType: state.sortType,
      sortDirection: state.sortDirection,
      searchQuery: state.searchQuery,
    );

    emit(state.copyWith(filterType: event.filterType, tasks: processedTasks));

    await _saveTaskViewPreferences(
      sortType: state.sortType,
      sortDirection: state.sortDirection,
      filterType: event.filterType,
    );
  }

  Future<void> _onSearchChanged(SearchChanged event, Emitter<TaskState> emit) async {
    final processedTasks = filterAndSortTasksUseCase(
      tasks: _rawTasks,
      filterType: state.filterType,
      sortType: state.sortType,
      sortDirection: state.sortDirection,
      searchQuery: event.query,
    );

    emit(state.copyWith(searchQuery: event.query, tasks: processedTasks));
  }

  Future<void> _onNotificationTaskOpened(
    NotificationTaskOpened event,
    Emitter<TaskState> emit,
  ) async {
    // При открытии уведомления сбрасываем фильтры и поиск
    final processedTasks = filterAndSortTasksUseCase(
      tasks: _rawTasks,
      filterType: TaskFilterType.all,
      sortType: state.sortType,
      sortDirection: state.sortDirection,
      searchQuery: '',
    );

    emit(
      state.copyWith(
        filterType: TaskFilterType.all,
        searchQuery: '',
        tasks: processedTasks,
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

  Future<void> _onTasksRefreshRequested(
    TasksRefreshRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await syncTasksUseCase();
    } catch (e, s) {
      _logError('refreshTasks', e, s);
    } finally {
      event.completer?.complete();
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
