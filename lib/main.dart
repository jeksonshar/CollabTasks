import 'package:collab_tasks/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/ui/screens/main_screen/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'di/service_locator.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  setupLocator(sharedPreferences);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskBloc>(create: (_) => getIt<TaskBloc>()..add(LoadTasksStarted())),
        BlocProvider<LocaleCubit>(create: (_) => getIt<LocaleCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
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
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
