import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/features/auth/domain/usecases/authenticate_with_biometric_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/check_biometric_availability_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/clear_biometric_data_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/get_biometric_enabled_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/set_biometric_enabled_use_case.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_bloc.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_event.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckBiometricAvailabilityUseCase extends Mock
    implements CheckBiometricAvailabilityUseCase {}

class MockAuthenticateWithBiometricUseCase extends Mock
    implements AuthenticateWithBiometricUseCase {}

class MockGetBiometricEnabledUseCase extends Mock implements GetBiometricEnabledUseCase {}

class MockSetBiometricEnabledUseCase extends Mock implements SetBiometricEnabledUseCase {}

class MockClearBiometricDataUseCase extends Mock implements ClearBiometricDataUseCase {}

void main() {
  late MockCheckBiometricAvailabilityUseCase mockCheckAvailability;
  late MockAuthenticateWithBiometricUseCase mockAuthenticate;
  late MockGetBiometricEnabledUseCase mockGetEnabled;
  late MockSetBiometricEnabledUseCase mockSetEnabled;
  late MockClearBiometricDataUseCase mockClearData;

  late DateTime currentTime;

  setUp(() {
    currentTime = DateTime(2026, 1, 1, 12, 0, 0);
    mockCheckAvailability = MockCheckBiometricAvailabilityUseCase();
    mockAuthenticate = MockAuthenticateWithBiometricUseCase();
    mockGetEnabled = MockGetBiometricEnabledUseCase();
    mockSetEnabled = MockSetBiometricEnabledUseCase();
    mockClearData = MockClearBiometricDataUseCase();
  });

  LockBloc buildBloc({DateTime Function()? nowProvider}) {
    return LockBloc(
      checkBiometricAvailabilityUseCase: mockCheckAvailability,
      authenticateWithBiometricUseCase: mockAuthenticate,
      getBiometricEnabledUseCase: mockGetEnabled,
      setBiometricEnabledUseCase: mockSetEnabled,
      clearBiometricDataUseCase: mockClearData,
      biometricAuthReason: 'Test reason',
      nowProvider: nowProvider ?? () => currentTime,
    );
  }

  group('LockBloc Lifecycle & Security', () {
    blocTest<LockBloc, LockState>(
      'preserves LockStatus.locked when app is paused (never overwrites with privacyScreen)',
      build: buildBloc,
      seed: () => const LockState(
        status: LockStatus.locked,
        isBiometricEnabled: true,
        isBiometricAvailable: true,
      ),
      act: (bloc) => bloc.add(const LockAppPaused()),
      expect: () => <LockState>[], // No state emitted, remains locked!
    );

    blocTest<LockBloc, LockState>(
      'emits privacyScreen when app is paused from LockStatus.idle with biometrics enabled',
      build: buildBloc,
      seed: () => const LockState(
        status: LockStatus.idle,
        isBiometricEnabled: true,
        isBiometricAvailable: true,
      ),
      act: (bloc) => bloc.add(const LockAppPaused()),
      expect: () => [
        const LockState(
          status: LockStatus.privacyScreen,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
        ),
      ],
    );

    blocTest<LockBloc, LockState>(
      'maintains LockStatus.locked and triggers biometric authentication when resumed from locked',
      setUp: () {
        when(
          () => mockAuthenticate(localizedReason: any(named: 'localizedReason')),
        ).thenAnswer((_) async => false);
      },
      build: buildBloc,
      seed: () => const LockState(
        status: LockStatus.locked,
        isBiometricEnabled: true,
        isBiometricAvailable: true,
      ),
      act: (bloc) => bloc.add(const LockAppResumed()),
      expect: () => [
        const LockState(
          status: LockStatus.authenticating,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: false,
        ),
        const LockState(
          status: LockStatus.locked,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: true,
        ),
      ],
      verify: (_) {
        verify(() => mockAuthenticate(localizedReason: any(named: 'localizedReason'))).called(1);
      },
    );

    blocTest<LockBloc, LockState>(
      'unlocks to LockStatus.idle only when biometric authentication succeeds',
      setUp: () {
        when(
          () => mockAuthenticate(localizedReason: any(named: 'localizedReason')),
        ).thenAnswer((_) async => true);
      },
      build: buildBloc,
      seed: () => const LockState(
        status: LockStatus.locked,
        isBiometricEnabled: true,
        isBiometricAvailable: true,
      ),
      act: (bloc) => bloc.add(const LockAuthenticateRequested()),
      expect: () => [
        const LockState(
          status: LockStatus.authenticating,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: false,
        ),
        const LockState(
          status: LockStatus.idle,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: false,
        ),
      ],
      verify: (_) {
        verify(() => mockAuthenticate(localizedReason: any(named: 'localizedReason'))).called(1);
      },
    );

    blocTest<LockBloc, LockState>(
      'preserves LockStatus.privacyScreen and does not re-emit on repeated LockAppPaused events',
      build: buildBloc,
      seed: () => const LockState(
        status: LockStatus.privacyScreen,
        isBiometricEnabled: true,
        isBiometricAvailable: true,
      ),
      act: (bloc) => bloc.add(const LockAppPaused()),
      expect: () => <LockState>[],
    );

    blocTest<LockBloc, LockState>(
      'locks app when resumed after inactivity >= kInactivityTimeout',
      setUp: () {
        when(
          () => mockAuthenticate(localizedReason: any(named: 'localizedReason')),
        ).thenAnswer((_) async => false);
      },
      build: buildBloc,
      seed: () => const LockState(
        status: LockStatus.idle,
        isBiometricEnabled: true,
        isBiometricAvailable: true,
      ),
      act: (bloc) async {
        // 1. App goes to background
        bloc.add(const LockAppPaused());
        await Future<void>.delayed(Duration.zero);

        // 2. 65 seconds elapse in background (working in another app)
        currentTime = currentTime.add(const Duration(seconds: 65));

        // 3. App is reopened by user
        bloc.add(const LockAppResumed());
      },
      expect: () => [
        const LockState(
          status: LockStatus.privacyScreen,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
        ),
        const LockState(
          status: LockStatus.locked,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: false,
        ),
        const LockState(
          status: LockStatus.authenticating,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: false,
        ),
        const LockState(
          status: LockStatus.locked,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: true,
        ),
      ],
      verify: (_) {
        verify(() => mockAuthenticate(localizedReason: any(named: 'localizedReason'))).called(1);
      },
    );

    blocTest<LockBloc, LockState>(
      'does not lock and returns to idle when resumed before inactivity timeout (< kInactivityTimeout)',
      build: buildBloc,
      seed: () => const LockState(
        status: LockStatus.idle,
        isBiometricEnabled: true,
        isBiometricAvailable: true,
      ),
      act: (bloc) async {
        // App goes to background
        bloc.add(const LockAppPaused());
        await Future<void>.delayed(Duration.zero);

        // 20 seconds elapse (< 60s timeout)
        currentTime = currentTime.add(const Duration(seconds: 20));

        // App resumed
        bloc.add(const LockAppResumed());
      },
      expect: () => [
        const LockState(
          status: LockStatus.privacyScreen,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
        ),
        const LockState(
          status: LockStatus.idle,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
        ),
      ],
    );

    blocTest<LockBloc, LockState>(
      'intermediate pause events (hidden -> inactive) during restoration do not reset inactivity timer',
      setUp: () {
        when(
          () => mockAuthenticate(localizedReason: any(named: 'localizedReason')),
        ).thenAnswer((_) async => true);
      },
      build: buildBloc,
      seed: () => const LockState(
        status: LockStatus.idle,
        isBiometricEnabled: true,
        isBiometricAvailable: true,
      ),
      act: (bloc) async {
        // App minimized: inactive -> hidden -> paused
        bloc
          ..add(const LockAppPaused())
          ..add(const LockAppPaused())
          ..add(const LockAppPaused());
        await Future<void>.delayed(Duration.zero);

        // User works in another app for 70 seconds
        currentTime = currentTime.add(const Duration(seconds: 70));

        // App restoration begins: intermediate hidden and inactive events arrive
        // followed by resumed
        bloc
          ..add(const LockAppPaused())
          ..add(const LockAppPaused())
          ..add(const LockAppResumed());
      },
      expect: () => [
        const LockState(
          status: LockStatus.privacyScreen,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
        ),
        const LockState(
          status: LockStatus.locked,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: false,
        ),
        const LockState(
          status: LockStatus.authenticating,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: false,
        ),
        const LockState(
          status: LockStatus.idle,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          authenticationFailed: false,
        ),
      ],
      verify: (_) {
        verify(() => mockAuthenticate(localizedReason: any(named: 'localizedReason'))).called(1);
      },
    );
  });
}
