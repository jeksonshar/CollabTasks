import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_state.dart';
import 'package:collab_tasks/features/tasks/ui/screens/home_screen/home_tasks_screen.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskBloc extends MockBloc<TaskEvent, TaskState> implements TaskBloc {}

class FakeTaskEvent extends Fake implements TaskEvent {}

void main() {
  late MockTaskBloc taskBloc;

  setUpAll(() {
    registerFallbackValue(FakeTaskEvent());
  });

  setUp(() {
    taskBloc = MockTaskBloc();

    when(() => taskBloc.add(any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments.first;
      if (event is TasksRefreshRequested) {
        event.completer?.complete();
      }
    });
  });

  Widget buildTestableWidget(TaskState state) {
    whenListen(taskBloc, const Stream<TaskState>.empty(), initialState: state);

    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      home: BlocProvider<TaskBloc>.value(value: taskBloc, child: const HomeTasksScreen()),
    );
  }

  testWidgets('Pull to refresh triggers TasksRefreshRequested with non-empty list', (tester) async {
    final tasks = [
      Task(id: '1', title: 'Test Task 1', createdAt: DateTime.now(), description: 'Description 1'),
    ];

    await tester.pumpWidget(
      buildTestableWidget(TaskState(status: TaskStatus.success, tasks: tasks)),
    );

    expect(find.text('Test Task 1'), findsOneWidget);

    final refreshIndicator = tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator));
    final refresh = refreshIndicator.show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await refresh;

    verify(() => taskBloc.add(any(that: isA<TasksRefreshRequested>()))).called(1);
  });

  testWidgets('Pull to refresh triggers TasksRefreshRequested when list is empty', (tester) async {
    await tester.pumpWidget(buildTestableWidget(const TaskState(status: TaskStatus.success)));

    expect(find.byIcon(Icons.inbox), findsOneWidget);

    final refreshIndicator = tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator));
    final refresh = refreshIndicator.show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await refresh;

    verify(() => taskBloc.add(any(that: isA<TasksRefreshRequested>()))).called(1);
  });
}
