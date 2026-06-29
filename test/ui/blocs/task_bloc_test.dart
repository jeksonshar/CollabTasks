import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/core/enums/task_error_type.dart';
import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/settings/domain/models/task_view_preferences.dart';
import 'package:collab_tasks/features/tasks/data/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/features/tasks/data/notifications/task_notification_event_type.dart';
import 'package:collab_tasks/features/tasks/domain/models/errors/data_exception.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_draft.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';
import '../../mocks/mock_use_cases.dart';

void main() {
  late TaskBloc taskBloc;
  late MockWatchTasksUseCase mockWatchTasksUseCase;
  late MockAddTaskUseCase mockAddTaskUseCase;
  late MockUpdateTaskUseCase mockUpdateTasksUseCase;
  late MockDeleteTaskUseCase mockDeleteTasksUseCase;
  late MockGetTaskViewPreferencesUseCase mockGetPrefsUseCase;
  late MockSetTaskViewPreferencesUseCase mockSetPrefsUseCase;
  late MockScheduleTaskNotificationsUseCase mockScheduleNotificationsUseCase;
  late MockCancelTaskNotificationsUseCase mockCancelTaskNotificationsUseCase;
  late MockGetNotificationTapStreamUseCase mockGetNotificationStreamUseCase;
  late MockConsumeInitialNotificationPayloadUseCase mockConsumePayloadUseCase;
  late MockSyncTasksUseCase mockSyncTasksUseCase;
  late StreamController<NotificationTapPayload> notificationController;

  setUpAll(() {
    registerFallbackValue(TaskFilterType.all);
    registerFallbackValue(TaskSortType.byDateCreated);
    registerFallbackValue(TaskSortDirection.topToBottom);
    // Registering default values for complex types
    registerTestFallbackValues();
  });

  void initMocks() {
    mockWatchTasksUseCase = MockWatchTasksUseCase();
    mockAddTaskUseCase = MockAddTaskUseCase();
    mockUpdateTasksUseCase = MockUpdateTaskUseCase();
    mockDeleteTasksUseCase = MockDeleteTaskUseCase();
    mockGetPrefsUseCase = MockGetTaskViewPreferencesUseCase();
    mockSetPrefsUseCase = MockSetTaskViewPreferencesUseCase();
    mockScheduleNotificationsUseCase = MockScheduleTaskNotificationsUseCase();
    mockCancelTaskNotificationsUseCase = MockCancelTaskNotificationsUseCase();
    mockGetNotificationStreamUseCase = MockGetNotificationTapStreamUseCase();
    mockConsumePayloadUseCase = MockConsumeInitialNotificationPayloadUseCase();
    mockSyncTasksUseCase = MockSyncTasksUseCase();
    // Initialize the controller BEFORE creating the BLoC
    notificationController = StreamController<NotificationTapPayload>.broadcast();
  }

  void stubDefaultBehavior() {
    // Default settings for preferences
    when(() => mockGetPrefsUseCase()).thenAnswer(
      (_) async => const TaskViewPreferences(
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
        filterType: TaskFilterType.all,
      ),
    );
    when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});

    when(
      () => mockConsumePayloadUseCase(),
    ).thenReturn(null); // Emulating the absence of a cold start from a notification
    // 2. Futures for notification planning
    when(() => mockScheduleNotificationsUseCase(any())).thenAnswer((_) async => {});
    // 3. Rest
    when(() => mockCancelTaskNotificationsUseCase(any())).thenAnswer((_) async => {});
    when(() => mockSyncTasksUseCase()).thenAnswer((_) async => {});
    // Overriding behavior for notification tests
    when(() => mockGetNotificationStreamUseCase()).thenAnswer((_) => notificationController.stream);

    // Дефолтный стаб, чтобы Блок не падал при создании
    when(
      () => mockWatchTasksUseCase(
        searchQuery: any(named: 'searchQuery'),
        filterType: any(named: 'filterType'),
        sortType: any(named: 'sortType'),
        sortDirection: any(named: 'sortDirection'),
      ),
    ).thenAnswer((_) => const Stream.empty());
  }

  setUp(() {
    initMocks();
    stubDefaultBehavior();

    taskBloc = TaskBloc(
      watchTasksUseCase: mockWatchTasksUseCase,
      addTaskUseCase: mockAddTaskUseCase,
      updateTaskUseCase: mockUpdateTasksUseCase,
      deleteTaskUseCase: mockDeleteTasksUseCase,
      getTaskViewPreferencesUseCase: mockGetPrefsUseCase,
      setTaskViewPreferencesUseCase: mockSetPrefsUseCase,
      scheduleTaskNotificationsUseCase: mockScheduleNotificationsUseCase,
      cancelTaskNotificationsUseCase: mockCancelTaskNotificationsUseCase,
      getNotificationTapStreamUseCase: mockGetNotificationStreamUseCase,
      consumeInitialNotificationPayloadUseCase: mockConsumePayloadUseCase,
      syncTasksUseCase: mockSyncTasksUseCase,
    );
  });

  tearDown(() {
    notificationController.close();
    taskBloc.close();
  });

  group('TaskBloc 1 - LoadTasks and Reactive Stream', () {
    final tTasks = [
      Task(id: '1', title: 'Task 1', createdAt: DateTime.now(), description: 'some description'),
    ];

    blocTest<TaskBloc, TaskState>(
      'should go to success and update the task list when receiving data from the stream',
      build: () {
        // Настраиваем UseCase на ожидание вызова с дефолтными параметрами фильтрации
        when(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: TaskSortType.byDateCreated,
            sortDirection: TaskSortDirection.topToBottom,
          ),
        ).thenAnswer((_) => Stream.value(tTasks));

        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        // 1. Сначала Блок переходит в состояние загрузки
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        // 2. Затем Блок получает готовый список задач напрямую из UseCase без всяких ручных фильтраций
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks, 'tasks', tTasks) // Просто проверяем совпадение массивов
            .having((s) => s.sortType, 'sortType', TaskSortType.byDateCreated),
      ],
      verify: (_) {
        // Верифицируем, что UseCase был вызван ровно один раз с точными дефолтными параметрами
        verify(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: TaskSortType.byDateCreated,
            sortDirection: TaskSortDirection.topToBottom,
          ),
        ).called(1);
      },
    );
  });

  group('TaskBloc 2 - AddTask', () {
    const tDraft = TaskDraft(
      title: 'New Task',
      descriptionJson: 'description',
      priority: 2,
      attachments: [],
      subtasks: [],
      isCompleted: false,
    );

    blocTest<TaskBloc, TaskState>(
      'must call AddTaskUseCase and release the state with lastAction.add',
      build: () {
        // For this test, the stream may be empty.
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        when(() => mockAddTaskUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      act: (bloc) => bloc.add(const TaskAdded(tDraft)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.lastAction, 'lastAction', TaskAction.add)
            .having((s) => s.lastActionTaskTitle, 'title', 'New Task'),
      ],
      verify: (_) {
        // Check that UseCase was actually called
        verify(() => mockAddTaskUseCase(any())).called(1);
      },
    );
  });

  group('TaskBloc 3 - UpdateTask', () {
    final tTask = Task(
      id: '1',
      title: 'Old Title',
      createdAt: DateTime.now(),
      description: 'Description',
      isPinned: true, // Let's check that the PIN will be saved.
    );

    const tDraft = TaskDraft(
      title: 'New Title',
      descriptionJson: 'description',
      priority: 1,
      attachments: [],
      subtasks: [],
      isCompleted: true,
    );

    blocTest<TaskBloc, TaskState>(
      'must call UpdateTaskUseCase and update lastAction',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value([tTask]));
        when(() => mockUpdateTasksUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      seed: () => TaskState(tasks: [tTask], status: TaskStatus.success),
      act: (bloc) => bloc.add(TaskUpdated(tTask.id, tTask.createdAt, tDraft)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.lastAction, 'lastAction', TaskAction.update)
            .having((s) => s.lastActionTaskTitle, 'title', 'New Title'),
      ],
      verify: (_) {
        // We check that the task with the saved isPinned flag has been sent to UseCase
        verify(
          () => mockUpdateTasksUseCase(
            any(that: isA<Task>().having((t) => t.isPinned, 'isPinned', true)),
          ),
        ).called(1);
      },
    );
  });

  group('TaskBloc 4 - DeleteTask', () {
    final tTask = Task(
      id: '1',
      title: 'Task to Delete',
      createdAt: DateTime.now(),
      description: '',
    );

    blocTest<TaskBloc, TaskState>(
      'should successfully delete the task and release a state with the title of the deleted task',
      build: () {
        // Настраиваем UseCase удаления и отмены нотификаций
        when(() => mockDeleteTasksUseCase(any())).thenAnswer((_) async {});
        when(() => mockCancelTaskNotificationsUseCase(any())).thenAnswer((_) async {});

        return taskBloc;
      },
      // Сеем начальное состояние: Блок сразу «знает» про существование этой таски
      seed: () => TaskState(tasks: [tTask], status: TaskStatus.success),

      act: (bloc) => bloc.add(TaskDeleted(tTask.id)),

      expect: () => [
        isA<TaskState>()
            .having((s) => s.lastAction, 'lastAction', TaskAction.delete)
            .having((s) => s.lastActionTaskTitle, 'title', 'Task to Delete'),
      ],
      verify: (_) {
        verify(() => mockDeleteTasksUseCase(tTask.id)).called(1);
        verify(() => mockCancelTaskNotificationsUseCase(tTask.id)).called(1);
      },
    );
  });

  group('TaskBloc 5 - UI Events', () {
    blocTest<TaskBloc, TaskState>(
      'should invert the sort direction if the same type is selected and restart subscription',
      build: () {
        // Настраиваем UseCase на вызов с новыми параметрами сортировки
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byTitle,
            sortDirection: TaskSortDirection.bottomToTop, // Ожидаем инвертированную
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        sortType: TaskSortType.byTitle,
        sortDirection: TaskSortDirection.topToBottom,
        status: TaskStatus.success,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byTitle)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.sortDirection, 'direction', TaskSortDirection.bottomToTop)
            .having((s) => s.sortType, 'type', TaskSortType.byTitle),
      ],
      verify: (_) {
        // Проверяем, что стрим базы был перезапущен с новой инвертированной сортировкой
        verify(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byTitle,
            sortDirection: TaskSortDirection.bottomToTop,
          ),
        ).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should update filterType, save preferences, and restart subscription when FilterChanged is added',
      build: () {
        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: TaskFilterType.completed, // Ожидаем новый фильтр
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(filterType: TaskFilterType.all, status: TaskStatus.success),
      act: (bloc) => bloc.add(const FilterChanged(TaskFilterType.completed)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.filterType, 'filterType', TaskFilterType.completed),
      ],
      verify: (_) {
        // 1. Проверяем сохранение настроек
        verify(
          () => mockSetPrefsUseCase(
            any(
              that: isA<TaskViewPreferences>().having(
                (p) => p.filterType,
                'filter',
                TaskFilterType.completed,
              ),
            ),
          ),
        ).called(1);

        // 2. Проверяем, что Блок запросил у БД данные именно под новый фильтр
        verify(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: TaskFilterType.completed,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should call SyncTasksUseCase when TasksRefreshRequested is added',
      build: () {
        when(() => mockSyncTasksUseCase()).thenAnswer((_) async => {});
        return taskBloc;
      },
      act: (bloc) => bloc.add(const TasksRefreshRequested()),
      verify: (_) {
        verify(() => mockSyncTasksUseCase()).called(1);
      },
    );
  });

  group('TaskBloc 6 - Error Handling', () {
    blocTest<TaskBloc, TaskState>(
      'should maintain a failure status or issue an error state if AddTask fails',
      build: () {
        // Использован дефолтный стаб из setUp
        when(() => mockAddTaskUseCase(any())).thenThrow(DataException('Database Error'));
        return taskBloc;
      },
      act: (bloc) => bloc.add(
        const TaskAdded(
          TaskDraft(
            title: 'Error Task',
            descriptionJson: '',
            priority: 1,
            attachments: [],
            subtasks: [],
            isCompleted: false,
          ),
        ),
      ),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.failure)
            .having((s) => s.errorType, 'errorType', TaskErrorType.add),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should swallow notification error in _onAddTask and cover debugPrint',
      build: () {
        when(() => mockAddTaskUseCase(any())).thenAnswer((_) async => {});
        when(
          () => mockScheduleNotificationsUseCase(any()),
        ).thenThrow(Exception('Notification Service Unavailable'));
        return taskBloc;
      },
      act: (bloc) => bloc.add(
        const TaskAdded(
          TaskDraft(
            title: 'Notification Error Task',
            descriptionJson: '',
            priority: 1,
            attachments: [],
            subtasks: [],
            isCompleted: false,
          ),
        ),
      ),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.lastAction, 'lastAction', TaskAction.add)
            .having((s) => s.lastActionTaskTitle, 'title', 'Notification Error Task'),
      ],
      verify: (_) {
        verify(() => mockScheduleNotificationsUseCase(any())).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should maintain a failure status or issue an error state if UpdateTask fails',
      build: () {
        when(() => mockUpdateTasksUseCase(any())).thenThrow(DataException('Database Error'));
        return taskBloc;
      },
      seed: () => TaskState(
        tasks: [
          Task(id: '123', createdAt: DateTime.now(), title: 'Original title', description: ''),
        ],
      ),
      act: (bloc) => bloc.add(
        TaskUpdated(
          '123',
          DateTime.now(),
          const TaskDraft(
            title: 'Error Task',
            descriptionJson: '',
            priority: 1,
            attachments: [],
            subtasks: [],
            isCompleted: false,
          ),
        ),
      ),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.failure)
            .having((s) => s.errorType, 'errorType', TaskErrorType.update),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should emit failure when the stream itself emits an error (onError от listen)',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.error(Exception('Stream emitted error')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        // 1. Сначала уходим в лоадинг при старте
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        // 2. Затем асинхронно прилетает ошибка из стрима через внутренний ивент _TasksLoadFailed
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.failure)
            .having((s) => s.errorType, 'error', TaskErrorType.load),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should emit failure when deleteTaskUseCase fails',
      build: () {
        when(() => mockDeleteTasksUseCase(any())).thenThrow(DataException('Database Delete Error'));
        return taskBloc;
      },
      seed: () => TaskState(
        tasks: [
          Task(
            id: '999',
            title: 'Task to fail deletion',
            createdAt: DateTime.now(),
            description: '',
          ),
        ],
      ),
      act: (bloc) => bloc.add(const TaskDeleted('999')),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.failure)
            .having((s) => s.errorType, 'error', TaskErrorType.delete),
      ],
      verify: (_) {
        verify(() => mockDeleteTasksUseCase('999')).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'Should remain functional and emit loading state with new filter even if preference saving fails',
      build: () {
        when(() => mockSetPrefsUseCase(any())).thenThrow(Exception('Prefs Save Failed'));
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: TaskFilterType.completed,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(status: TaskStatus.success, filterType: TaskFilterType.all),
      act: (bloc) => bloc.add(const FilterChanged(TaskFilterType.completed)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.filterType, 'filterType', TaskFilterType.completed),
      ],
      verify: (_) {
        verify(
          () => mockSetPrefsUseCase(
            any(
              that: isA<TaskViewPreferences>().having(
                (f) => f.filterType,
                'filterType',
                TaskFilterType.completed,
              ),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should emit failure when TaskPinToggled fails at UseCase level',
      build: () {
        when(() => mockUpdateTasksUseCase(any())).thenThrow(Exception('Update Pin Failed'));
        return taskBloc;
      },
      seed: () => TaskState(
        tasks: [
          Task(
            id: 'pin_id',
            title: 'Task to Pin',
            createdAt: DateTime.now(),
            description: '',
            isPinned: false,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const TaskPinToggled('pin_id')),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.failure)
            .having((s) => s.errorType, 'error', TaskErrorType.update),
      ],
      verify: (_) {
        verify(() => mockUpdateTasksUseCase(any())).called(1);
      },
    );
  });

  group('TaskBloc 7 - Notifications Error', () {
    blocTest<TaskBloc, TaskState>(
      'should swallow the notification error without breaking the main flow',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        when(() => mockAddTaskUseCase(any())).thenAnswer((_) async => {});
        // Simulating an error in the notification manager
        when(
          () => mockScheduleNotificationsUseCase(any()),
        ).thenThrow(Exception('Notification Fail'));
        return taskBloc;
      },
      act: (bloc) => bloc.add(
        const TaskAdded(
          TaskDraft(
            title: 'Test',
            priority: 1,
            isCompleted: false,
            descriptionJson: '',
            attachments: [],
            subtasks: [],
          ),
        ),
      ),
      expect: () => [
        // We expect the status to still be success (or remain the same),
        // since the notification error in the catch block is only printed to the console
        isA<TaskState>().having((s) => s.lastAction, 'lastAction', TaskAction.add),
      ],
    );
  });

  group('TaskBloc 8 - Reactive Task Stream Notifications', () {
    blocTest<TaskBloc, TaskState>(
      'should not synchronize notifications when the task stream emits data',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer(
          (_) => Stream.value([
            Task(
              id: '1',
              title: 'Test',
              createdAt: DateTime.now(),
              description: '',
              priority: 1,
              attachments: const [],
              subtasks: const [],
              isCompleted: false,
            ),
          ]),
        );
        when(() => mockGetPrefsUseCase()).thenAnswer(
          (_) async => const TaskViewPreferences(
            sortType: TaskSortType.byDateCreated,
            sortDirection: TaskSortDirection.topToBottom,
            filterType: TaskFilterType.all,
          ),
        );

        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.success),
      ],
      verify: (_) {
        verifyNever(() => mockScheduleNotificationsUseCase(any()));
        verifyNever(() => mockCancelTaskNotificationsUseCase(any()));
      },
    );
  });

  group('TaskBloc 9 - Sorting Logic', () {
    final taskLow = Task(
      id: '1',
      title: 'A',
      priority: 1,
      createdAt: DateTime.now(),
      description: '',
    );
    final taskHigh = Task(
      id: '2',
      title: 'B',
      priority: 3,
      createdAt: DateTime.now(),
      description: '',
    );

    blocTest<TaskBloc, TaskState>(
      'should update sortType to byPriority and deliver sorted tasks from the restarted stream',
      build: () {
        // Настраиваем мок: когда Блок перезапустит стрим с сортировкой по приоритету,
        // мы имитируем, что SQL-движок базы данных вернул нам уже отсортированный список (сначала High, потом Low)
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byPriority, // Ожидаем именно этот тип
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value([taskHigh, taskLow])); // уже отсортированный список

        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      seed: () => TaskState(
        status: TaskStatus.success,
        tasks: [taskLow, taskHigh], // Исходный неотсортированный список
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byPriority)),
      expect: () => [
        // Ждем комбинированный стейт: статус loading + обновленный тип сортировки
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.sortType, 'type', TaskSortType.byPriority),

        // Как только Stream.value([taskHigh, taskLow]) мгновенно выплевывает данные,
        // срабатывает внутренний ивент обновления, и статус меняется на success с новым списком
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks.first.id, 'first task id', '2') // Теперь первая таска — taskHigh
            .having((s) => s.tasks.first.priority, 'first task priority', 3),
      ],
      verify: (_) {
        // Проверяем, что Блок действительно сходил в UseCase с правильным аргументом сортировки
        verify(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byPriority,
            sortDirection: any(named: 'sortDirection'),
          ),
        ).called(1);
      },
    );
  });

  group('TaskBloc 10 - Notifications & Deep Links', () {
    blocTest<TaskBloc, TaskState>(
      'should handle notification tap and initial payload, and restart stream with loading status',
      build: () {
        when(() => mockConsumePayloadUseCase()).thenReturn(
          const NotificationTapPayload(
            taskId: '123',
            eventType: TaskNotificationEventType.beforeDeadline,
          ),
        );

        // Настраиваем перезапуск стрима при открытии нотификаций (сброс фильтров)
        when(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());

        return TaskBloc(
          watchTasksUseCase: mockWatchTasksUseCase,
          scheduleTaskNotificationsUseCase: mockScheduleNotificationsUseCase,
          cancelTaskNotificationsUseCase: mockCancelTaskNotificationsUseCase,
          getNotificationTapStreamUseCase: mockGetNotificationStreamUseCase,
          consumeInitialNotificationPayloadUseCase: mockConsumePayloadUseCase,
          addTaskUseCase: mockAddTaskUseCase,
          updateTaskUseCase: mockUpdateTasksUseCase,
          deleteTaskUseCase: mockDeleteTasksUseCase,
          getTaskViewPreferencesUseCase: mockGetPrefsUseCase,
          setTaskViewPreferencesUseCase: mockSetPrefsUseCase,
          syncTasksUseCase: mockSyncTasksUseCase,
        );
      },
      act: (bloc) => notificationController.add(
        const NotificationTapPayload(
          taskId: '456',
          eventType: TaskNotificationEventType.beforeDeadline,
        ),
      ),
      expect: () => [
        // 1. Отрабатывает initialPayload из конструктора (Cold Start)
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.highlightedTaskId, 'initial', '123'),
        // 2. Прилетает событие из стрима тапов (App Open)
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.highlightedTaskId, 'stream', '456'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should reset lastAction when ActionCleared is added',
      build: () => taskBloc,
      seed: () => const TaskState(lastAction: TaskAction.add, lastActionTaskTitle: 'Test'),
      act: (bloc) => bloc.add(const ActionCleared()),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.lastAction, 'action', TaskAction.none)
            .having((s) => s.lastActionTaskTitle, 'title', null),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should emit failure when watchTasks throws exception',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenThrow(Exception('DB Crash'));
        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.failure)
            .having((s) => s.errorType, 'error', TaskErrorType.load),
      ],
    );

    // Pin Toggled
    final tTask = Task(
      id: '1',
      title: 'T',
      createdAt: DateTime.now(),
      isPinned: false,
      description: '',
    );
    blocTest<TaskBloc, TaskState>(
      'should toggle pin and call updateUseCase using seeded state tasks',
      build: () {
        when(() => mockUpdateTasksUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      seed: () => TaskState(status: TaskStatus.success, tasks: [tTask]),
      act: (bloc) => bloc.add(const TaskPinToggled('1')),
      expect: () => [],
      // Блок сам не эмитит стейты при тоггле пина (он ждет ответа от стрима БД)
      verify: (_) {
        verify(
          () => mockUpdateTasksUseCase(
            any(that: isA<Task>().having((t) => t.isPinned, 'pinned', true)),
          ),
        ).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should do nothing if task not found for update or delete',
      build: () => taskBloc,
      seed: () => const TaskState(tasks: []),
      act: (bloc) {
        bloc
          ..add(const TaskDeleted('unknown'))
          ..add(
            TaskUpdated(
              'unknown',
              DateTime.now(),
              const TaskDraft(
                title: '',
                descriptionJson: '',
                priority: 1,
                attachments: [],
                subtasks: [],
                isCompleted: false,
              ),
            ),
          );
      },
      expect: () => [],
    );
  });

  group('TaskBloc 11 - Missing Event Coverage', () {
    blocTest<TaskBloc, TaskState>(
      'should update searchQuery and move to loading state when SearchChanged is added',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: 'flutter examples',
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      act: (bloc) => bloc.add(const SearchChanged('flutter examples')),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.searchQuery, 'query', 'flutter examples'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should clear error when ErrorCleared is added',
      build: () => taskBloc,
      seed: () => const TaskState(status: TaskStatus.failure, errorType: TaskErrorType.load),
      act: (bloc) => bloc.add(ErrorCleared()),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.errorType, 'error', null)
            .having((s) => s.status, 'status', TaskStatus.failure),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should reset fields to default, set target ID, and emit loading status when NotificationTaskOpened is added',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        filterType: TaskFilterType.completed,
        searchQuery: 'old search query',
        highlightedTaskId: null,
        highlightedTaskVersion: 0,
      ),
      act: (bloc) => bloc.add(const NotificationTaskOpened('task-xyz')),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.filterType, 'filter reset to all', TaskFilterType.all)
            .having((s) => s.searchQuery, 'search cleared', '')
            .having((s) => s.highlightedTaskId, 'taskId set', 'task-xyz')
            .having((s) => s.highlightedTaskVersion, 'version incremented', 1),
      ],
      verify: (_) {
        // Верифицируем, что Блок действительно запросил чистый дефолтный стрим
        verify(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).called(1);
      },
    );
  });

  group('TaskBloc 12 - Edge Cases - Empty & Single Task', () {
    blocTest<TaskBloc, TaskState>(
      'should handle empty task list gracefully',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value([]));
        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks, 'tasks empty', isEmpty),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should handle single task without errors',
      build: () {
        final task = Task(
          id: '1',
          title: 'Only Task',
          createdAt: DateTime.now(),
          description: '',
          priority: 1,
        );
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value([task]));
        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success) // Добавлен явный стейт success
            .having((s) => s.tasks.length, 'count', 1)
            .having((s) => s.tasks.first.id, 'id', '1')
            .having((s) => s.tasks.first.title, 'title', 'Only Task'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should request stream with new sort type and deliver database-ordered pinned tasks',
      build: () {
        final now = DateTime.now();
        // Имитируем, что БД пришлет нам список, где пины УЖЕ гарантированно идут первыми
        final sortedByDbTasks = [
          Task(id: '2', title: 'B', priority: 1, isPinned: true, createdAt: now, description: ''),
          Task(id: '3', title: 'C', priority: 2, isPinned: true, createdAt: now, description: ''),
          Task(id: '1', title: 'A', priority: 3, isPinned: false, createdAt: now, description: ''),
        ];

        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});

        // Настраиваем UseCase на перезапуск стрима при изменении сортировки
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byPriority, // Ждем запрос с новой сортировкой
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value(sortedByDbTasks));

        return taskBloc;
      },
      seed: () => const TaskState(
        status: TaskStatus.success,
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byPriority)),
      expect: () => [
        // 1. Первый стейт: Блок уходит в loading и обновляет флаг сортировки
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.sortType, 'sortType', TaskSortType.byPriority),

        // 2. Второй стейт: Из перезапущенного стрима прилетают готовые таски от БД
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks.first.isPinned, 'first pinned', true)
            .having((s) => s.tasks[1].isPinned, 'second pinned', true)
            .having((s) => s.tasks.last.isPinned, 'last unpinned', false),
      ],
      verify: (_) {
        // Верифицируем, что Блок честно сходил в базу с нужным sortType
        verify(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byPriority,
            sortDirection: any(named: 'sortDirection'),
          ),
        ).called(1);
      },
    );
  });

  group('TaskBloc 13 - Complete Sorting Coverage', () {
    final now = DateTime.now();

    final taskA = Task(id: '1', title: 'Apple', createdAt: now, description: '');
    final taskM = Task(id: '3', title: 'Mango', createdAt: now, description: '');
    final taskZ = Task(id: '2', title: 'Zebra', createdAt: now, description: '');

    blocTest<TaskBloc, TaskState>(
      'should request stream by title and deliver ordered tasks from database',
      build: () {
        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
        // Имитируем, что база данных вернула список, отсортированный по алфавиту (Z -> A согласно дефолтному направлению topToBottom)
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byTitle,
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value([taskZ, taskM, taskA]));
        return taskBloc;
      },
      seed: () => TaskState(
        status: TaskStatus.success,
        tasks: [taskZ, taskA, taskM],
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byTitle)),
      expect: () => [
        // 1. Уход в лоадинг и обновление флага сортировки
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.sortType, 'type', TaskSortType.byTitle),
        // 2. Получение данных из нового стрима
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks.first.title, 'first (Z)', 'Zebra')
            .having((s) => s.tasks.last.title, 'last (A)', 'Apple'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should request stream by date created and deliver ordered tasks from database',
      build: () {
        final oldTask = Task(
          id: '2',
          title: 'Old Task',
          createdAt: now.subtract(const Duration(days: 7)),
          description: '',
        );
        final newTask = Task(id: '1', title: 'New Task', createdAt: now, description: '');

        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
        // Имитируем, что база вернула новые задачи первыми
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byDateCreated,
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value([newTask, oldTask]));
        return taskBloc;
      },
      seed: () => const TaskState(
        status: TaskStatus.success,
        tasks: [],
        sortType: TaskSortType.byPriority,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byDateCreated)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.sortType, 'type', TaskSortType.byDateCreated),
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks.first.id, 'newest first', '1'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should invert sort direction when changing to same type',
      build: () {
        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byTitle,
            sortDirection: TaskSortDirection.bottomToTop, // Ожидаем инвертированное
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        status: TaskStatus.success,
        sortType: TaskSortType.byTitle,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byTitle)),
      expect: () => [
        // Стейт объединяет смену статуса и инверсию направления
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.sortDirection, 'direction flipped', TaskSortDirection.bottomToTop),
      ],
      verify: (_) {
        verify(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: TaskSortType.byTitle,
            sortDirection: TaskSortDirection.bottomToTop,
          ),
        ).called(1);
      },
    );
  });

  group('TaskBloc 14 - Rapid Sequential Events', () {
    blocTest<TaskBloc, TaskState>(
      'should handle rapid sequential UI events, updating configuration and restarting stream each time',
      build: () {
        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});

        // Настраиваем цепочку ожидаемых вызовов для перезапуска стрима.
        // Важен точный порядок параметров, который формируется на каждом шаге:

        // 1. Сначала меняется только сортировка на byTitle
        when(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: TaskSortType.byTitle,
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());

        // 2. Затем добавляется фильтр .completed (сортировка уже осталась byTitle)
        when(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.completed,
            sortType: TaskSortType.byTitle,
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());

        // 3. Затем сортировка меняется на byPriority
        when(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.completed,
            sortType: TaskSortType.byPriority,
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());

        // 4. В конце добавляется поисковый запрос 'query'
        when(
          () => mockWatchTasksUseCase(
            searchQuery: 'query',
            filterType: TaskFilterType.completed,
            sortType: TaskSortType.byPriority,
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());

        return taskBloc;
      },
      seed: () => TaskState(
        tasks: [Task(id: '1', title: 'Task', createdAt: DateTime.now(), description: '')],
        status: TaskStatus.success,
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
        filterType: TaskFilterType.all,
        searchQuery: '',
      ),
      act: (bloc) {
        bloc
          ..add(const SortChanged(TaskSortType.byTitle))
          ..add(const FilterChanged(TaskFilterType.completed))
          ..add(const SortChanged(TaskSortType.byPriority))
          ..add(const SearchChanged('query'));
      },
      expect: () => [
        // Шаг 1: Сортировка поменялась, статус ушел в loading
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.sortType, 'type1', TaskSortType.byTitle),

        // Шаг 2: Фильтр поменялся, статус держит loading
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.filterType, 'filter', TaskFilterType.completed),

        // Шаг 3: Сортировка снова поменялась на приоритет
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.sortType, 'type2', TaskSortType.byPriority),

        // Шаг 4: Добавился поиск, финальный стейт загрузки перед ответом БД
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.searchQuery, 'query', 'query'),
      ],
      verify: (_) {
        // Верифицируем, что Блок дернул базу данных ровно 4 раза,
        // последовательно применяя каждый промежуточный конфиг
        verify(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).called(4);
      },
    );
  });

  group('TaskBloc 15 - Missing Task Scenarios', () {
    blocTest<TaskBloc, TaskState>(
      'should emit failure when toggling pin for non-existent task',
      build: () => taskBloc,
      seed: () => const TaskState(tasks: []),
      // Пустой список задач
      act: (bloc) => bloc.add(const TaskPinToggled('non-existent-id')),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.failure)
            .having((s) => s.errorType, 'errorType', TaskErrorType.update),
      ],
      verify: (_) {
        // Убеждаемся, что до UseCase апдейта выполнение так и не дошло
        verifyNever(() => mockUpdateTasksUseCase(any()));
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should gracefully skip update and emit nothing when task not found',
      build: () => taskBloc,
      seed: () => const TaskState(tasks: []),
      act: (bloc) => bloc.add(
        TaskUpdated(
          'not-found',
          DateTime.now(),
          const TaskDraft(
            title: 'Update',
            descriptionJson: '',
            priority: 1,
            attachments: [],
            subtasks: [],
            isCompleted: false,
          ),
        ),
      ),
      expect: () => [],
      // Состояние не меняется, так как задача отсутствует в стейте
      verify: (_) {
        verifyNever(() => mockUpdateTasksUseCase(any()));
      },
    );
  });

  group('TaskBloc 16 - highlightedTaskVersion Tracking', () {
    blocTest<TaskBloc, TaskState>(
      'should increment highlightedTaskVersion and emit loading status on notification open',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        status: TaskStatus.success,
        highlightedTaskId: null,
        highlightedTaskVersion: 0,
      ),
      act: (bloc) => bloc.add(const NotificationTaskOpened('task-1')),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.highlightedTaskVersion, 'version', 1)
            .having((s) => s.highlightedTaskId, 'taskId', 'task-1')
            .having((s) => s.searchQuery, 'search cleared', '')
            .having((s) => s.filterType, 'filter reset', TaskFilterType.all),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should continue incrementing version on multiple notifications and trigger stream reload',
      build: () {
        when(
          () => mockWatchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        status: TaskStatus.success,
        highlightedTaskId: 'task-1',
        highlightedTaskVersion: 2,
      ),
      act: (bloc) => bloc.add(const NotificationTaskOpened('task-2')),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.highlightedTaskVersion, 'incremented', 3)
            .having((s) => s.highlightedTaskId, 'new taskId', 'task-2'),
      ],
    );
  });

  group('TaskBloc 17 - Preference Persistence', () {
    blocTest<TaskBloc, TaskState>(
      'should persist sort preference with correct type and direction',
      build: () {
        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        status: TaskStatus.success,
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byTitle)),
      verify: (_) {
        final captured = verify(() => mockSetPrefsUseCase(captureAny())).captured;

        expect(captured.length, 1);
        final prefs = captured.first as TaskViewPreferences;
        expect(prefs.sortType, TaskSortType.byTitle);
        expect(prefs.sortDirection, TaskSortDirection.topToBottom);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should persist filter preference even when other settings change',
      build: () {
        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
        when(
          () => mockWatchTasksUseCase(
            searchQuery: any(named: 'searchQuery'),
            filterType: any(named: 'filterType'),
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        status: TaskStatus.success,
        sortType: TaskSortType.byTitle,
        filterType: TaskFilterType.all,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byPriority)),
      verify: (_) {
        final captured = verify(() => mockSetPrefsUseCase(captureAny())).captured;

        final prefs = captured.last as TaskViewPreferences;
        expect(
          prefs.filterType,
          TaskFilterType.all,
        ); // Проверяем, что фильтр не затерся при смене сортировки
      },
    );
  });
}
