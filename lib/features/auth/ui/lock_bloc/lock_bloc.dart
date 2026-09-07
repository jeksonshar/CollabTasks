import 'package:collab_tasks/core/utils/auth_biometric_constants.dart';
import 'package:collab_tasks/features/auth/data/services/biometric_secure_storage.dart';
import 'package:collab_tasks/features/auth/domain/usecases/authenticate_with_biometric_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/check_biometric_availability_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/clear_biometric_data_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/get_biometric_enabled_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/set_biometric_enabled_use_case.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_event.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages biometric lock/unlock lifecycle:
/// - Cold start lock check
/// - Warm start (resume) lock check with inactivity timeout
/// - Privacy screen overlay when backgrounded
/// - Biometric toggle from Settings
/// - Post-login biometric enrollment offer
class LockBloc extends Bloc<LockEvent, LockState> {
  LockBloc({
    required CheckBiometricAvailabilityUseCase checkBiometricAvailabilityUseCase,
    required AuthenticateWithBiometricUseCase authenticateWithBiometricUseCase,
    required GetBiometricEnabledUseCase getBiometricEnabledUseCase,
    required SetBiometricEnabledUseCase setBiometricEnabledUseCase,
    required ClearBiometricDataUseCase clearBiometricDataUseCase,
    required String biometricAuthReason,
  }) : _checkAvailability = checkBiometricAvailabilityUseCase,
       _authenticate = authenticateWithBiometricUseCase,
       _getEnabled = getBiometricEnabledUseCase,
       _setEnabled = setBiometricEnabledUseCase,
       _clearData = clearBiometricDataUseCase,
       _authReason = biometricAuthReason,
       super(const LockState()) {
    on<LockCheckRequested>(_onCheckRequested);
    on<LockAppPaused>(_onAppPaused);
    on<LockAppResumed>(_onAppResumed);
    on<LockAuthenticateRequested>(_onAuthenticateRequested);
    on<LockSignInWithPasswordRequested>(_onSignInWithPasswordRequested);
    on<LockBiometricToggled>(_onBiometricToggled);
    on<LockBiometricOfferResponded>(_onBiometricOfferResponded);
    on<_LockResetRequested>((_, emit) => emit(const LockState()));
  }

  final CheckBiometricAvailabilityUseCase _checkAvailability;
  final AuthenticateWithBiometricUseCase _authenticate;
  final GetBiometricEnabledUseCase _getEnabled;
  final SetBiometricEnabledUseCase _setEnabled;
  final ClearBiometricDataUseCase _clearData;
  final String _authReason;

  /// Timestamp when the app was put in background.
  DateTime? _backgroundedAt;

  /// Tracks whether the biometric dialog is currently presented.
  /// Prevents lifecycle pause/resume loops from re-triggering biometric checks.
  bool _isAuthenticating = false;

  /// Timestamp of the last successful or completed authentication.
  DateTime? _lastAuthenticatedAt;

  // ────────────────────────────────────────────────
  // Event handlers
  // ────────────────────────────────────────────────

  /// Cold start: check capability, enrolled flag, and lock if enabled.
  Future<void> _onCheckRequested(LockCheckRequested event, Emitter<LockState> emit) async {
    final isAvailable = await _checkAvailability();

    bool isEnabled = false;
    try {
      isEnabled = (await _getEnabled()) ?? false;
    } on BiometricKeysInvalidatedException {
      debugPrint('LockBloc: biometric keys invalidated, disabling biometrics');
      await _clearData();
      emit(
        state.copyWith(
          isBiometricAvailable: isAvailable,
          isBiometricEnabled: false,
          status: LockStatus.idle,
        ),
      );
      return;
    }

    emit(state.copyWith(isBiometricAvailable: isAvailable, isBiometricEnabled: isEnabled));

    final shouldLock = isEnabled && isAvailable;
    if (!shouldLock) {
      emit(state.copyWith(status: LockStatus.idle));
      return;
    }

    emit(
      state.copyWith(
        status: LockStatus.locked,
        authenticationFailed: false,
        isBiometricEnabled: isEnabled,
        isBiometricAvailable: isAvailable,
      ),
    );
    add(const LockAuthenticateRequested());
  }

  /// App went to background.
  void _onAppPaused(LockAppPaused event, Emitter<LockState> emit) {
    // If biometric prompt is currently active, the pause is caused by the OS
    // system dialog taking window focus — ignore it so we don't disrupt auth.
    if (_isAuthenticating) {
      debugPrint('LockBloc._onAppPaused: ignoring pause during active biometric auth');
      return;
    }

    _backgroundedAt = DateTime.now();
    debugPrint('LockBloc._onAppPaused: app backgrounded at $_backgroundedAt');
    emit(state.copyWith(status: LockStatus.privacyScreen));
  }

  /// App returned to foreground.
  Future<void> _onAppResumed(LockAppResumed event, Emitter<LockState> emit) async {
    // 1. If currently in the middle of authenticating, ignore resume event
    if (_isAuthenticating) {
      debugPrint('LockBloc._onAppResumed: ignoring resume during active biometric auth');
      return;
    }

    // 2. If authentication just completed within 3 seconds, this resume is the dialog closing
    if (_lastAuthenticatedAt != null &&
        DateTime.now().difference(_lastAuthenticatedAt!) < const Duration(seconds: 3)) {
      debugPrint('LockBloc._onAppResumed: ignoring resume right after biometric completion');
      if (state.status == LockStatus.privacyScreen) {
        emit(state.copyWith(status: LockStatus.idle));
      }
      return;
    }

    // 3. If already locked, keep locked (clear privacy screen if needed)
    if (state.status == LockStatus.locked || state.status == LockStatus.authenticating) {
      debugPrint('LockBloc._onAppResumed: app already locked, maintaining lock');
      return;
    }

    // 4. If app wasn't properly backgrounded, restore idle
    if (_backgroundedAt == null) {
      debugPrint('LockBloc._onAppResumed: no background timestamp, staying idle');
      if (state.status == LockStatus.privacyScreen) {
        emit(state.copyWith(status: LockStatus.idle));
      }
      return;
    }

    // 5. Check inactivity timeout
    final elapsed = DateTime.now().difference(_backgroundedAt!);
    _backgroundedAt = null;
    debugPrint('LockBloc._onAppResumed: elapsed inactivity=$elapsed');

    final shouldLock =
        state.isBiometricEnabled && state.isBiometricAvailable && elapsed >= kInactivityTimeout;

    if (shouldLock) {
      debugPrint('LockBloc._onAppResumed: inactivity exceeded 5m, locking app');
      emit(state.copyWith(status: LockStatus.locked, authenticationFailed: false));
      add(const LockAuthenticateRequested());
    } else {
      emit(state.copyWith(status: LockStatus.idle));
    }
  }

  Future<void> _onAuthenticateRequested(
    LockAuthenticateRequested event,
    Emitter<LockState> emit,
  ) async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    emit(state.copyWith(status: LockStatus.authenticating, authenticationFailed: false));

    debugPrint('LockBloc._onAuthenticateRequested: triggering biometric prompt...');
    final success = await _authenticate(localizedReason: _authReason);
    _isAuthenticating = false;
    _lastAuthenticatedAt = DateTime.now();
    debugPrint('LockBloc._onAuthenticateRequested: result=$success');

    if (success) {
      emit(state.copyWith(status: LockStatus.idle, authenticationFailed: false));
    } else {
      // Keep locked, show retry + password buttons
      emit(state.copyWith(status: LockStatus.locked, authenticationFailed: true));
    }
  }

  void _onSignInWithPasswordRequested(
    LockSignInWithPasswordRequested event,
    Emitter<LockState> emit,
  ) {
    emit(state.copyWith(status: LockStatus.requiresLogout));
  }

  Future<void> _onBiometricToggled(LockBiometricToggled event, Emitter<LockState> emit) async {
    if (!event.enabled) {
      try {
        await _setEnabled(value: false);
        debugPrint('LockBloc._onBiometricToggled: disabled biometrics');
        emit(state.copyWith(isBiometricEnabled: false));
      } catch (e, st) {
        debugPrint('LockBloc._onBiometricToggled disable error: $e\n$st');
      }
      return;
    }

    if (_isAuthenticating) return;
    _isAuthenticating = true;
    debugPrint('LockBloc._onBiometricToggled: prompting biometric confirmation...');
    final success = await _authenticate(localizedReason: _authReason);
    _isAuthenticating = false;
    _lastAuthenticatedAt = DateTime.now();
    debugPrint('LockBloc._onBiometricToggled: biometric confirmation success=$success');

    if (success) {
      try {
        await _setEnabled(value: true);
        debugPrint('LockBloc._onBiometricToggled: saved isBiometricEnabled=true');
        emit(state.copyWith(isBiometricEnabled: true, status: LockStatus.idle));
      } on BiometricKeysInvalidatedException {
        emit(state.copyWith(isBiometricEnabled: false, status: LockStatus.idle));
      }
    } else {
      debugPrint('LockBloc._onBiometricToggled: authentication failed or cancelled');
      emit(state.copyWith(isBiometricEnabled: false, status: LockStatus.idle));
    }
  }

  Future<void> _onBiometricOfferResponded(
    LockBiometricOfferResponded event,
    Emitter<LockState> emit,
  ) async {
    if (!event.accepted) {
      emit(state.copyWith(status: LockStatus.idle));
      return;
    }

    if (_isAuthenticating) return;
    _isAuthenticating = true;
    final success = await _authenticate(localizedReason: _authReason);
    _isAuthenticating = false;
    _lastAuthenticatedAt = DateTime.now();

    if (success) {
      try {
        await _setEnabled(value: true);
        emit(state.copyWith(isBiometricEnabled: true, status: LockStatus.idle));
      } on BiometricKeysInvalidatedException {
        emit(state.copyWith(isBiometricEnabled: false, status: LockStatus.idle));
      }
    } else {
      emit(state.copyWith(status: LockStatus.idle));
    }
  }

  /// Called externally (e.g. from AppAuthGate after handling requiresLogout)
  /// to clear biometric data and reset lock state.
  Future<void> clearAndReset() async {
    await _clearData();
    _backgroundedAt = null;
    _isAuthenticating = false;
    _lastAuthenticatedAt = null;
    add(const _LockResetRequested());
  }
}

/// Internal event for resetting LockBloc state after logout.
class _LockResetRequested extends LockEvent {
  const _LockResetRequested();
}
