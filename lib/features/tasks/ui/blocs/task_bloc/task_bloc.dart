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

  // Подписки на стримы
  StreamSubscription? _notificationTapSubscription;
  StreamSubscription<List<Task>>? _tasksSubscription;

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
  }) : super(const TaskState()) {
    // Настройки списка и конфигурация
    on<LoadTasksStarted>(_onLoadTasks);
    on<SortChanged>(_onSortChanged);
    on<FilterChanged>(_onFilterChanged);
    on<SearchChanged>(_onSearchChanged);
    on<NotificationTaskOpened>(_onNotificationTaskOpened);
    on<TasksRefreshRequested>(_onTasksRefreshRequested);

    // Внутренние события синхронизации данных из Stream -> Bloc
    on<_TasksUpdatedFromDatabase>(_onTasksUpdatedFromDatabase);
    on<_TasksLoadFailed>(_onTasksLoadFailed);

    // CRUD операции
    on<TaskAdded>(_onAddTask);
    on<TaskUpdated>(_onUpdateTask);
    on<TaskDeleted>(_onDeleteTask);
    on<TaskPinToggled>(_onToggleTaskPin);

    // Очистка стейта
    on<ErrorCleared>((event, emit) => emit(state.copyWith(errorType: null)));
    on<ActionCleared>(
      (event, emit) => emit(state.copyWith(lastAction: TaskAction.none, lastActionTaskTitle: null)),
    );

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

  // --- РЕАКТИВНОЕ УПРАВЛЕНИЕ СТРИМОМ БАЗЫ ДАННЫХ ---

  Future<void> _onLoadTasks(LoadTasksStarted event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.loading));
    try {
      // Подгружаем сохраненные настройки отображения из SharedPreferences
      final preferences = await getTaskViewPreferencesUseCase();

      emit(
        state.copyWith(
          sortType: preferences.sortType,
          sortDirection: preferences.sortDirection,
          filterType: preferences.filterType,
        ),
      );

      // Запускаем реактивный стрим базы данных
      _restartTasksSubscription();
    } catch (e, s) {
      _logError('loadTasks', e, s);
      emit(state.copyWith(status: TaskStatus.failure, errorType: TaskErrorType.load));
    }
  }

  void _restartTasksSubscription() {
    _tasksSubscription?.cancel();

    _tasksSubscription =
        watchTasksUseCase(
          searchQuery: state.searchQuery,
          filterType: state.filterType,
          sortType: state.sortType,
          sortDirection: state.sortDirection,
        ).listen(
          (filteredTasks) => add(_TasksUpdatedFromDatabase(filteredTasks)),
          onError: (Object e, StackTrace s) => add(_TasksLoadFailed(e, s)),
        );
  }

  void _onTasksUpdatedFromDatabase(_TasksUpdatedFromDatabase event, Emitter<TaskState> emit) {
    emit(
      state.copyWith(
        status: TaskStatus.success,
        tasks: event.tasks, // База вернула уже готовый отсортированный массив
      ),
    );
  }

  void _onTasksLoadFailed(_TasksLoadFailed event, Emitter<TaskState> emit) {
    _logError('watchTasks', event.error, event.stackTrace);
    emit(state.copyWith(status: TaskStatus.failure, errorType: TaskErrorType.load));
  }

  // --- ИЗМЕНЕНИЕ ФИЛЬТРОВ И СОРТИРОВОК (ПЕРЕЗАПУСКАЮТ СТРИМ) ---

  Future<void> _onSortChanged(SortChanged event, Emitter<TaskState> emit) async {
    TaskSortDirection newDirection = state.sortDirection;
    if (state.sortType == event.sortType) {
      newDirection = state.sortDirection == TaskSortDirection.topToBottom
          ? TaskSortDirection.bottomToTop
          : TaskSortDirection.topToBottom;
    } else {
      newDirection = TaskSortDirection.topToBottom;
    }

    emit(
      state.copyWith(
        status: TaskStatus.loading,
        sortType: event.sortType,
        sortDirection: newDirection,
        lastAction: TaskAction.none,
        lastActionTaskTitle: null,
      ),
    );

    _restartTasksSubscription();

    await _saveTaskViewPreferences(
      sortType: event.sortType,
      sortDirection: newDirection,
      filterType: state.filterType,
    );
  }

  Future<void> _onFilterChanged(FilterChanged event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.loading, filterType: event.filterType));

    _restartTasksSubscription();

    await _saveTaskViewPreferences(
      sortType: state.sortType,
      sortDirection: state.sortDirection,
      filterType: event.filterType,
    );
  }

  Future<void> _onSearchChanged(SearchChanged event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.loading, searchQuery: event.query));
    _restartTasksSubscription();
  }

  Future<void> _onNotificationTaskOpened(
    NotificationTaskOpened event,
    Emitter<TaskState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TaskStatus.loading,
        filterType: TaskFilterType.all,
        searchQuery: '',
        highlightedTaskId: event.taskId,
        highlightedTaskVersion: state.highlightedTaskVersion + 1,
      ),
    );

    _restartTasksSubscription();
  }

  // --- ЧИСТЫЕ CRUD ОБРАБОТЧИКИ (ОРИЕНТИРУЮТСЯ НА STATE.TASKS) ---

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
      final taskToUpdate = state.tasks.cast<Task?>().firstWhere(
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

      await updateTaskUseCase(updatedTask);
    } catch (e, s) {
      _logError('toggleTaskPin', e, s);
      emit(state.copyWith(errorType: TaskErrorType.update, status: TaskStatus.failure));
    }
  }

  // --- УТИЛИТЫ ---

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
    _tasksSubscription?.cancel(); // Глушим стрим базы данных при закрытии Блока
    return super.close();
  }
}

// --- ВНУТРЕННИЕ ИВЕНТЫ СИНХРОНИЗАЦИИ ---

class _TasksUpdatedFromDatabase extends TaskEvent {
  final List<Task> tasks;

  const _TasksUpdatedFromDatabase(this.tasks);
}

class _TasksLoadFailed extends TaskEvent {
  final Object error;
  final StackTrace stackTrace;

  const _TasksLoadFailed(this.error, this.stackTrace);
}
