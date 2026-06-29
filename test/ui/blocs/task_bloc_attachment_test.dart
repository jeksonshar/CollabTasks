import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/settings/domain/models/task_view_preferences.dart';
import 'package:collab_tasks/features/tasks/data/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_draft.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';
import '../../mocks/mock_use_cases.dart';

void main() {
  late MockWatchTasksUseCase watchTasksUseCase;
  late MockAddTaskUseCase addTaskUseCase;
  late MockUpdateTaskUseCase updateTaskUseCase;
  late MockDeleteTaskUseCase deleteTaskUseCase;
  late MockGetTaskViewPreferencesUseCase getPrefsUseCase;
  late MockSetTaskViewPreferencesUseCase setPrefsUseCase;
  late MockScheduleTaskNotificationsUseCase scheduleNotificationsUseCase;
  late MockCancelTaskNotificationsUseCase cancelNotificationsUseCase;
  late MockGetNotificationTapStreamUseCase getNotificationStreamUseCase;
  late MockConsumeInitialNotificationPayloadUseCase consumePayloadUseCase;
  late MockSyncTasksUseCase syncTasksUseCase;
  late StreamController<NotificationTapPayload> notificationController;

  setUpAll(() {
    registerTestFallbackValues();

    // РЕГИСТРИРУЕМ СЛИТЫЕ ENUM-ТИПЫ ДЛЯ МАТЧЕРА any()
    registerFallbackValue(TaskFilterType.all);
    registerFallbackValue(TaskSortType.byDateCreated);
    registerFallbackValue(TaskSortDirection.topToBottom);
  });

  void initMocks() {
    watchTasksUseCase = MockWatchTasksUseCase();
    addTaskUseCase = MockAddTaskUseCase();
    updateTaskUseCase = MockUpdateTaskUseCase();
    deleteTaskUseCase = MockDeleteTaskUseCase();
    getPrefsUseCase = MockGetTaskViewPreferencesUseCase();
    setPrefsUseCase = MockSetTaskViewPreferencesUseCase();
    scheduleNotificationsUseCase = MockScheduleTaskNotificationsUseCase();
    cancelNotificationsUseCase = MockCancelTaskNotificationsUseCase();
    getNotificationStreamUseCase = MockGetNotificationTapStreamUseCase();
    consumePayloadUseCase = MockConsumeInitialNotificationPayloadUseCase();
    syncTasksUseCase = MockSyncTasksUseCase();
    notificationController = StreamController<NotificationTapPayload>.broadcast();
  }

  void stubDefaultBehavior() {
    when(() => getPrefsUseCase()).thenAnswer(
      (_) async => const TaskViewPreferences(
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
        filterType: TaskFilterType.all,
      ),
    );
    when(() => setPrefsUseCase(any())).thenAnswer((_) async {});
    when(() => scheduleNotificationsUseCase(any())).thenAnswer((_) async {});
    when(() => cancelNotificationsUseCase(any())).thenAnswer((_) async {});
    when(() => syncTasksUseCase()).thenAnswer((_) async {});
    when(() => getNotificationStreamUseCase()).thenAnswer((_) => notificationController.stream);
    when(() => consumePayloadUseCase()).thenReturn(null);

    // ДОБАВЛЕНО: Дефолтный стаб для стрима, чтобы тесты добавления/апдейта не падали при инициализации подписки Блока
    when(
      () => watchTasksUseCase(
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
  });

  tearDown(() async {
    await notificationController.close();
  });

  TaskBloc buildBloc() {
    return TaskBloc(
      watchTasksUseCase: watchTasksUseCase,
      addTaskUseCase: addTaskUseCase,
      updateTaskUseCase: updateTaskUseCase,
      deleteTaskUseCase: deleteTaskUseCase,
      getTaskViewPreferencesUseCase: getPrefsUseCase,
      setTaskViewPreferencesUseCase: setPrefsUseCase,
      scheduleTaskNotificationsUseCase: scheduleNotificationsUseCase,
      cancelTaskNotificationsUseCase: cancelNotificationsUseCase,
      getNotificationTapStreamUseCase: getNotificationStreamUseCase,
      consumeInitialNotificationPayloadUseCase: consumePayloadUseCase,
      syncTasksUseCase: syncTasksUseCase,
    );
  }

  group('TaskBloc attachments', () {
    blocTest<TaskBloc, TaskState>(
      'passes draft attachments to AddTaskUseCase when adding a task',
      build: () {
        when(() => addTaskUseCase(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const TaskAdded(
          TaskDraft(
            title: 'Task with file',
            descriptionJson: '[{"insert":"Body\\n"}]',
            priority: 1,
            attachments: [
              TaskAttachment(
                id: 'file-1',
                name: 'notes.txt',
                extension: 'txt',
                localPath: '/tmp/notes.txt',
                sizeBytes: 512,
              ),
            ],
            subtasks: [],
            isCompleted: false,
          ),
        ),
      ),
      verify: (_) {
        final capturedTask = verify(() => addTaskUseCase(captureAny())).captured.single as Task;

        expect(capturedTask.title, 'Task with file');
        expect(capturedTask.attachments, hasLength(1));
        expect(capturedTask.attachments.single.id, 'file-1');
        expect(capturedTask.attachments.single.localPath, '/tmp/notes.txt');
        expect(capturedTask.attachments.single.sizeBytes, 512);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'replaces attachments through UpdateTaskUseCase while preserving pin state',
      build: () {
        when(() => updateTaskUseCase(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => TaskState(
        status: TaskStatus.success,
        tasks: [
          Task(
            id: 'task-1',
            createdAt: DateTime.utc(2026),
            title: 'Existing',
            description: 'Old body',
            isPinned: true,
            attachments: const [
              TaskAttachment(
                id: 'old-file',
                name: 'old.txt',
                extension: 'txt',
                localPath: '/tmp/old.txt',
                sizeBytes: 10,
              ),
            ],
          ),
        ],
      ),
      act: (bloc) => bloc.add(
        TaskUpdated(
          'task-1',
          DateTime.utc(2026),
          const TaskDraft(
            title: 'Updated',
            descriptionJson: '[{"insert":"Updated body\\n"}]',
            priority: 2,
            attachments: [
              TaskAttachment(
                id: 'new-file',
                name: 'new.pdf',
                extension: 'pdf',
                storageKey: 'remote/new.pdf',
                sizeBytes: 2048,
              ),
            ],
            subtasks: [],
            isCompleted: true,
          ),
        ),
      ),
      verify: (_) {
        final capturedTask = verify(() => updateTaskUseCase(captureAny())).captured.single as Task;

        expect(capturedTask.id, 'task-1');
        expect(capturedTask.isPinned, isTrue);
        expect(capturedTask.attachments, hasLength(1));
        expect(capturedTask.attachments.single.id, 'new-file');
        expect(capturedTask.attachments.single.storageKey, 'remote/new.pdf');
      },
    );

    blocTest<TaskBloc, TaskState>(
      'filters tasks without files when FilterChanged(TaskFilterType.withoutFiles) is added',
      build: () {
        final withFile = Task(
          id: 'with-file',
          createdAt: DateTime.utc(2026),
          title: 'With file',
          description: '',
          attachments: const [
            TaskAttachment(id: 'file-1', name: '1.txt', extension: 'txt', sizeBytes: 1),
          ],
        );
        final withoutFile = Task(
          id: 'without-file',
          createdAt: DateTime.utc(2026),
          title: 'Without file',
          description: '',
        );

        // ИСПРАВЛЕНО: Настройка для LoadTasksStarted (запрос всех тасок)
        when(
          () => watchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.all,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value([withFile, withoutFile]));

        // ИСПРАВЛЕНО: Настройка для FilterChanged (запрос тасок без файлов)
        when(
          () => watchTasksUseCase(
            searchQuery: '',
            filterType: TaskFilterType.withoutFiles,
            sortType: any(named: 'sortType'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) => Stream.value([withoutFile]));

        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTasksStarted());
        await pumpEventQueue();
        bloc.add(const FilterChanged(TaskFilterType.withoutFiles));
      },
      expect: () => [
        // Шаг 1-2: Результат от LoadTasksStarted
        isA<TaskState>().having((s) => s.status, 'status', TaskStatus.loading),
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks, 'tasks', hasLength(2)),

        // ИСПРАВЛЕНО: Шаг 3-4: Результат от FilterChanged (перезапуск подписки)
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.loading)
            .having((s) => s.filterType, 'filterType', TaskFilterType.withoutFiles),
        isA<TaskState>()
            .having((s) => s.status, 'status', TaskStatus.success)
            .having((s) => s.tasks, 'tasks', hasLength(1))
            .having((s) => s.tasks.first.id, 'task id', 'without-file'),
      ],
    );
  });
}
