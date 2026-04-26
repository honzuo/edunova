/// login_screen.dart — Authentication screen with login, registration,
/// and forgot password functionality.
///
/// Features:
/// - Toggle between Sign In and Create Account modes
/// - Email format validation with regex
/// - Password validation (minimum 6 characters)
/// - Confirm Password field during registration (must match)
/// - Forgot Password bottom sheet with email + new password reset

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../main/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isRegisterMode = false;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final r = await AuthService().login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    if (mounted) {
      if (r.ok) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        _snack(r.msg);
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final r = await AuthService().register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    if (mounted) {
      _snack(r.msg);
      if (r.ok) {
        setState(() {
          _isRegisterMode = false;
          _passCtrl.clear();
          _confirmPassCtrl.clear();
        });
      }
      setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _passCtrl.clear();
      _confirmPassCtrl.clear();
      _formKey.currentState?.reset();
    });
  }

  void _showForgotPassword() {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ForgotPasswordBottomSheet(initialEmail: _emailCtrl.text.trim()),
    ).then((resultMsg) {
      if (!mounted) return;
      if (resultMsg != null) {
        Future.microtask(() {
          if (mounted) _snack(resultMsg);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/logo.png'),
                  ),
                ),
                const SizedBox(height: 20),
                Text('EduNova',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(
                    _isRegisterMode ? 'Create your account' : 'Study smarter, not harder.',
                    style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                const SizedBox(height: 48),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email address';
                    if (!_emailRegex.hasMatch(v.trim())) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your password';
                    if (v.trim().length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),

                if (_isRegisterMode) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                      suffixIcon: IconButton(
                          icon: Icon(
                              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please confirm your password';
                      if (v.trim() != _passCtrl.text.trim()) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],

                if (!_isRegisterMode) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPassword,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Forgot Password?',
                          style: TextStyle(
                              fontSize: 14,
                              color: cs.primary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : (_isRegisterMode ? _register : _login),
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
                const SizedBox(height: 16),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                      _isRegisterMode ? 'Already have an account?' : "Don't have an account?",
                      style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  TextButton(
                    onPressed: _loading ? null : _toggleMode,
                    child: Text(
                        _isRegisterMode ? 'Sign In' : 'Register',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordBottomSheet extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordBottomSheet({super.key, required this.initialEmail});

  @override
  State<ForgotPasswordBottomSheet> createState() => _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends State<ForgotPasswordBottomSheet> {
  final _fKey = GlobalKey<FormState>();
  late final TextEditingController _emailC;
  final _newPassC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _obsNew = true;
  bool _obsConfirm = true;
  bool _loading = false;

  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    _emailC = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailC.dispose();
    _newPassC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _fKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Reset Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Enter your email and set a new password',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!_emailRegex.hasMatch(v.trim())) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _newPassC,
                obscureText: _obsNew,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                      icon: Icon(
                          _obsNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _obsNew = !_obsNew)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter new password';
                  if (v.trim().length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _confirmC,
                obscureText: _obsConfirm,
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                  suffixIcon: IconButton(
                      icon: Icon(
                          _obsConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _obsConfirm = !_obsConfirm)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Confirm password';
                  if (v.trim() != _newPassC.text.trim()) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                  if (!_fKey.currentState!.validate()) return;
                  setState(() => _loading = true);
                  final r = await AuthService().resetPassword(
                    email: _emailC.text.trim(),
                    newPassword: _newPassC.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context, r.msg);
                },
                child: _loading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}