import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/core/enums/task_error_type.dart';
import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/core/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/core/notifications/task_notification_event_type.dart';
import 'package:collab_tasks/domain/models/errors/data_exception.dart';
import 'package:collab_tasks/domain/models/task.dart';
import 'package:collab_tasks/domain/models/task_draft.dart';
import 'package:collab_tasks/domain/models/task_view_preferences.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_state.dart';
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
  late MockNotificationsManager mockNotificationsManager;
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
    mockNotificationsManager = MockNotificationsManager();
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
    when(
      () => mockNotificationsManager.notificationTapStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockNotificationsManager.consumeInitialTapPayload(),
    ).thenReturn(null); // Emulating the absence of a cold start from a notification
    // 2. Futures for synchronization and planning
    when(
      () => mockNotificationsManager.syncTaskDeadlineNotifications(
        any(),
        reminderTitle: any(named: 'reminderTitle'),
        deadlineTitle: any(named: 'deadlineTitle'),
      ),
    ).thenAnswer((_) async => {});
    when(
      () => mockNotificationsManager.scheduleTaskDeadlineNotifications(
        any(),
        reminderTitle: any(named: 'reminderTitle'),
        deadlineTitle: any(named: 'deadlineTitle'),
      ),
    ).thenAnswer((_) async => {});
    // 3. Rest
    when(
      () => mockNotificationsManager.cancelTaskDeadlineNotifications(any()),
    ).thenAnswer((_) async => {});
    // Overriding behavior for notification tests
    when(
      () => mockNotificationsManager.notificationTapStream,
    ).thenAnswer((_) => notificationController.stream);
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
      notificationsManager: mockNotificationsManager,
      notificationReminderTitle: '',
      notificationDeadlineTitle: '',
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
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => Stream.value([tTask]));
        when(() => mockUpdateTasksUseCase(any())).thenAnswer((_) async => {});
        return taskBloc;
      },
      // First we load the tasks so that they are in state, then we update
      act: (bloc) async {
        bloc.add(LoadTasksStarted());
        await Future.delayed(Duration.zero); // Let the stream load
        bloc.add(TaskUpdated(tTask.id, tTask.createdAt, tDraft));
      },
      skip: 2,
      // Skipping loading states (loading and initial success)
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
      act: (bloc) async {
        bloc.add(LoadTasksStarted());
        await Future.delayed(Duration.zero);
        bloc.add(TaskDeleted(tTask.id));
      },
      skip: 2,
      expect: () => [
        isA<TaskState>()
            .having((s) => s.lastAction, 'lastAction', TaskAction.delete)
            .having((s) => s.lastActionTaskTitle, 'title', 'Task to Delete'),
      ],
      verify: (_) {
        verify(() => mockDeleteTasksUseCase(tTask.id)).called(1);
        verify(() => mockNotificationsManager.cancelTaskDeadlineNotifications(tTask.id)).called(1);
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
          () => mockNotificationsManager.scheduleTaskDeadlineNotifications(
            any(),
            reminderTitle: any(named: 'reminderTitle'),
            deadlineTitle: any(named: 'deadlineTitle'),
          ),
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
        verify(
          () => mockNotificationsManager.scheduleTaskDeadlineNotifications(
            any(),
            reminderTitle: any(named: 'reminderTitle'),
            deadlineTitle: any(named: 'deadlineTitle'),
          ),
        ).called(1);
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
      'should swallow error in _saveTaskViewPreferences and cover debugPrint',
      build: () {
        // Configure UseCase to throw an exception
        when(() => mockSetPrefsUseCase(any())).thenThrow(Exception('Prefs Save Failed'));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const FilterChanged(TaskFilterType.completed)),
      expect: () => [
        // The state should still be updated, since the error in the catch is swallowed.
        isA<TaskState>().having((s) => s.filterType, 'filterType', TaskFilterType.completed),
      ],
      verify: (_) {
        // We check that the call attempt was made
        verify(() => mockSetPrefsUseCase(any())).called(1);
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

  group('TaskBloc 7 - Sorting Logic', () {
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

  group('TaskBloc 8 - Notifications Error', () {
    blocTest<TaskBloc, TaskState>(
      'should swallow the notification error without breaking the main flow',
      build: () {
        when(() => mockWatchTasksUseCase()).thenAnswer((_) => const Stream.empty());
        when(() => mockAddTaskUseCase(any())).thenAnswer((_) async => {});
        // Simulating an error in the notification manager
        when(
          () => mockNotificationsManager.syncTaskDeadlineNotifications(
            any(),
            reminderTitle: any(named: 'reminderTitle'),
            deadlineTitle: any(named: 'deadlineTitle'),
          ),
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

  group('TaskBloc 9 - Sync Notifications Error', () {
    blocTest<TaskBloc, TaskState>(
      'должен зайти в блок catch внутри _syncNotifications при ошибке стрима данных',
      build: () {
        // 1. Bringing back the single-task stream
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

        // 2. We are dropping the SYNC method
        when(
          () => mockNotificationsManager.syncTaskDeadlineNotifications(
            any(),
            reminderTitle: any(named: 'reminderTitle'),
            deadlineTitle: any(named: 'deadlineTitle'),
          ),
        ).thenAnswer((_) async => throw Exception('Sync Global Failed'));

        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasksStarted()),
      expect: () => [
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.success),
      ],
      verify: (_) {
        verify(
          () => mockNotificationsManager.syncTaskDeadlineNotifications(
            any(),
            reminderTitle: any(named: 'reminderTitle'),
            deadlineTitle: any(named: 'deadlineTitle'),
          ),
        ).called(1);
      },
    );
  });

  group('TaskBloc 10 - Coverage Push', () {
    blocTest<TaskBloc, TaskState>(
      'should handle notification tap and initial payload',
      build: () {
        // Emulating a cold start
        when(() => mockNotificationsManager.consumeInitialTapPayload()).thenReturn(
          const NotificationTapPayload(
            taskId: '123',
            eventType: TaskNotificationEventType.beforeDeadline,
          ),
        );

        // We recreate the block so that initNotificationListeners fires with the new mock.
        return TaskBloc(
          watchTasksUseCase: mockWatchTasksUseCase,
          notificationsManager: mockNotificationsManager,
          notificationReminderTitle: '',
          notificationDeadlineTitle: '',
          addTaskUseCase: mockAddTaskUseCase,
          updateTaskUseCase: mockUpdateTasksUseCase,
          deleteTaskUseCase: mockDeleteTasksUseCase,
          getTaskViewPreferencesUseCase: mockGetPrefsUseCase,
          setTaskViewPreferencesUseCase: mockSetPrefsUseCase,
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
}
