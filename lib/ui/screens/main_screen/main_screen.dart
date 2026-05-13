import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/l10n/l10n_mixin.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_state.dart';
import 'package:collab_tasks/ui/screens/group_screen/group_screen.dart';
import 'package:collab_tasks/ui/screens/home_screen/home_tasks_screen.dart';
import 'package:collab_tasks/ui/screens/settings_screen/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with L10nMixin {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTasksScreen(),
    const GroupScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TaskBloc>(
      create: (context) {
        return getIt<TaskBloc>(
          param1: localization.deadlineIn30MinutesTitle,
          param2: localization.deadlineReachedTitle,
        )..add(LoadTasksStarted());
      },
      child: BlocListener<TaskBloc, TaskState>(
        listenWhen: (previous, current) =>
            previous.highlightedTaskVersion != current.highlightedTaskVersion,
        listener: (context, state) {
          if (_selectedIndex == 0) {
            return;
          }
          setState(() {
            _selectedIndex = 0;
          });
        },
        child: Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            elevation: 12,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            selectedItemColor: Colors.indigo,
            // unselectedItemColor: Colors.blue.shade200,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: localization.home),
              BottomNavigationBarItem(icon: const Icon(Icons.group), label: localization.groups),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: localization.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
