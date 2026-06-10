import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_event.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_state.dart';
import 'package:collab_tasks/features/settings/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_state.dart';
import 'package:collab_tasks/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocaleCubit extends MockCubit<Locale?> implements LocaleCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockTaskBloc extends MockBloc<TaskEvent, TaskState> implements TaskBloc {}

void main() {
  late MockLocaleCubit localeCubit;
  late MockAuthBloc authBloc;
  late MockTaskBloc taskBloc;

  setUpAll(() {
    registerFallbackValue(const AuthSubscriptionStarted());
    registerFallbackValue(LoadTasksStarted());
  });

  setUp(() async {
    await getIt.reset();

    localeCubit = MockLocaleCubit();
    authBloc = MockAuthBloc();
    taskBloc = MockTaskBloc();

    const authState = AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser(id: 'user-1', email: 'user@example.com', isEmailVerified: true),
    );
    const taskState = TaskState(status: TaskStatus.success);

    whenListen(localeCubit, const Stream<Locale?>.empty(), initialState: null);
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: authState);
    whenListen(taskBloc, const Stream<TaskState>.empty(), initialState: taskState);

    getIt
      ..registerFactory<LocaleCubit>(() => localeCubit)
      ..registerFactory<AuthBloc>(() => authBloc)
      ..registerFactory<TaskBloc>(() => taskBloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('MyApp renders main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
