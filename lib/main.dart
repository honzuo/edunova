/// main.dart — Application entry point for EduNova.
///
/// Data Architecture:
///   Supabase (cloud)  → Primary data store for all important data
///   SQLite (local)    → Only for achievements, goals, reminders, preferences
///   SharedPreferences → Session persistence (user ID, email, onboarding)
///
/// Related SDG: #4 Quality Education

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'providers/task_provider.dart';
import 'providers/session_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/user_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/goal_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

/// Supabase project URL.
const String _supabaseUrl = 'https://seinakjdxsymlqkpltnb.supabase.co';

/// Supabase anonymous API key.
const String _supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlaW5ha2pkeHN5bWxxa3BsdG5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMjI1NTMsImV4cCI6MjA5MDc5ODU1M30.3j-Woa22nu_4I7KbPMteXyC1NmgkwGowh978PDAhD2Y';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Connect to Supabase (primary data source)
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);

  // Step 2: Initialize local SQLite (for achievements, goals, reminders only)
  await DatabaseService().database;

  // Step 3: Initialize notification service for study reminders
  await NotificationService().init();

  // Step 4: Load saved user session from SharedPreferences
  await AuthService().loadSession();

  // No sync needed — all important data reads directly from Supabase

  // Step 5: Launch app with all providers
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
