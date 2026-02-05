import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'di/service_locator.dart';
import 'ui/screens/home_screen.dart';
import 'ui/view_models/task_view_model.dart';

void main() {
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide TaskViewModel via Provider + GetIt factory
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskViewModel>(
          create: (_) => GetIt.instance<TaskViewModel>()..loadTasks(),
        ),
      ],
      child: MaterialApp(
        title: 'Safe Tasks (dialog owns controller)',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
