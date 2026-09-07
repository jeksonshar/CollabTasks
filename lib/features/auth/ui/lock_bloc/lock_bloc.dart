import 'dart:async';

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
/// - Foreground inactivity timer ([kInactivityTimeout] of no touch/interaction)
/// - Background / screen-lock inactivity timer ([kInactivityTimeout] elapsed since last activity)
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
    on<LockUserInteractionOccurred>(_onUserInteractionOccurred);
    on<LockAuthStatusChanged>(_onAuthStatusChanged);
    on<LockAuthenticateRequested>(_onAuthenticateRequested);
    on<LockSignInWithPasswordRequested>(_onSignInWithPasswordRequested);
    on<LockBiometricToggled>(_onBiometricToggled);
    on<LockBiometricOfferResponded>(_onBiometricOfferResponded);
    on<_LockTimeoutExpired>(_onTimeoutExpired);
    on<_LockResetRequested>((_, emit) => emit(const LockState()));
  }

  final CheckBiometricAvailabilityUseCase _checkAvailability;
  final AuthenticateWithBiometricUseCase _authenticate;
  final GetBiometricEnabledUseCase _getEnabled;
  final SetBiometricEnabledUseCase _setEnabled;
  final ClearBiometricDataUseCase _clearData;
  final String _authReason;

  /// Timer that fires when the user has not touched the screen for [kInactivityTimeout].
  Timer? _inactivityTimer;

  /// Timestamp of the last user interaction or resume.
  DateTime? _lastActivityTime;

  /// Throttling helper for user pointer interactions.
  DateTime? _lastInteractionProcessedAt;

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

    debugPrint(
      'LockBloc._onCheckRequested: available=$isAvailable, enabled=$isEnabled, timeout=${kInactivityTimeout.inSeconds}s',
    );

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

  /// App went to background or screen was locked.
  void _onAppPaused(LockAppPaused event, Emitter<LockState> emit) {
    if (_isAuthenticating) {
      debugPrint('LockBloc._onAppPaused: ignoring pause during active biometric auth');
      return;
    }

    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _lastActivityTime = DateTime.now();
    debugPrint('LockBloc._onAppPaused: app paused/hidden/inactive at $_lastActivityTime');
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

    // 4. Calculate inactivity elapsed since last activity
    final now = DateTime.now();
    final elapsed = _lastActivityTime != null ? now.difference(_lastActivityTime!) : Duration.zero;
    debugPrint(
      'LockBloc._onAppResumed: elapsed inactivity=${elapsed.inSeconds}s / required=${kInactivityTimeout.inSeconds}s '
      '(enabled=${state.isBiometricEnabled}, available=${state.isBiometricAvailable})',
    );

    final shouldLock =
        state.isBiometricEnabled && state.isBiometricAvailable && elapsed >= kInactivityTimeout;

    if (shouldLock) {
      debugPrint(
        'LockBloc._onAppResumed: inactivity exceeded (${elapsed.inSeconds}s >= ${kInactivityTimeout.inSeconds}s), locking app',
      );
      emit(state.copyWith(status: LockStatus.locked, authenticationFailed: false));
      add(const LockAuthenticateRequested());
    } else {
      emit(state.copyWith(status: LockStatus.idle));
      _lastActivityTime = now;
      _resetInactivityTimer();
    }
  }

  /// Dispatched when the user taps or interacts with the screen.
  void _onUserInteractionOccurred(LockUserInteractionOccurred event, Emitter<LockState> emit) {
    final now = DateTime.now();
    // Throttle interaction events to at most once every 2 seconds
    if (_lastInteractionProcessedAt != null &&
        now.difference(_lastInteractionProcessedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastInteractionProcessedAt = now;
    _lastActivityTime = now;
    _resetInactivityTimer();
  }

  /// Synchronizes authentication status from AuthBloc.
  void _onAuthStatusChanged(LockAuthStatusChanged event, Emitter<LockState> emit) {
    debugPrint('LockBloc._onAuthStatusChanged: isAuthenticated=${event.isAuthenticated}');
    if (event.isAuthenticated) {
      _lastActivityTime = DateTime.now();
      _resetInactivityTimer();
    } else {
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
    }
  }

  /// Foreground inactivity timer fired.
  void _onTimeoutExpired(_LockTimeoutExpired event, Emitter<LockState> emit) {
    debugPrint(
      'LockBloc._onTimeoutExpired: checking lock conditions '
      '(enabled=${state.isBiometricEnabled}, available=${state.isBiometricAvailable}, status=${state.status})',
    );
    if (!state.isBiometricEnabled || !state.isBiometricAvailable) {
      return;
    }
    if (state.status == LockStatus.idle) {
      debugPrint(
        'LockBloc._onTimeoutExpired: LOCKING app due to ${kInactivityTimeout.inSeconds}s foreground inactivity!',
      );
      emit(state.copyWith(status: LockStatus.locked, authenticationFailed: false));
      add(const LockAuthenticateRequested());
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
      _lastActivityTime = DateTime.now();
      emit(state.copyWith(status: LockStatus.idle, authenticationFailed: false));
      _resetInactivityTimer();
    } else {
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
        _inactivityTimer?.cancel();
        _inactivityTimer = null;
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
        _lastActivityTime = DateTime.now();
        emit(state.copyWith(isBiometricEnabled: true, status: LockStatus.idle));
        _resetInactivityTimer();
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
        _lastActivityTime = DateTime.now();
        emit(state.copyWith(isBiometricEnabled: true, status: LockStatus.idle));
        _resetInactivityTimer();
      } on BiometricKeysInvalidatedException {
        emit(state.copyWith(isBiometricEnabled: false, status: LockStatus.idle));
      }
    } else {
      emit(state.copyWith(status: LockStatus.idle));
    }
  }

  /// Starts or resets the inactivity countdown using [kInactivityTimeout].
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    final shouldTrack =
        state.isBiometricEnabled && state.isBiometricAvailable && state.status == LockStatus.idle;

    debugPrint(
      'LockBloc._resetInactivityTimer: shouldTrack=$shouldTrack '
      '(enabled=${state.isBiometricEnabled}, available=${state.isBiometricAvailable}, status=${state.status}, timeout=${kInactivityTimeout.inSeconds}s)',
    );

    if (!shouldTrack) return;

    _inactivityTimer = Timer(kInactivityTimeout, () {
      debugPrint(
        'LockBloc: Timer expired after ${kInactivityTimeout.inSeconds}s! Emitting _LockTimeoutExpired',
      );
      add(const _LockTimeoutExpired());
    });
  }

  /// Called externally (e.g. from AppAuthGate after handling requiresLogout)
  /// to clear biometric data and reset lock state.
  Future<void> clearAndReset() async {
    await _clearData();
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _lastActivityTime = null;
    _isAuthenticating = false;
    _lastAuthenticatedAt = null;
    add(const _LockResetRequested());
  }

  @override
  Future<void> close() {
    _inactivityTimer?.cancel();
    return super.close();
  }
}

/// Internal event fired when the foreground inactivity timer expires.
class _LockTimeoutExpired extends LockEvent {
  const _LockTimeoutExpired();
}

/// Internal event for resetting LockBloc state after logout.
class _LockResetRequested extends LockEvent {
  const _LockResetRequested();
}
