import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskie/presentation/viewmodels/app_shell_viewmodel.dart';
import 'package:taskie/presentation/views/screens/categories_screen.dart';
import 'package:taskie/presentation/views/screens/home_screen.dart';
import 'package:taskie/presentation/views/screens/stats_screen.dart';
import 'package:taskie/presentation/views/screens/timetable_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final shellVM = context.watch<AppShellViewModel>();
    return Scaffold(
      body: IndexedStack(
        index: shellVM.currentIndex,
        children: [
          HomeScreen(),
          CategoriesScreen(),
          TimetableScreen(),
          StatsScreen()
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shellVM.currentIndex,
        onDestinationSelected: shellVM.setIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), 
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined), 
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined), 
            label: 'Progress',
          ),
        ]
      ),
    );
  }
}