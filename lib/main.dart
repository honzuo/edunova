import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'providers/task_provider.dart';
import 'providers/session_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'providers/reminder_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/user_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/goal_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://seinakjdxsymlqkpltnb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlaW5ha2pkeHN5bWxxa3BsdG5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMjI1NTMsImV4cCI6MjA5MDc5ODU1M30.3j-Woa22nu_4I7KbPMteXyC1NmgkwGowh978PDAhD2Y',
  );

  await DatabaseService().database;
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadPreference()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
      ],
      child: const EduNovaApp(),
    ),
  );
}

