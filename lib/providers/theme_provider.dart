/// theme_provider.dart — State management for app theme.
///
/// Loads dark mode preference from Supabase [app_users] table.

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/app_user.dart';

class ThemeProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Load dark mode preference from Supabase.
  Future<void> loadPreference() async {
    try {
      final uid = AuthService().currentUserId ?? 'demo-user';
      final data = await _db.getUserById(uid);
      if (data != null) {
        _isDarkMode = AppUser.fromMap(data).darkMode;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// Toggle dark mode and save to Supabase.
  Future<void> toggleDarkMode(bool v) async {
    _isDarkMode = v;
    notifyListeners();
    try {
      final uid = AuthService().currentUserId ?? 'demo-user';
      final data = await _db.getUserById(uid);
      if (data != null) {
        await _db.updateUser(
          uid,
          AppUser.fromMap(data).copyWith(darkMode: v).toMap(),
        );
      }
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
}
