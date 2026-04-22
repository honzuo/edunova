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
import '../../services/notification_service.dart';
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

  // ═══════════════════════════════
  // ── Auth Methods ──
  // ═══════════════════════════════

  /// Validate and login.
  Future<void> _login() async {
    await NotificationService().showNow(title: 'title', body: 'body');
    await NotificationService().scheduleReminder(
      id: 10,
      title: 'Test Reminder',
      body: 'This should appear in 1 minutes',
      triggerTime: DateTime.now().add(const Duration(minutes: 1)),
    );
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

  /// Validate (including confirm password match) and register.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final r = await AuthService().register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    if (mounted) {
      _snack(r.msg);
      // Switch back to login mode on success
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

  /// Toggle between login ↔ register mode.
  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _passCtrl.clear();
      _confirmPassCtrl.clear();
      _formKey.currentState?.reset();
    });
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════
  // ── Forgot Password Sheet ──
  // ═══════════════════════════════

  void _showForgotPassword() {
    final fKey = GlobalKey<FormState>();
    final emailC = TextEditingController(text: _emailCtrl.text.trim());
    final newPassC = TextEditingController();
    final confirmC = TextEditingController();
    bool obsNew = true, obsConfirm = true, loading = false;

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: fKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Reset Password',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Enter your email and set a new password',
                      style:
                      TextStyle(fontSize: 14, color: Colors.grey[500]))),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: emailC,
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

              // New Password
              TextFormField(
                controller: newPassC,
                obscureText: obsNew,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  prefixIcon:
                  const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                      icon: Icon(
                          obsNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setSt(() => obsNew = !obsNew)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter new password';
                  if (v.trim().length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Confirm New Password
              TextFormField(
                controller: confirmC,
                obscureText: obsConfirm,
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                  suffixIcon: IconButton(
                      icon: Icon(
                          obsConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () =>
                          setSt(() => obsConfirm = !obsConfirm)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Confirm password';
                  if (v.trim() != newPassC.text.trim()) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Reset button
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                  if (!fKey.currentState!.validate()) return;
                  setSt(() => loading = true);
                  final r = await AuthService().resetPassword(
                    email: emailC.text.trim(),
                    newPassword: newPassC.text.trim(),
                  );
                  if (!ctx.mounted) return;
                  // Pop bottom sheet and pass result message back
                  Navigator.pop(ctx, r.msg);
                },
                child: loading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Reset Password'),
              ),
            ]),
          ),
        ),
      ),
    ).then((resultMsg) {
      emailC.dispose();
      newPassC.dispose();
      confirmC.dispose();
      // Show snackbar AFTER bottom sheet is fully closed
      if (resultMsg != null && mounted) {
        _snack(resultMsg);
      }
    });
  }

  // ═══════════════════════════════
  // ── Build UI ──
  // ═══════════════════════════════

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

                // ── Logo ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.school_rounded,
                      size: 40, color: cs.primary),
                ),
                const SizedBox(height: 20),

                // ── Title ──
                Text('EduNova',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(
                    _isRegisterMode
                        ? 'Create your account'
                        : 'Study smarter, not harder.',
                    style:
                    TextStyle(fontSize: 15, color: Colors.grey[500])),
                const SizedBox(height: 48),

                // ── Email ──
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon:
                      Icon(Icons.mail_outline_rounded, size: 20)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!_emailRegex.hasMatch(v.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Password ──
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon:
                    const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    if (v.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // ── Confirm Password (register mode only) ──
                if (_isRegisterMode) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      prefixIcon:
                      const Icon(Icons.lock_rounded, size: 20),
                      suffixIcon: IconButton(
                          icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20),
                          onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (v.trim() != _passCtrl.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],

                // ── Forgot Password (login mode only) ──
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

                // ── Primary Button ──
                ElevatedButton(
                  onPressed:
                  _loading ? null : (_isRegisterMode ? _register : _login),
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : Text(
                      _isRegisterMode ? 'Create Account' : 'Sign In'),
                ),
                const SizedBox(height: 16),

                // ── Toggle mode ──
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                      _isRegisterMode
                          ? 'Already have an account?'
                          : "Don't have an account?",
                      style:
                      TextStyle(fontSize: 14, color: Colors.grey[500])),
                  TextButton(
                    onPressed: _loading ? null : _toggleMode,
                    child: Text(
                        _isRegisterMode ? 'Sign In' : 'Register',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
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