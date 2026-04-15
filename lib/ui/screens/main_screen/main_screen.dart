import 'package:collab_tasks/l10n/l10n_mixin.dart';
import 'package:collab_tasks/ui/screens/group_screen/group_screen.dart';
import 'package:collab_tasks/ui/screens/home_screen/home_tasks_screen.dart';
import 'package:collab_tasks/ui/screens/profile_screen/profile_screen.dart';
import 'package:flutter/material.dart';

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
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 12,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        // selectedItemColor: Colors.white,
        // unselectedItemColor: Colors.blue.shade200,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: localization.home),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: localization.groups),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: localization.profile),
        ],
      ),
    );
  }
}
