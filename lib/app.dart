/// app.dart — Root application widget and authentication wrapper.
///
/// [EduNovaApp] configures MaterialApp with theme support (light/dark).
/// [AuthWrapper] determines the initial screen based on:
/// - Whether onboarding has been completed (SharedPreferences)
/// - Whether a user session exists (AuthService)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'constants/subjects.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';

/// Root widget that configures MaterialApp with theming.
class EduNovaApp extends StatelessWidget {
  const EduNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'EduNova',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AuthWrapper(),
    );
  }
}

/// Determines the initial screen based on authentication and onboarding state.
///
/// Flow:
/// 1. Show loading indicator while checking state
/// 2. If onboarding not done → OnboardingScreen
/// 3. If not logged in → LoginScreen
/// 4. If logged in → MainScreen
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _onboardingDone;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Load session state and onboarding flag from SharedPreferences.
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    await AuthService().loadSession();

    if (mounted) {
      setState(() {
        _onboardingDone = prefs.getBool('onboarding_complete') ?? false;
        _ready = true;
      });

      // Pre-load user data if already logged in
      if (AuthService().isLoggedIn) {
        context.read<UserProvider>().loadUser();
        context.read<ThemeProvider>().loadPreference();
        SubjectService().load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while initializing
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show onboarding for first-time users
    if (_onboardingDone == false) {
      return OnboardingScreen(
        onComplete: () => setState(() => _onboardingDone = true),
      );
    }

    // Show main screen or login based on auth state
    return AuthService().isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}
