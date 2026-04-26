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

/// Custom authentication service managing the app_users table.
class AuthService {
  // ── 1. Singleton Setup ──
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  // ── 2. Properties & Getters ──
  SupabaseClient get _supa => Supabase.instance.client;

  String? _currentUserId;
  String? _currentEmail;

  String? get currentUserId => _currentUserId;
  String? get currentEmail => _currentEmail;
  bool get isLoggedIn => _currentUserId != null;

  // ── 3. Helper Methods ──
  /// Hashes the password with SHA-256 before storing or comparing.
  String _hash(String pw) {
    return sha256.convert(utf8.encode(pw)).toString();
  }

  // ── 4. Session Management ──
  /// Restores the user session from local SharedPreferences upon app start.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('auth_user_id');
    _currentEmail = prefs.getString('auth_email');
  }

  /// Clears session data from memory and removes it from SharedPreferences.
  Future<void> logout() async {
    _currentUserId = null;
    _currentEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_email');
  }

  // ── 5. Core Authentication ──
  /// Registers a new user account into the Supabase database.
  /// Returns a record with a boolean success flag and a status message.
  Future<({bool ok, String msg})> register({
    required String email,
    required String password,
  }) async {
    try {
      // Check if the email is already registered
      final existingUser = await _supa
          .from('app_users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        return (ok: false, msg: 'Email already registered');
      }

      // Insert the new user with default empty values for profile fields
      await _supa.from('app_users').insert({
        'id': const Uuid().v4(),
        'email': email,
        'password_hash': _hash(password), // Securely hash the password
        'full_name': '',
        'age': 0,
        'gender': '',
        'institution': '',
        'course': '',
        'study_goal': '',
        'target_gpa': 3.5,
        'profile_photo_path': '',
        'dark_mode': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return (ok: true, msg: 'Account created! Please login.');
    } catch (e) {
      debugPrint('Register Error: $e');
      return (ok: false, msg: 'Registration failed');
    }
  }

  /// Authenticates a user by comparing the email and hashed password.
  Future<({bool ok, String msg})> login({
    required String email,
    required String password,
  }) async {
    try {
      // Query the user by email and matching password hash
      final userRecord = await _supa
          .from('app_users')
          .select()
          .eq('email', email)
          .eq('password_hash', _hash(password))
          .maybeSingle();

      if (userRecord == null) {
        return (ok: false, msg: 'Invalid email or password');
      }

      // Update current session variables
      _currentUserId = userRecord['id'] as String;
      _currentEmail = userRecord['email'] as String;

      // Persist the session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_id', _currentUserId!);
      await prefs.setString('auth_email', _currentEmail!);

      return (ok: true, msg: 'Login successful');
    } catch (e) {
      debugPrint('Login Error: $e');
      return (ok: false, msg: 'Login failed');
    }
  }

  // ── 6. Account Management ──
  /// Permanently deletes the current user's account from Supabase and clears the session.
  Future<bool> deleteAccount() async {
    if (_currentUserId == null) return false;

    try {
      await _supa.from('app_users').delete().eq('id', _currentUserId!);
      await logout(); // Clear local session after deletion
      return true;
    } catch (e) {
      debugPrint('Delete Account Error: $e');
      return false;
    }
  }

  /// Resets the password for an existing account by email.
  /// Verifies the email exists, then updates the password_hash.
  Future<({bool ok, String msg})> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Verify if the user exists
      final user = await _supa
          .from('app_users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        return (ok: false, msg: 'Email not found');
      }

      // Update the password with a new hash
      await _supa
          .from('app_users')
          .update({'password_hash': _hash(newPassword)})
          .eq('email', email);

      return (ok: true, msg: 'Password reset successful! Please login.');
    } catch (e) {
      debugPrint('Reset password Error: $e');
      return (ok: false, msg: 'Password reset failed');
    }
  }
}