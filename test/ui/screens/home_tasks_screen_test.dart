import 'dart:async';

import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/settings/domain/models/task_view_preferences.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/features/tasks/ui/screens/home_screen/home_tasks_screen.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  setUpAll(() {
    registerTestFallbackValues();
  });

  setUp(() {
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

    // Default settings for preferences
    when(() => mockGetPrefsUseCase()).thenAnswer(
      (_) async => const TaskViewPreferences(
        sortType: TaskSortType.byDateCreated,
        sortDirection: TaskSortDirection.topToBottom,
        filterType: TaskFilterType.all,
      ),
    );
    when(() => mockSetPrefsUseCase(any())).thenAnswer((_) async => {});
    when(() => mockGetNotificationStreamUseCase()).thenAnswer((_) => const Stream.empty());
    when(() => mockConsumePayloadUseCase()).thenReturn(null);

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
    );
  });

  tearDown(() {
    taskBloc.close();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      home: BlocProvider<TaskBloc>.value(value: taskBloc, child: child),
    );
  }

  testWidgets('Pull to refresh triggers TasksRefreshRequested with non-empty list', (tester) async {
    final tasks = [
      Task(id: '1', title: 'Test Task 1', createdAt: DateTime.now(), description: 'Description 1'),
    ];

    when(() => mockWatchTasksUseCase()).thenAnswer((_) => Stream.value(tasks));
    when(() => mockSyncTasksUseCase()).thenAnswer((_) async => {});

    await tester.pumpWidget(buildTestableWidget(const HomeTasksScreen()));

    // Add LoadTasksStarted to initialize state
    taskBloc.add(LoadTasksStarted());
    await tester.pumpAndSettle();

    // Verify task is displayed
    expect(find.text('Test Task 1'), findsOneWidget);

    // Trigger pull to refresh programmatically
    final refreshIndicator = tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator));
    await refreshIndicator.show();
    await tester.pumpAndSettle();

    // Verify syncTasksUseCase was called
    verify(() => mockSyncTasksUseCase()).called(1);
  });

  testWidgets('Pull to refresh triggers TasksRefreshRequested when list is empty', (tester) async {
    when(() => mockWatchTasksUseCase()).thenAnswer((_) => Stream.value(<Task>[]));
    when(() => mockSyncTasksUseCase()).thenAnswer((_) async => {});

    await tester.pumpWidget(buildTestableWidget(const HomeTasksScreen()));

    // Add LoadTasksStarted to initialize state
    taskBloc.add(LoadTasksStarted());
    await tester.pumpAndSettle();

    // Verify empty state is displayed
    expect(find.byIcon(Icons.inbox), findsOneWidget);

    // Trigger pull to refresh programmatically
    final refreshIndicator = tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator));
    await refreshIndicator.show();
    await tester.pumpAndSettle();

    // Verify syncTasksUseCase was called
    verify(() => mockSyncTasksUseCase()).called(1);
  });
}
