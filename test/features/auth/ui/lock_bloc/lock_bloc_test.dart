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

  setUp(() {
    mockCheckAvailability = MockCheckBiometricAvailabilityUseCase();
    mockAuthenticate = MockAuthenticateWithBiometricUseCase();
    mockGetEnabled = MockGetBiometricEnabledUseCase();
    mockSetEnabled = MockSetBiometricEnabledUseCase();
    mockClearData = MockClearBiometricDataUseCase();
  });

  LockBloc buildBloc() {
    return LockBloc(
      checkBiometricAvailabilityUseCase: mockCheckAvailability,
      authenticateWithBiometricUseCase: mockAuthenticate,
      getBiometricEnabledUseCase: mockGetEnabled,
      setBiometricEnabledUseCase: mockSetEnabled,
      clearBiometricDataUseCase: mockClearData,
      biometricAuthReason: 'Test reason',
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
  });
}
