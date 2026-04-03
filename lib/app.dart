import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';

class EduNovaApp extends StatelessWidget {
  const EduNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduNova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return const LoginScreen();
    } else {
      return const MainScreen();
    }
  }
}