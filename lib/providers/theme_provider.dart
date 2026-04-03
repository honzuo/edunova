import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_preference.dart';
import '../services/database_service.dart';

class ThemeProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadPreference() async {
    final data = await _db.getUserPreference(_userId);

    if (data != null) {
      final pref = UserPreference.fromMap(data);
      _isDarkMode = pref.darkMode;
    } else {
      final pref = UserPreference(
        userId: _userId,
        darkMode: false,
        notificationEnabled: true,
        defaultReminderType: '1 hour before',
        dailySummaryEnabled: false,
      );

      await _db.insertUserPreference(pref.toMap());
      _isDarkMode = false;
    }

    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    final existing = await _db.getUserPreference(_userId);

    UserPreference pref;
    if (existing != null) {
      pref = UserPreference.fromMap(existing).copyWith(
        darkMode: value,
      );
      await _db.updateUserPreference(_userId, pref.toMap());
    } else {
      pref = UserPreference(
        userId: _userId,
        darkMode: value,
        notificationEnabled: true,
        defaultReminderType: '1 hour before',
        dailySummaryEnabled: false,
      );
      await _db.insertUserPreference(pref.toMap());
    }

    _isDarkMode = value;
    notifyListeners();
  }
}