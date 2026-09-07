import 'dart:async';

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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Инициализируем Firebase с конфигурацией платформы
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).timeout(
    const Duration(seconds: 3),
    onTimeout: () {
      debugPrint('Firebase init timed out!');
      return Firebase.app();
    },
  );
  debugPrint("=== [FCM] Обработан пуш в состоянии Terminated: ${message.messageId} ===");
}

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
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Perform cold-start lock check after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LockBloc>().add(const LockCheckRequested());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (mounted) {
          context.read<LockBloc>().add(const LockAppPaused());
        }
      case AppLifecycleState.resumed:
        if (mounted) {
          context.read<LockBloc>().add(const LockAppResumed());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // When unauthenticated after being authenticated → clear the nav stack
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current.status == AuthStatus.unauthenticated &&
              previous.status == AuthStatus.authenticated,
          listener: (context, state) {
            debugPrint('AppAuthGate: popUntil called (unauthenticated)');
            globalNavigatorKey.currentState?.popUntil((route) => false);
            // Also reset LockBloc to idle after logout
            context.read<LockBloc>().clearAndReset();
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
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final Widget mainContent = switch (authState.status) {
            AuthStatus.initial || AuthStatus.loadingBeforeStart => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            AuthStatus.authenticated => const MainScreen(),
            AuthStatus.unauthenticated ||
            AuthStatus.loadingFormSubmit ||
            AuthStatus.failure => const AuthScreen(),
          };

          // Overlay the lock / privacy screen on top of the main content
          return BlocBuilder<LockBloc, lock.LockState>(
            builder: (context, lockState) {
              return Stack(
                children: [
                  mainContent,
                  if (lockState.status == lock.LockStatus.privacyScreen)
                    const PrivacyScreenWidget()
                  else if (lockState.status == lock.LockStatus.locked ||
                      lockState.status == lock.LockStatus.authenticating)
                    const LockScreenWidget(),
                ],
              );
            },
          );
        },
      ),
    );
  }
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
