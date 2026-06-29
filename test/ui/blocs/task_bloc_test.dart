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
  late MockCancelTaskNotificationsUseCase mockCancelNotificationsUseCase;
  late MockGetNotificationTapStreamUseCase mockGetNotificationStreamUseCase;
  late MockConsumeInitialNotificationPayloadUseCase mockConsumePayloadUseCase;
  late MockSyncTasksUseCase mockSyncTasksUseCase;
  late MockFilterAndSortTasksUseCase mockFilterAndSortTasksUseCase;
  late StreamController<NotificationTapPayload> notificationController;

  setUpAll(() {
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
    mockCancelNotificationsUseCase = MockCancelTaskNotificationsUseCase();
    mockGetNotificationStreamUseCase = MockGetNotificationTapStreamUseCase();
    mockConsumePayloadUseCase = MockConsumeInitialNotificationPayloadUseCase();
    mockSyncTasksUseCase = MockSyncTasksUseCase();
    mockFilterAndSortTasksUseCase = MockFilterAndSortTasksUseCase();
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

    // 1. Streams and cold starts
    when(() => mockGetNotificationStreamUseCase()).thenAnswer((_) => const Stream.empty());
    when(
      () => mockConsumePayloadUseCase(),
    ).thenReturn(null); // Emulating the absence of a cold start from a notification
    // 2. Futures for notification planning
    when(() => mockScheduleNotificationsUseCase(any())).thenAnswer((_) async => {});
    // 3. Rest
    when(() => mockCancelNotificationsUseCase(any())).thenAnswer((_) async => {});
    when(() => mockSyncTasksUseCase()).thenAnswer((_) async => {});
    // Filter and sort (identity: just return input as is)
    when(
      () => mockFilterAndSortTasksUseCase(
        tasks: any(named: 'tasks'),
        filterType: any(named: 'filterType'),
        sortType: any(named: 'sortType'),
        sortDirection: any(named: 'sortDirection'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((invocation) {
      // Extract tasks from named arguments
      final tasks = invocation.namedArguments.values.first as List<Task>? ?? <Task>[];
      return tasks;
    });
    // Overriding behavior for notification tests
    when(() => mockGetNotificationStreamUseCase()).thenAnswer((_) => notificationController.stream);
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
      cancelTaskNotificationsUseCase: mockCancelNotificationsUseCase,
      getNotificationTapStreamUseCase: mockGetNotificationStreamUseCase,
      consumeInitialNotificationPayloadUseCase: mockConsumePayloadUseCase,
      syncTasksUseCase: mockSyncTasksUseCase,
      filterAndSortTasksUseCase: mockFilterAndSortTasksUseCase, // ??
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
        // Simulating the flow of data from the database
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => Stream.value(tTasks));
        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        // 1. First, the status changes to loading
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        // 2. Then tasks from the stream arrive
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks, 'tasks', tTasks)
            .having((s) => s.sortType, 'sortType', TaskSortType.byDateCreated),
      ],
      verify: (_) {
        verify(() => mockWatchTasksUseCase()).called(1);
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
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
        verify(
          () => mockAddTaskUseCase(
            any(
              that: isA<Task>()
                  .having((t) => t.id, 'id', isNotEmpty)
                  .having((t) => t.title, 'title', tDraft.title)
                  .having((t) => t.priority, 'priority', tDraft.priority)
                  .having((t) => t.createdAt, 'createdAt', isA<DateTime>()),
            ),
          ),
        ).called(1);
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => Stream.value([tTask]));
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => Stream.value([tTask]));
        when(() => mockDeleteTasksUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      seed: () => TaskState(tasks: [tTask], status: TaskStatus.success),
      act: (bloc) => bloc.add(TaskDeleted(tTask.id)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.lastAction, 'lastAction', TaskAction.delete)
            .having((s) => s.lastActionTaskTitle, 'title', 'Task to Delete'),
      ],
      verify: (_) {
        verify(() => mockDeleteTasksUseCase(tTask.id)).called(1);
        verify(() => mockCancelNotificationsUseCase(tTask.id)).called(1);
      },
    );
  });

  group('TaskBloc 5 - UI Events', () {
    blocTest<TaskBloc, TaskState>(
      'should invert the sort direction if the same type is selected',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        sortType: TaskSortType.byTitle,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byTitle)),
      expect: () => [
        isA<TaskState>().having((s) => s.sortDirection, 'direction', TaskSortDirection.bottomToTop),
      ],
    );
    blocTest<TaskBloc, TaskState>(
      'should update filterType and save preferences when FilterChanged is added',
      build: () {
        // We'll stabilize the saving of settings so that the test doesn't crash.
        when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      seed: () => const TaskState(filterType: TaskFilterType.all),
      act: (bloc) => bloc.add(const FilterChanged(TaskFilterType.completed)),
      expect: () => [
        isA<TaskState>().having((s) => s.filterType, 'filterType', TaskFilterType.completed),
      ],
      verify: (_) {
        // Check that the save UseCase was called with the correct filter
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        // Simulating a Hard UseCase Error
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
      expect: () => [isA<TaskState>().having((s) => s.status, 'status', TaskStatus.failure)],
    );
    blocTest<TaskBloc, TaskState>(
      'should swallow notification error in _onAddTask and cover debugPrint',
      build: () {
        // 1. Setup: Adding task successfully
        when(() => mockAddTaskUseCase(any())).thenAnswer((_) async => {});

        // 2. Setting: Notification scheduling crashes with an error
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
        // The status should NOT be failure, as the notification error is caught internally
        isA<TaskState>()
            .having((s) => s.lastAction, 'lastAction', TaskAction.add)
            .having((s) => s.lastActionTaskTitle, 'title', 'Notification Error Task'),
      ],
      verify: (_) {
        // We check that the method was actually called and crashed.
        verify(() => mockScheduleNotificationsUseCase(any())).called(1);
      },
    );
    blocTest<TaskBloc, TaskState>(
      'should maintain a failure status or issue an error state if UpdateTask fails',
      build: () {
        // Simulating a Hard UseCase Error
        when(() => mockUpdateTasksUseCase(any())).thenThrow(DataException('Database Error'));
        return taskBloc;
      },
      // PREPARATION: Give the block a state with an existing task
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
      expect: () => [isA<TaskState>().having((s) => s.status, 'status', TaskStatus.failure)],
    );
    blocTest<TaskBloc, TaskState>(
      'should emit failure when the stream itself emits an error (forEach onError)',
      build: () {
        // Important: not thenThrow, but return the stream that contains the error
        when(
          () => mockWatchTasksUseCase(),
        ).thenAnswer((_) => Stream.error(Exception('Stream emitted error')));
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
    blocTest<TaskBloc, TaskState>(
      'should emit failure when deleteTaskUseCase fails',
      build: () {
        // Simulating a hard error when deleting
        when(() => mockDeleteTasksUseCase(any())).thenThrow(DataException('Database Delete Error'));
        return taskBloc;
      },
      // MANDATORY: Add the task to the state to pass the taskToDelete == null check.
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
      'Should remain functional and emit success state even if preference saving fails',
      build: () {
        when(() => mockSetPrefsUseCase(any())).thenThrow(Exception('Prefs Save Failed'));
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(status: TaskStatus.success),
      act: (bloc) => bloc.add(const FilterChanged(TaskFilterType.completed)),
      expect: () => [
        // The state should still be updated, since the error in the catch is swallowed.
        isA<TaskState>()
            .having((s) => s.filterType, 'filterType', TaskFilterType.completed)
            .having((s) => s.status, 'status', TaskStatus.success),
      ],
      verify: (_) {
        verify(
          () => mockSetPrefsUseCase(
            any(
              that: isA<TaskViewPreferences>()
                  .having((f) => f.filterType, 'filterType', TaskFilterType.completed)
                  .having((f) => f.sortType, 'sortType', TaskSortType.byDateCreated),
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
      // PREPARATION: Without a task in the state, the method will fail when searching for firstWhere
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
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
        when(() => mockWatchTasksUseCase()).thenAnswer(
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
        verifyNever(() => mockCancelNotificationsUseCase(any()));
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
      'should actually sort the list by priority',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      // We throw two tasks into the state in the "wrong" order
      seed: () => TaskState(
        status: TaskStatus.success,
        tasks: [taskLow, taskHigh],
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byPriority)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.sortType, 'type', TaskSortType.byPriority)
            // We check that the tasks in the list have changed places according to priority
            .having((s) => s.tasks.first.priority, 'first task priority', 3),
      ],
    );
  });

  group('TaskBloc 10 - Notifications & Deep Links', () {
    blocTest<TaskBloc, TaskState>(
      'should handle notification tap and initial payload',
      build: () {
        // Emulating a cold start
        when(() => mockConsumePayloadUseCase()).thenReturn(
          const NotificationTapPayload(
            taskId: '123',
            eventType: TaskNotificationEventType.beforeDeadline,
          ),
        );

        // We recreate the block so that initNotificationListeners fires with the new mock.
        return TaskBloc(
          watchTasksUseCase: mockWatchTasksUseCase,
          scheduleTaskNotificationsUseCase: mockScheduleNotificationsUseCase,
          cancelTaskNotificationsUseCase: mockCancelNotificationsUseCase,
          getNotificationTapStreamUseCase: mockGetNotificationStreamUseCase,
          consumeInitialNotificationPayloadUseCase: mockConsumePayloadUseCase,
          addTaskUseCase: mockAddTaskUseCase,
          updateTaskUseCase: mockUpdateTasksUseCase,
          deleteTaskUseCase: mockDeleteTasksUseCase,
          getTaskViewPreferencesUseCase: mockGetPrefsUseCase,
          setTaskViewPreferencesUseCase: mockSetPrefsUseCase,
          syncTasksUseCase: mockSyncTasksUseCase,
          filterAndSortTasksUseCase: mockFilterAndSortTasksUseCase,
        );
      },
      act: (bloc) => notificationController.add(
        const NotificationTapPayload(
          taskId: '456',
          eventType: TaskNotificationEventType.beforeDeadline,
        ),
      ),
      expect: () => [
        // First, the initialPayload from the constructor will be executed.
        isA<TaskState>().having((s) => s.highlightedTaskId, 'initial', '123'),
        // Then an event from the stream will arrive
        isA<TaskState>().having((s) => s.highlightedTaskId, 'stream', '456'),
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
        when(() => mockWatchTasksUseCase()).thenThrow(Exception('DB Crash'));
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
      'should toggle pin and call updateUseCase',
      build: () {
        when(() => mockUpdateTasksUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      seed: () => TaskState(tasks: [tTask]),
      act: (bloc) => bloc.add(const TaskPinToggled('1')),
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
      'should update searchQuery when SearchChanged is added',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      act: (bloc) => bloc.add(const SearchChanged('flutter examples')),
      expect: () => [isA<TaskState>().having((s) => s.searchQuery, 'query', 'flutter examples')],
    );

    blocTest<TaskBloc, TaskState>(
      'should clear error when ErrorCleared is added',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(status: TaskStatus.failure, errorType: TaskErrorType.load),
      act: (bloc) => bloc.add(ErrorCleared()),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.errorType, 'error', null)
            .having((s) => s.status, 'status', TaskStatus.failure),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should reset multiple fields when NotificationTaskOpened',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
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
            .having((s) => s.filterType, 'filter reset to all', TaskFilterType.all)
            .having((s) => s.searchQuery, 'search cleared', '')
            .having((s) => s.highlightedTaskId, 'taskId set', 'task-xyz')
            .having((s) => s.highlightedTaskVersion, 'version incremented', 1),
      ],
    );
  });

  group('TaskBloc 12 - Edge Cases - Empty & Single Task', () {
    blocTest<TaskBloc, TaskState>(
      'should handle empty task list gracefully',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => Stream.value([]));
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => Stream.value([task]));
        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        isA<TaskState>()
            .having((s) => s.tasks.length, 'count', 1)
            .having((s) => s.tasks.first.id, 'id', '1')
            .having((s) => s.tasks.first.title, 'title', 'Only Task'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should keep all pinned tasks before unpinned tasks regardless of sort type',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () {
        final now = DateTime.now();
        return TaskState(
          status: TaskStatus.success,
          tasks: [
            Task(
              id: '1',
              title: 'A',
              priority: 3,
              isPinned: false,
              createdAt: now,
              description: '',
            ),
            Task(id: '2', title: 'B', priority: 1, isPinned: true, createdAt: now, description: ''),
            Task(id: '3', title: 'C', priority: 2, isPinned: true, createdAt: now, description: ''),
          ],
          sortType: TaskSortType.byPriority,
          sortDirection: TaskSortDirection.topToBottom,
        );
      },
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byPriority)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.tasks.first.isPinned, 'first pinned', true)
            .having((s) => s.tasks[1].isPinned, 'second pinned', true)
            .having((s) => s.tasks.last.isPinned, 'last unpinned', false),
      ],
    );
  });

  group('TaskBloc 13 - Complete Sorting Coverage', () {
    blocTest<TaskBloc, TaskState>(
      'should sort tasks by title (descending first)',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () {
        final now = DateTime.now();
        return TaskState(
          status: TaskStatus.success,
          tasks: [
            Task(id: '2', title: 'Zebra', createdAt: now, description: ''),
            Task(id: '1', title: 'Apple', createdAt: now, description: ''),
            Task(id: '3', title: 'Mango', createdAt: now, description: ''),
          ],
          sortType: TaskSortType.byDateCreated,
          sortDirection: TaskSortDirection.topToBottom,
        );
      },
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byTitle)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.sortType, 'type', TaskSortType.byTitle)
            .having((s) => s.tasks.first.title, 'first (Z)', 'Zebra')
            .having((s) => s.tasks.last.title, 'last (A)', 'Apple'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should sort tasks by date created (newest first by default)',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () {
        final now = DateTime.now();
        return TaskState(
          status: TaskStatus.success,
          tasks: [
            Task(
              id: '2',
              title: 'Old Task',
              createdAt: now.subtract(const Duration(days: 7)),
              description: '',
            ),
            Task(id: '1', title: 'New Task', createdAt: now, description: ''),
          ],
          sortType: TaskSortType.byPriority,
          sortDirection: TaskSortDirection.topToBottom,
        );
      },
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byDateCreated)),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.sortType, 'type', TaskSortType.byDateCreated)
            .having((s) => s.tasks.first.id, 'newest first', '1'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should invert sort direction when changing to same type multiple times',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
        sortType: TaskSortType.byTitle,
        sortDirection: TaskSortDirection.topToBottom,
      ),
      act: (bloc) {
        bloc.add(const SortChanged(TaskSortType.byTitle)); // Flip 1
        // After first flip: bottomToTop
        // Internally trigger another sort (would be done via add after state change)
      },
      expect: () => [
        isA<TaskState>().having(
          (s) => s.sortDirection,
          'direction flipped',
          TaskSortDirection.bottomToTop,
        ),
      ],
    );
  });

  group('TaskBloc 14 - Rapid Sequential Events', () {
    blocTest<TaskBloc, TaskState>(
      'should handle rapid sequential events correctly',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        when(() => mockAddTaskUseCase(any())).thenAnswer((_) async => {});
        when(() => mockUpdateTasksUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      seed: () => TaskState(
        tasks: [Task(id: '1', title: 'Task', createdAt: DateTime.now(), description: '')],
        status: TaskStatus.success,
      ),
      act: (bloc) {
        // Multiple rapid events
        bloc
          ..add(const SortChanged(TaskSortType.byTitle))
          ..add(const FilterChanged(TaskFilterType.completed))
          ..add(const SortChanged(TaskSortType.byPriority))
          ..add(const SearchChanged('query'));
      },
      expect: () => [
        // Sort changed
        isA<TaskState>().having((s) => s.sortType, 'type1', TaskSortType.byTitle),
        // Filter changed
        isA<TaskState>().having((s) => s.filterType, 'filter', TaskFilterType.completed),
        // Sort changed again
        isA<TaskState>().having((s) => s.sortType, 'type2', TaskSortType.byPriority),
        // Search changed
        isA<TaskState>().having((s) => s.searchQuery, 'query', 'query'),
      ],
    );
  });

  group('TaskBloc 15 - Missing Task Scenarios', () {
    blocTest<TaskBloc, TaskState>(
      'should emit failure when toggling pin for non-existent task',
      build: () {
        when(() => mockUpdateTasksUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      seed: () => const TaskState(tasks: []), // Empty
      act: (bloc) => bloc.add(const TaskPinToggled('non-existent-id')),
      expect: () => [
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.failure)
            .having((s) => s.errorType, 'error', TaskErrorType.update),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should gracefully skip update when task not found',
      build: () {
        when(() => mockUpdateTasksUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
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
      expect: () => [], // No state change because task not found
    );
  });

  group('TaskBloc 16 - highlightedTaskVersion Tracking', () {
    blocTest<TaskBloc, TaskState>(
      'should increment highlightedTaskVersion on each notification open',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(highlightedTaskId: null, highlightedTaskVersion: 0),
      act: (bloc) {
        bloc.add(const NotificationTaskOpened('task-1'));
        // After version becomes 1
      },
      expect: () => [
        isA<TaskState>()
            .having((s) => s.highlightedTaskVersion, 'version', 1)
            .having((s) => s.highlightedTaskId, 'taskId', 'task-1'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should continue incrementing version on multiple notifications',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(highlightedTaskId: 'task-1', highlightedTaskVersion: 2),
      act: (bloc) => bloc.add(const NotificationTaskOpened('task-2')),
      expect: () => [
        isA<TaskState>()
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        return taskBloc;
      },
      seed: () => const TaskState(sortType: TaskSortType.byTitle, filterType: TaskFilterType.all),
      act: (bloc) => bloc.add(const SortChanged(TaskSortType.byPriority)),
      verify: (_) {
        final captured = verify(() => mockSetPrefsUseCase(captureAny())).captured;

        final prefs = captured.last as TaskViewPreferences;
        expect(prefs.filterType, TaskFilterType.all); // Should preserve
      },
    );
  });
}
