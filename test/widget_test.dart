import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_event.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_state.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_bloc.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_event.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_state.dart' as lock;
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_bloc.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_event.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_state.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_state.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_groups_use_case.dart';
import 'package:collab_tasks/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLocaleCubit extends MockCubit<Locale?> implements LocaleCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockTaskBloc extends MockBloc<TaskEvent, TaskState> implements TaskBloc {}

class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState> implements ThemeBloc {}

class MockLockBloc extends MockBloc<LockEvent, lock.LockState> implements LockBloc {}

class MockCallsBloc extends MockBloc<CallsEvent, CallsState> implements CallsBloc {}

class MockWatchAuthStateUseCase extends Mock implements WatchAuthStateUseCase {}

class MockGetWorkingGroupsUseCase extends Mock implements GetWorkingGroupsUseCase {}

void main() {
  late MockLocaleCubit localeCubit;
  late MockAuthBloc authBloc;
  late MockTaskBloc taskBloc;
  late MockThemeBloc themeBloc;
  late MockLockBloc lockBloc;
  late MockCallsBloc callsBloc;
  late MockWatchAuthStateUseCase watchAuthStateUseCase;
  late MockGetWorkingGroupsUseCase getWorkingGroupsUseCase;

  setUpAll(() {
    registerFallbackValue(const AuthSubscriptionStarted());
    registerFallbackValue(LoadTasksStarted());
  });

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    localeCubit = MockLocaleCubit();
    authBloc = MockAuthBloc();
    taskBloc = MockTaskBloc();
    themeBloc = MockThemeBloc();
    lockBloc = MockLockBloc();
    callsBloc = MockCallsBloc();
    watchAuthStateUseCase = MockWatchAuthStateUseCase();
    getWorkingGroupsUseCase = MockGetWorkingGroupsUseCase();

    const authState = AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser(id: 'user-1', email: 'user@example.com', isEmailVerified: true),
    );
    const taskState = TaskState(status: TaskStatus.success);
    const themeState = ThemeState(themePreference: ThemePreference(mode: AppThemeMode.system));
    const lockState = lock.LockState(status: lock.LockStatus.idle);
    const callsState = CallsState();

    whenListen(localeCubit, const Stream<Locale?>.empty(), initialState: null);
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: authState);
    whenListen(taskBloc, const Stream<TaskState>.empty(), initialState: taskState);
    whenListen(themeBloc, const Stream<ThemeState>.empty(), initialState: themeState);
    whenListen(lockBloc, const Stream<lock.LockState>.empty(), initialState: lockState);
    whenListen(callsBloc, const Stream<CallsState>.empty(), initialState: callsState);
    when(() => watchAuthStateUseCase()).thenAnswer((_) => const Stream<AuthUser?>.empty());
    when(
      () => getWorkingGroupsUseCase(),
    ).thenAnswer((_) => const Stream<List<WorkingGroup>>.empty());

    getIt
      ..registerSingleton<SharedPreferences>(sharedPreferences)
      ..registerFactory<WatchAuthStateUseCase>(() => watchAuthStateUseCase)
      ..registerFactory<GetWorkingGroupsUseCase>(() => getWorkingGroupsUseCase)
      ..registerFactory<LocaleCubit>(() => localeCubit)
      ..registerFactory<AuthBloc>(() => authBloc)
      ..registerFactory<TaskBloc>(() => taskBloc)
      ..registerFactory<ThemeBloc>(() => themeBloc)
      ..registerFactory<LockBloc>(() => lockBloc)
      ..registerFactory<CallsBloc>(() => callsBloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('MyApp renders main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.group), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
