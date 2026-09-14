import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_event.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_state.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_bloc.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_event.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_state.dart' as lock;
import 'package:collab_tasks/features/auth/ui/lock_screen/lock_screen_widget.dart';
import 'package:collab_tasks/features/auth/ui/lock_screen/privacy_screen_widget.dart';
import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_bloc.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_event.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_state.dart';
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

class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState> implements ThemeBloc {}

class MockLockBloc extends MockBloc<LockEvent, lock.LockState> implements LockBloc {}

void main() {
  late MockLocaleCubit localeCubit;
  late MockAuthBloc authBloc;
  late MockTaskBloc taskBloc;
  late MockThemeBloc themeBloc;
  late MockLockBloc lockBloc;

  setUpAll(() {
    registerFallbackValue(const AuthSubscriptionStarted());
    registerFallbackValue(LoadTasksStarted());
  });

  setUp(() async {
    await getIt.reset();

    localeCubit = MockLocaleCubit();
    authBloc = MockAuthBloc();
    taskBloc = MockTaskBloc();
    themeBloc = MockThemeBloc();
    lockBloc = MockLockBloc();

    const authState = AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser(id: 'user-1', email: 'user@example.com', isEmailVerified: true),
    );
    const taskState = TaskState(status: TaskStatus.success);
    const themeState = ThemeState(themePreference: ThemePreference(mode: AppThemeMode.system));

    whenListen(localeCubit, const Stream<Locale?>.empty(), initialState: null);
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: authState);
    whenListen(taskBloc, const Stream<TaskState>.empty(), initialState: taskState);
    whenListen(themeBloc, const Stream<ThemeState>.empty(), initialState: themeState);

    getIt
      ..registerFactory<LocaleCubit>(() => localeCubit)
      ..registerFactory<AuthBloc>(() => authBloc)
      ..registerFactory<TaskBloc>(() => taskBloc)
      ..registerFactory<ThemeBloc>(() => themeBloc)
      ..registerFactory<LockBloc>(() => lockBloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('LockScreenWidget is not shown when lockStatus is idle', (tester) async {
    whenListen(
      lockBloc,
      const Stream<lock.LockState>.empty(),
      initialState: const lock.LockState(status: lock.LockStatus.idle),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LockScreenWidget), findsNothing);
    expect(find.byType(PrivacyScreenWidget), findsNothing);
  });

  testWidgets('LockScreenWidget overlays pushed subroutes when lockStatus is locked', (
    tester,
  ) async {
    whenListen(
      lockBloc,
      Stream.fromIterable([
        const lock.LockState(status: lock.LockStatus.idle),
        const lock.LockState(status: lock.LockStatus.locked),
      ]),
      initialState: const lock.LockState(status: lock.LockStatus.idle),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Push a subroute on top of the root route
    globalNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('Subroute Screen Content'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subroute Screen Content'), findsOneWidget);

    // Now emit locked state
    whenListen(
      lockBloc,
      const Stream<lock.LockState>.empty(),
      initialState: const lock.LockState(status: lock.LockStatus.locked),
    );
    await tester.pump();

    // LockScreenWidget must now be present on top
    expect(find.byType(LockScreenWidget), findsOneWidget);
  });

  testWidgets('PrivacyScreenWidget overlays screen when lockStatus is privacyScreen', (
    tester,
  ) async {
    whenListen(
      lockBloc,
      const Stream<lock.LockState>.empty(),
      initialState: const lock.LockState(status: lock.LockStatus.privacyScreen),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PrivacyScreenWidget), findsOneWidget);
    expect(find.byType(LockScreenWidget), findsNothing);
  });
}
