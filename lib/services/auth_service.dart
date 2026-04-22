/// auth_service.dart — Custom authentication via Supabase [app_users] table.
///
/// Implements register, login, logout, and account deletion.
/// Passwords are hashed with SHA-256 before storage.
/// Session persistence via SharedPreferences (user ID and email).

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Custom auth via app_users table (Member 1 CRUD).
class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();
  SupabaseClient get _supa => Supabase.instance.client;
  String? _currentUserId;
  String? _currentEmail;
  String? get currentUserId => _currentUserId;
  String? get currentEmail => _currentEmail;
  bool get isLoggedIn => _currentUserId != null;
  /// Hash password with SHA-256 before storing.
  String _hash(String pw) => sha256.convert(utf8.encode(pw)).toString();

  /// Restore user session from SharedPreferences.
  Future<void> loadSession() async {
    final p = await SharedPreferences.getInstance();
    _currentUserId = p.getString('auth_user_id');
    _currentEmail = p.getString('auth_email');
  }

  /// Register a new user account. Returns success/failure with message.
  Future<({bool ok, String msg})> register({required String email, required String password}) async {
    try {
      final ex = await _supa.from('app_users').select('id').eq('email', email).maybeSingle();
      if (ex != null) return (ok: false, msg: 'Email already registered');
      await _supa.from('app_users').insert({
        'id': const Uuid().v4(), 'email': email, 'password_hash': _hash(password),
        'full_name': '', 'age': 0, 'gender': '', 'institution': '', 'course': '',
        'study_goal': '', 'target_gpa': 3.5, 'profile_photo_path': '', 'dark_mode': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      return (ok: true, msg: 'Account created! Please login.');
    } catch (e) { debugPrint('Register: $e'); return (ok: false, msg: 'Registration failed'); }
  }

  /// Authenticate user with email and password hash comparison.
  Future<({bool ok, String msg})> login({required String email, required String password}) async {
    try {
      final r = await _supa.from('app_users').select().eq('email', email).eq('password_hash', _hash(password)).maybeSingle();
      if (r == null) return (ok: false, msg: 'Invalid email or password');
      _currentUserId = r['id'] as String; _currentEmail = r['email'] as String;
      final p = await SharedPreferences.getInstance();
      await p.setString('auth_user_id', _currentUserId!);
      await p.setString('auth_email', _currentEmail!);
      return (ok: true, msg: 'Login successful');
    } catch (e) { debugPrint('Login: $e'); return (ok: false, msg: 'Login failed'); }
  }

  /// Clear session data and remove from SharedPreferences.
  Future<void> logout() async {
    _currentUserId = null; _currentEmail = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('auth_user_id'); await p.remove('auth_email');
  }

  /// Permanently delete user account from Supabase.
  Future<bool> deleteAccount() async {
    if (_currentUserId == null) return false;
    try { await _supa.from('app_users').delete().eq('id', _currentUserId!); await logout(); return true; }
    catch (e) { return false; }
  }

  /// Reset password for an existing account by email.
  /// Verifies email exists, then updates the password_hash.
  Future<({bool ok, String msg})> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final user = await _supa
          .from('app_users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (user == null) return (ok: false, msg: 'Email not found');
      await _supa
          .from('app_users')
          .update({'password_hash': _hash(newPassword)})
          .eq('email', email);
      return (ok: true, msg: 'Password reset successful! Please login.');
    } catch (e) {
      debugPrint('Reset password: $e');
      return (ok: false, msg: 'Password reset failed');
    }
  }
}
