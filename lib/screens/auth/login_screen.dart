import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool _obscure = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password');
      return;
    }
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Login failed');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password');
      return;
    }
    if (password.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signUp(email: email, password: password);
      if (mounted) _snack('Account created! Please login.');
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Signup failed');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.school_rounded, size: 40,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 20),
                Text('EduNova', style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
                const SizedBox(height: 4),
                Text('Study smarter, not harder.',
                    style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                const SizedBox(height: 48),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: loading ? null : signup,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Create Account'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
