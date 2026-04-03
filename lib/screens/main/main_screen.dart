import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../task/task_screen.dart';
import '../calendar/calendar_screen.dart';
import '../progress/progress_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  late final List<Widget> screens = [
    HomeScreen(onNavigate: changeTab),
    const TaskScreen(),
    const CalendarScreen(),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: changeTab,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Task'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}