import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../services/database_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

  String get _email =>
      Supabase.instance.client.auth.currentUser?.email ?? '';

  Future<void> loadUser() async {
    final data = await _db.getUserById(_userId);

    if (data != null) {
      _currentUser = AppUser.fromMap(data);
    } else {
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

      await _db.insertUser(_currentUser!.toMap());
    }

    notifyListeners();
  }

  Future<void> saveUser({
    required String fullName,
    required int age,
    required String gender,
    required String institution,
    required String course,
    required String studyGoal,
  }) async {
    final user = AppUser(
      id: _userId,
      email: _email,
      fullName: fullName,
      age: age,
      gender: gender,
      institution: institution,
      course: course,
      studyGoal: studyGoal,
      createdAt: _currentUser?.createdAt ?? DateTime.now(),
    );

    final existing = await _db.getUserById(_userId);
    if (existing == null) {
      await _db.insertUser(user.toMap());
    } else {
      await _db.updateUser(_userId, user.toMap());
    }

    _currentUser = user;
    notifyListeners();
  }
}