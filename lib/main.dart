import 'dart:async';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:collab_tasks/core/theme/app_theme.dart';
import 'package:collab_tasks/core/utils/auth_utils.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_event.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_state.dart';
import 'package:collab_tasks/features/auth/ui/auth_screen/auth_screen.dart';
import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_bloc.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_state.dart';
import 'package:collab_tasks/features/tasks/data/notifications/task_notifications_manager.dart';
import 'package:collab_tasks/features/tasks/ui/screens/main_screen/main_screen.dart';
import 'package:collab_tasks/firebase_options.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureSelectedAuthBackend();
  final sharedPreferences = await SharedPreferences.getInstance();
  setupLocator(sharedPreferences);
  await getIt<TaskNotificationsManager>().initialize();
  runApp(const MyApp());
}

Future<void> _configureSelectedAuthBackend() async {
  if (authBackend == AuthBackend.firebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return;
  }

  try {
    // Add plugins
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.addPlugin(AmplifyAPI());
    await Amplify.addPlugin(AmplifyStorageS3());

    // 1. Read string from assets
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

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

ThemeMode _mapThemeModeToFlutterThemeMode(AppThemeMode themeModeEnum) {
  return switch (themeModeEnum) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
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
      ],
      // Listen to the locale and theme above MaterialApp to change the application configuration
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
                home: const AppAuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}

class AppAuthGate extends StatelessWidget {
  const AppAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Слушаем только тот момент, когда статус меняется на неавторизованный из авторизованого
      listenWhen: (previous, current) =>
          current.status == AuthStatus.unauthenticated &&
          previous.status == AuthStatus.authenticated,
      listener: (context, state) {
        debugPrint('AppAuthGate in main.dart popUntil((route) => false) called');
        // HERE we safely clean the stack.
        globalNavigatorKey.currentState?.popUntil((route) => false);
      },
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
}
