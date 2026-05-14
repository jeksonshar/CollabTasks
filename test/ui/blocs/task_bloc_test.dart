import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
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

  tearDown(() => taskBloc.close());

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
}
