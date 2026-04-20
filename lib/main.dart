import 'package:collab_tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/ui/screens/main_screen/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'di/service_locator.dart';
import 'l10n/app_localizations.dart';

void main() {
  // Убеждаемся, что инициализация БД (если она асинхронная) завершена
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide TaskViewModel via Provider + GetIt factory
    return MultiBlocProvider(
      providers: [
        // Создаем блок через GetIt и СРАЗУ отправляем ивент на загрузку данных
        BlocProvider<TaskBloc>(create: (_) => getIt<TaskBloc>()..add(LoadTasksStarted())),
      ],
      child: MaterialApp(
        title: 'CollabTasks',
        // ----- IMPORTANT: localization delegates -----
        localizationsDelegates: const [
          AppLocalizations.delegate,
          FlutterQuillLocalizations.delegate, // <-- flutter_quill (formatting lib)
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // you can list needed locales explicitly or reuse the global supported list
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
