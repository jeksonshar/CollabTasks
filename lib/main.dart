import 'dart:async';
import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:collab_tasks/core/notifications/chat_notification_service.dart';
import 'package:collab_tasks/core/theme/app_theme.dart';
import 'package:collab_tasks/core/utils/auth_utils.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_event.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_state.dart';
import 'package:collab_tasks/features/auth/ui/auth_screen/auth_screen.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_bloc.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_event.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_state.dart' as lock;
import 'package:collab_tasks/features/auth/ui/lock_screen/biometric_offer_dialog.dart';
import 'package:collab_tasks/features/auth/ui/lock_screen/lock_screen_widget.dart';
import 'package:collab_tasks/features/auth/ui/lock_screen/privacy_screen_widget.dart';
import 'package:collab_tasks/features/calls/data/datasources/call_fcm_background_handler.dart';
import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:collab_tasks/features/calls/ui/dialogs/incoming_call_dialog.dart';
import 'package:collab_tasks/features/calls/ui/screens/audio_call_screen.dart';
import 'package:collab_tasks/features/calls/ui/screens/group_call_screen.dart';
import 'package:collab_tasks/features/calls/ui/screens/video_call_screen.dart';
import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_bloc.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_state.dart';
import 'package:collab_tasks/features/tasks/data/notifications/task_notifications_manager.dart';
import 'package:collab_tasks/features/tasks/ui/screens/main_screen/main_screen.dart';
import 'package:collab_tasks/firebase_options.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

// Создаём глобальный Observer для отслеживания открытых экранов
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureSelectedAuthBackend();
  final sharedPreferences = await SharedPreferences.getInstance();
  setupLocator(sharedPreferences);
  await getIt<TaskNotificationsManager>().initialize();

  // Инициализируем FCM ТОЛЬКО если выбран бэкенд Firebase
  if (authBackend == AuthBackend.firebase) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundCallHandler);
    await FlutterCallkitIncoming.onBackgroundMessage(callKitBackgroundEventHandler);
    FlutterCallkitIncoming.acceptCallHandle(callKitAcceptedFromKilledHandler);
    await getIt<ChatNotificationService>().initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>(create: (_) => getIt<LocaleCubit>()),
        BlocProvider<ThemeBloc>(create: (_) => getIt<ThemeBloc>()),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const AuthSubscriptionStarted()),
        ),
        BlocProvider<LockBloc>(create: (_) => getIt<LockBloc>()),
        BlocProvider<CallsBloc>(create: (_) => getIt<CallsBloc>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final themeModeValue = _mapThemeModeToFlutterThemeMode(
                themeState.themePreference.mode,
              );
              return MaterialApp(
                navigatorKey: globalNavigatorKey,
                title: 'CollabTasks',
                locale: locale,
                themeMode: themeModeValue,
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  FlutterQuillLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                navigatorObservers: [routeObserver],
                home: const AppAuthGate(),
                builder: (context, child) {
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      context.read<LockBloc>().add(const LockUserInteractionOccurred());
                    },
                    child: BlocBuilder<LockBloc, lock.LockState>(
                      builder: (context, lockState) {
                        return Stack(
                          children: [
                            child ?? const SizedBox.shrink(),
                            if (lockState.status == lock.LockStatus.privacyScreen)
                              const Positioned.fill(child: PrivacyScreenWidget())
                            else if (lockState.status == lock.LockStatus.locked ||
                                lockState.status == lock.LockStatus.authenticating)
                              const Positioned.fill(child: LockScreenWidget()),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Root gate that handles auth routing, biometric lock overlay, and app lifecycle.
class AppAuthGate extends StatefulWidget {
  const AppAuthGate({super.key});

  @override
  State<AppAuthGate> createState() => _AppAuthGateState();
}

class _AppAuthGateState extends State<AppAuthGate> with WidgetsBindingObserver {
  final Set<String> _restoredCallIds = {};
  final Set<String> _navigatedCallIds = {};
  String? _incomingCallDialogId;
  bool _fullScreenPermissionRequested = false;
  StreamSubscription<RemoteMessage>? _callPushSubscription;
  StreamSubscription<CallDataEntity>? _callKitAcceptSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callKitAcceptSubscription = callKitAcceptedActions.listen((callData) {
      if (mounted) {
        context.read<CallsBloc>().add(CallKitAccepted(callData));
      }
    });
    if (authBackend == AuthBackend.firebase) {
      _callPushSubscription = FirebaseMessaging.onMessage.listen((message) {
        final action = message.data['action'] ?? message.data['type'];
        if (action != 'cancel_call') return;
        final callId = (message.data['callId'] ?? message.data['id'])?.toString();
        if (callId == null || callId.isEmpty || !mounted) return;
        context.read<CallsBloc>().add(CallCancellationPushReceived(callId));
      });
    }
    // Perform cold-start lock check and sync auth status after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_requestFullScreenCallPermission());
        final authState = context.read<AuthBloc>().state;
        final isAuth = authState.status == AuthStatus.authenticated;
        context.read<LockBloc>()
          ..add(LockAuthStatusChanged(isAuthenticated: isAuth))
          ..add(const LockCheckRequested());

        if (isAuth && authState.user != null) {
          final userIdentifier = authState.user!.email.isNotEmpty
              ? authState.user!.email
              : authState.user!.id;
          unawaited(_restoreCallKitActionsThenListen(userIdentifier));
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_callPushSubscription?.cancel());
    unawaited(_callKitAcceptSubscription?.cancel());
    super.dispose();
  }

  AppLifecycleState? _lastLifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final previous = _lastLifecycleState;
    _lastLifecycleState = state;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // Only dispatch pause when transitioning away from resumed/active state.
        // Prevents re-dispatching pause during intermediate resume steps (paused -> hidden -> inactive -> resumed).
        if (mounted && (previous == null || previous == AppLifecycleState.resumed)) {
          context.read<LockBloc>().add(const LockAppPaused());
        }
      case AppLifecycleState.resumed:
        if (mounted) {
          context.read<LockBloc>().add(const LockAppResumed());
          unawaited(_restoreAcceptedCallIfAny().then((_) => _navigateToCurrentAcceptedCall()));
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Sync auth status with LockBloc and handle logout cleanup
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            final isAuth = state.status == AuthStatus.authenticated;
            context.read<LockBloc>().add(LockAuthStatusChanged(isAuthenticated: isAuth));

            if (isAuth && state.user != null) {
              final userIdentifier = state.user!.email.isNotEmpty
                  ? state.user!.email
                  : state.user!.id;
              unawaited(_restoreCallKitActionsThenListen(userIdentifier));
            }

            if (state.status == AuthStatus.unauthenticated) {
              debugPrint('AppAuthGate: popUntil called (unauthenticated)');
              globalNavigatorKey.currentState?.popUntil((route) => route.isFirst);
              context.read<LockBloc>().clearAndReset();
              context.read<CallsBloc>().add(const StopListeningIncomingCalls());
            }
          },
        ),
        // When login succeeds and device supports biometrics → offer setup
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current.status == AuthStatus.authenticated &&
              current.offerBiometricSetup &&
              !previous.offerBiometricSetup,
          listener: (context, state) async {
            // Acknowledge immediately so we don't re-trigger on rebuild
            context.read<AuthBloc>().add(const AuthBiometricOfferAcknowledged());
            // Show the offer dialog
            await BiometricOfferDialog.show(context);
          },
        ),
        // When LockBloc signals password login requested → trigger logout
        BlocListener<LockBloc, lock.LockState>(
          listenWhen: (previous, current) =>
              current.status == lock.LockStatus.requiresLogout &&
              previous.status != lock.LockStatus.requiresLogout,
          listener: (context, state) {
            context.read<AuthBloc>().add(const AuthLogOutRequested());
          },
        ),
        // When an incoming call arrives → show incoming call dialog
        BlocListener<CallsBloc, CallsState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == CallsStatus.ringingIncoming &&
              current.activeCall != null,
          listener: (context, state) {
            if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
              debugPrint(
                '[CallNavigation] Skipping in-app incoming dialog while app is backgrounded',
              );
              return;
            }
            final authState = context.read<AuthBloc>().state;
            final currentUserId = (authState.user?.email.isNotEmpty == true)
                ? authState.user!.email
                : (authState.user?.id ?? '');
            final call = state.activeCall!;
            _incomingCallDialogId = call.id;
            unawaited(
              IncomingCallDialog.show(
                context,
                call: call,
                currentUserId: currentUserId,
              ).whenComplete(() {
                if (mounted && _incomingCallDialogId == call.id) {
                  _incomingCallDialogId = null;
                }
              }),
            );
          },
        ),
        BlocListener<CallsBloc, CallsState>(
          listenWhen: (previous, current) =>
              current is CallAcceptedState &&
              (previous is! CallAcceptedState ||
                  previous.callData.callId != current.callData.callId),
          listener: (context, state) {
            if (state is! CallAcceptedState) return;
            _navigateToAcceptedCall(state.callData);
          },
        ),
        BlocListener<CallsBloc, CallsState>(
          listenWhen: (previous, current) =>
              current.status == CallsStatus.idle && previous.status != CallsStatus.idle,
          listener: (_, _) {
            _restoredCallIds.clear();
            _navigatedCallIds.clear();
          },
        ),
        BlocListener<CallsBloc, CallsState>(
          listenWhen: (_, current) => current is CallEndedState && current.callId != null,
          listener: (_, state) {
            final endedState = state as CallEndedState;
            unawaited(_clearPendingCallKitDecline(endedState.callId!));
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return switch (authState.status) {
            AuthStatus.initial || AuthStatus.loadingBeforeStart => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            AuthStatus.authenticated => const MainScreen(),
            AuthStatus.unauthenticated ||
            AuthStatus.loadingFormSubmit ||
            AuthStatus.failure => const AuthScreen(),
          };
        },
      ),
    );
  }

  Future<void> _requestFullScreenCallPermission() async {
    if (_fullScreenPermissionRequested ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _fullScreenPermissionRequested = true;
    try {
      if (!await FlutterCallkitIncoming.canUseFullScreenIntent()) {
        await FlutterCallkitIncoming.requestFullIntentPermission();
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to request full-screen call permission: $error\n$stackTrace');
    }
  }

  Future<void> _restoreCallKitActionsThenListen(String userIdentifier) async {
    await _restoreAcceptedCallIfAny();
    if (!mounted) return;
    context.read<CallsBloc>().add(ListenIncomingCallsStarted(userIdentifier));
    _navigateToCurrentAcceptedCall();
  }

  void _navigateToCurrentAcceptedCall() {
    if (!mounted) return;
    final state = context.read<CallsBloc>().state;
    if (state is CallAcceptedState) {
      _navigateToAcceptedCall(state.callData);
    }
  }

  void _navigateToAcceptedCall(CallDataEntity callData) {
    if (!mounted || !_navigatedCallIds.add(callData.callId)) return;
    _restoredCallIds.add(callData.callId);
    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) {
      _navigatedCallIds.remove(callData.callId);
      debugPrint('[CallNavigation] Navigator is not ready for ${callData.callId}');
      return;
    }

    if (_incomingCallDialogId != null && navigator.canPop()) {
      navigator.pop();
      _incomingCallDialogId = null;
    }
    final route = callData.isGroup
        ? MaterialPageRoute<void>(
            builder: (_) => GroupCallScreen(
              callId: callData.callId,
              groupName: callData.displayName,
              callType: callData.callType,
            ),
          )
        : callData.callType == CallType.video
        ? MaterialPageRoute<void>(
            builder: (_) => VideoCallScreen(
              callId: callData.callId,
              opponentName: callData.displayName,
              opponentAvatarUrl: callData.callerAvatarUrl,
              opponentId: callData.callerId,
            ),
          )
        : MaterialPageRoute<void>(
            builder: (_) => AudioCallScreen(
              callId: callData.callId,
              opponentName: callData.displayName,
              opponentAvatarUrl: callData.callerAvatarUrl,
            ),
          );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentNavigator = globalNavigatorKey.currentState;
      if (!mounted || currentNavigator == null) {
        _navigatedCallIds.remove(callData.callId);
        return;
      }
      debugPrint('[CallNavigation] Opening call screen for ${callData.callId}');
      currentNavigator.push(route);
    });
  }

  Future<void> _restoreAcceptedCallIfAny() async {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated || authState.user == null) {
      return;
    }

    try {
      final preferences = getIt<SharedPreferences>();
      // CallKit background callbacks run in another isolate. Refresh this
      // isolate's SharedPreferences cache before reading a persisted Accept.
      await preferences.reload();
      if (!mounted) return;
      final pendingDecline = preferences.getString(pendingCallKitDeclinePreferenceKey);
      if (pendingDecline != null) {
        final declinedCall = CallDataEntity.fromMap(
          Map<String, dynamic>.from(jsonDecode(pendingDecline) as Map),
        );
        if (declinedCall.callId.isNotEmpty) {
          context.read<CallsBloc>().add(CallKitDeclined(declinedCall));
        }
      }
      final pendingAccept = preferences.getString(pendingCallKitAcceptPreferenceKey);
      if (pendingAccept != null) {
        final callData = CallDataEntity.fromMap(
          Map<String, dynamic>.from(jsonDecode(pendingAccept) as Map),
        );
        if (callData.callId.isNotEmpty && _restoredCallIds.add(callData.callId)) {
          context.read<CallsBloc>().add(CallKitAccepted(callData));
          await preferences.remove(pendingCallKitAcceptPreferenceKey);
          return;
        }
      }
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (!mounted) return;
      for (final params in calls) {
        if (!params.isAccepted || !_restoredCallIds.add(params.id)) continue;
        context.read<CallsBloc>().add(CallKitAccepted(_callDataFromCallKitParams(params)));
        break;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to restore accepted CallKit call: $error\n$stackTrace');
    }
  }

  Future<void> _clearPendingCallKitDecline(String callId) async {
    try {
      final preferences = getIt<SharedPreferences>();
      await preferences.reload();
      final pending = preferences.getString(pendingCallKitDeclinePreferenceKey);
      if (pending == null) return;
      final callData = CallDataEntity.fromMap(
        Map<String, dynamic>.from(jsonDecode(pending) as Map),
      );
      if (callData.callId == callId) {
        await preferences.remove(pendingCallKitDeclinePreferenceKey);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to clear pending CallKit decline: $error\n$stackTrace');
    }
  }
}

CallDataEntity _callDataFromCallKitParams(CallKitParams params) {
  return CallDataEntity.fromMap({
    ...?params.extra,
    'callId': params.id,
    'displayName': params.nameCaller,
    'handle': params.handle,
    'callType': params.type?.toString() ?? '0',
  });
}

Future<void> _configureSelectedAuthBackend() async {
  if (authBackend == AuthBackend.firebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('Firebase init timed out!');
        return Firebase.app();
      },
    );
    return;
  }

  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.addPlugin(AmplifyAPI());
    await Amplify.addPlugin(AmplifyStorageS3());

    final configString = await rootBundle.loadString('amplify_outputs.json');
    await Amplify.configure(configString).timeout(const Duration(seconds: 10));

    safePrint('Amplify successfully configured with Gen 2 outputs!');
  } on AmplifyAlreadyConfiguredException {
    safePrint('Amplify was already configured.');
  } on TimeoutException {
    safePrint('Amplify configure timed out. Continue app startup without blocking UI.');
  } catch (error, stackTrace) {
    safePrint('Amplify configure failed: $error');
    safePrint('$stackTrace');
  }
}

ThemeMode _mapThemeModeToFlutterThemeMode(AppThemeMode themeModeEnum) {
  return switch (themeModeEnum) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}
