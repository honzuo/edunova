/// settings_screen.dart — App settings and navigation hub.
///
/// Organized into sections:
/// - Account: Profile, Reminders
/// - Features: Achievements, Goals, Subjects, Export
/// - Preferences: Dark Mode toggle
/// - Info: About, Sign Out
/// - Danger Zone: Delete Account

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';

import 'profile_screen.dart';
import 'reminder_screen.dart';
import 'data_export_screen.dart';
import 'about_screen.dart';
import 'subject_screen.dart';
import '../achievements/achievements_screen.dart';
import '../goals/goal_screen.dart';
import '../auth/login_screen.dart';
import '../location/study_location_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ── Sign Out Logic ──
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (context.mounted) {
        // Clear navigation stack and redirect to Login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    }
  }

  // ── Delete Account Logic ──
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account?\n\n'
              'This action cannot be undone. All your study data, tasks, and achievements will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 显示一个加载圈，因为请求网络可能需要几秒钟
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      // 调用你 AuthService 里的删除逻辑
      final success = await AuthService().deleteAccount();

      if (context.mounted) {
        Navigator.pop(context); // 关掉加载圈

        if (success) {
          // 删除成功，清空路由栈并跳转回登录页
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
          );
        } else {
          // 删除失败，提示用户
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete account. Please try again.')),
          );
        }
      }
    }
  }

  // ── Main UI Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Settings'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── 1. ACCOUNT SECTION ──
                  _groupLabel('ACCOUNT'),
                  Card(
                    child: Column(
                      children: [
                        _item(context, 'Profile', Icons.person_rounded, const Color(0xFF5856D6), () => _push(context, const ProfileScreen())),
                        _div(),
                        _item(context, 'Reminders', Icons.notifications_rounded, const Color(0xFFFF3B30), () => _push(context, const ReminderScreen())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 2. FEATURES SECTION ──
                  _groupLabel('FEATURES'),
                  Card(
                    child: Column(
                      children: [
                        _item(context, 'Achievements', Icons.emoji_events_rounded, const Color(0xFFFF9500), () => _push(context, const AchievementsScreen())),
                        _div(),
                        _item(context, 'Study Goals', Icons.flag_rounded, const Color(0xFF34C759), () => _push(context, const GoalScreen())),
                        _div(),
                        _item(context, 'Subjects', Icons.book_rounded, const Color(0xFFAF52DE), () => _push(context, const SubjectScreen())),
                        _div(),
                        _item(context, 'Study Locations', Icons.location_on_rounded, const Color(0xFF34C759), () => _push(context, const StudyLocationScreen())),
                        _div(),
                        _item(context, 'Export Data', Icons.square_foot_rounded, const Color(0xFF5AC8FA), () => _push(context, const DataExportScreen())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 3. PREFERENCES SECTION ──
                  _groupLabel('PREFERENCES'),
                  Card(
                    child: Consumer<ThemeProvider>(
                      builder: (ctx, tp, _) => SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                        secondary: _ib(Icons.dark_mode_rounded, const Color(0xFF5856D6)),
                        title: const Text('Dark Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        value: tp.isDarkMode,
                        onChanged: (v) {
                          tp.toggleDarkMode(v);
                          context.read<UserProvider>().setDarkMode(v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 4. INFO SECTION ──
                  _groupLabel('INFO'),
                  Card(
                    child: Column(
                      children: [
                        _item(context, 'About', Icons.info_outline_rounded, Colors.grey, () => _push(context, const AboutScreen())),
                        _div(),
                        // Sign Out button
                        InkWell(
                          onTap: () => _logout(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            child: Row(
                              children: [
                                _ib(Icons.logout_rounded, Colors.grey[700]!),
                                const SizedBox(width: 14),
                                Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 5. DANGER ZONE ──
                  _groupLabel('DANGER ZONE'),
                  Card(
                    color: Colors.red.withAlpha(10), // 给出淡淡的红色警告背景
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.red.withAlpha(50), width: 1),
                    ),
                    child: InkWell(
                      onTap: () => _deleteAccount(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            _ib(Icons.delete_forever_rounded, Colors.red),
                            const SizedBox(width: 14),
                            const Text('Delete Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // ── UI Helper Methods ──
  // ══════════════════════════════════════

  void _push(BuildContext c, Widget s) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => s));
  }

  Widget _groupLabel(String t) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: t == 'DANGER ZONE' ? Colors.red.withAlpha(200) : Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _item(BuildContext c, String t, IconData ic, Color col, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            _ib(ic, col),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                t,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  Widget _ib(IconData ic, Color c) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: c.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(ic, size: 18, color: c),
    );
  }

  Widget _div() {
    return Divider(
      height: 0.5,
      indent: 64,
      color: Colors.grey.withAlpha(30),
    );
  }
}