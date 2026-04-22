/// user_provider.dart — State management for user profile.
///
/// User profile data is stored in Supabase (cloud).
/// Profile photo is saved to local device storage via path_provider.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_user.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  String get _userId => AuthService().currentUserId ?? 'demo-user';
  String get _email => AuthService().currentEmail ?? '';

  /// Load user profile from Supabase. Creates default if not found.
  Future<void> loadUser() async {
    try {
      final data = await _db.getUserById(_userId);
      if (data != null) {
        _currentUser = AppUser.fromMap(data);
      } else {
        // User exists in Supabase (created by AuthService.register)
        // but we create a local fallback just in case
        _currentUser = AppUser(
          id: _userId,
          email: _email,
          fullName: '',
          age: 0,
          gender: '',
          institution: '',
          course: '',
          studyGoal: '',
          createdAt: DateTime.now(),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  /// Save updated profile fields to Supabase.
  Future<void> saveUser({
    required String fullName,
    required int age,
    required String gender,
    required String institution,
    required String course,
    required String studyGoal,
  }) async {
    final u = _currentUser!.copyWith(
      fullName: fullName,
      age: age,
      gender: gender,
      institution: institution,
      course: course,
      studyGoal: studyGoal,
    );
    await _db.updateUser(_userId, u.toMap());
    _currentUser = u;
    notifyListeners();
  }

  /// Update the user's target GPA in Supabase.
  Future<void> setTargetGpa(double gpa) async {
    final u = _currentUser!.copyWith(targetGpa: gpa);
    await _db.updateUser(_userId, u.toMap());
    _currentUser = u;
    notifyListeners();
  }

  /// Toggle dark mode preference in Supabase.
  Future<void> setDarkMode(bool v) async {
    final u = _currentUser!.copyWith(darkMode: v);
    await _db.updateUser(_userId, u.toMap());
    _currentUser = u;
    notifyListeners();
  }

  /// Save profile photo to local device and update path in Supabase.
  Future<void> setProfilePhoto(File f) async {
    final dir = await getApplicationDocumentsDirectory();
    final saved = await f.copy('${dir.path}/profile_$_userId.jpg');
    final u = _currentUser!.copyWith(profilePhotoPath: saved.path);
    await _db.updateUser(_userId, u.toMap());
    _currentUser = u;
    notifyListeners();
  }

  /// Remove profile photo from device and clear path in Supabase.
  Future<void> removeProfilePhoto() async {
    if (_currentUser!.profilePhotoPath.isNotEmpty) {
      try {
        await File(_currentUser!.profilePhotoPath).delete();
      } catch (_) {}
    }
    final u = _currentUser!.copyWith(profilePhotoPath: '');
    await _db.updateUser(_userId, u.toMap());
    _currentUser = u;
    notifyListeners();
  }
}
