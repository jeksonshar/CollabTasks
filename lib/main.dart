import 'dart:async';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:collab_tasks/amplify_configuration.dart';
import 'package:collab_tasks/core/notifications/notifications_manager.dart';
import 'package:collab_tasks/core/utils/auth_utils.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/firebase_options.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_event.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_state.dart';
import 'package:collab_tasks/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/ui/screens/auth_screen/auth_screen.dart';
import 'package:collab_tasks/ui/screens/main_screen/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureSelectedAuthBackend();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final sharedPreferences = await SharedPreferences.getInstance();
  setupLocator(sharedPreferences);
  await getIt<NotificationsManager>().initialize();
  runApp(const MyApp());
}

Future<void> _configureSelectedAuthBackend() async {
  if (authBackend != AuthBackend.aws) {
    return;
  }

  try {
    final authPlugin = AmplifyAuthCognito();
    await Amplify.addPlugin(authPlugin);
    await Amplify.configure(amplifyConfig).timeout(const Duration(seconds: 10));
  } on AmplifyAlreadyConfiguredException {
    safePrint('Amplify was already configured.');
  } on TimeoutException {
    safePrint('Amplify configure timed out. Continue app startup without blocking UI.');
  } catch (error, stackTrace) {
    safePrint('Amplify configure failed: $error');
    safePrint('$stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>(create: (_) => getIt<LocaleCubit>()),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const AuthSubscriptionStarted()),
        ),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return MaterialApp(
                title: 'CollabTasks',
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  FlutterQuillLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                ),
                home: switch (authState.status) {
                  AuthStatus.initial || AuthStatus.loadingBeforeStart => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                  AuthStatus.authenticated => const MainScreen(),
                  AuthStatus.unauthenticated ||
                  AuthStatus.loadingFormSubmit ||
                  AuthStatus.failure => const AuthScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
