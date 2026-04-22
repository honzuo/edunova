/// settings_screen.dart — App settings and navigation hub.
///
/// Organized into sections:
/// - Account: Profile, Reminders
/// - Features: Achievements, Goals, Subjects, Export
/// - Preferences: Dark Mode toggle
/// - Info: About, Sign Out

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import 'profile_screen.dart';
import 'reminder_screen.dart';
import 'data_export_screen.dart';
import 'about_screen.dart';
import '../achievements/achievements_screen.dart';
import '../goals/goal_screen.dart';
import '../auth/login_screen.dart';
import 'subject_screen.dart';
import '../location/study_location_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Sign Out'), content: const Text('Are you sure?'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red)))]));
    if (confirm == true) { await AuthService().logout();
      if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: CustomScrollView(slivers: [
      const SliverAppBar(floating: true, snap: true, title: Text('Settings')),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8), _groupLabel('ACCOUNT'),
          Card(child: Column(children: [
            _item(context, 'Profile', Icons.person_rounded, const Color(0xFF5856D6), () => _push(context, const ProfileScreen())),
            _div(), _item(context, 'Reminders', Icons.notifications_rounded, const Color(0xFFFF3B30), () => _push(context, const ReminderScreen()))])),
          const SizedBox(height: 28), _groupLabel('FEATURES'),
          Card(child: Column(children: [
            _item(context, 'Achievements', Icons.emoji_events_rounded, const Color(0xFFFF9500), () => _push(context, const AchievementsScreen())),
            _div(), _item(context, 'Study Goals', Icons.flag_rounded, const Color(0xFF34C759), () => _push(context, const GoalScreen())),
            _div(), _item(context, 'Subjects', Icons.book_rounded, const Color(0xFFAF52DE), () => _push(context, const SubjectScreen())),
            _div(), _item(context, 'Study Locations', Icons.location_on_rounded, const Color(0xFF34C759), () => _push(context, const StudyLocationScreen())),
            _div(), _item(context, 'Export Data', Icons.square_foot_rounded, const Color(0xFF5AC8FA), () => _push(context, const DataExportScreen()))])),
          const SizedBox(height: 28), _groupLabel('PREFERENCES'),
          Card(child: Consumer<ThemeProvider>(builder: (ctx, tp, _) => SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            secondary: _ib(Icons.dark_mode_rounded, const Color(0xFF5856D6)),
            title: const Text('Dark Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            value: tp.isDarkMode, onChanged: (v) { tp.toggleDarkMode(v); context.read<UserProvider>().setDarkMode(v); }))),
          const SizedBox(height: 28), _groupLabel('INFO'),
          Card(child: Column(children: [
            _item(context, 'About', Icons.info_outline_rounded, Colors.grey, () => _push(context, const AboutScreen())),
            _div(), InkWell(onTap: () => _logout(context), borderRadius: BorderRadius.circular(16),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(children: [_ib(Icons.logout_rounded, Colors.red), const SizedBox(width: 14),
                  const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red))])))])),
          const SizedBox(height: 40)])))]),
    );
  }
  void _push(BuildContext c, Widget s) => Navigator.push(c, MaterialPageRoute(builder: (_) => s));
  Widget _groupLabel(String t) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)));
  Widget _item(BuildContext c, String t, IconData ic, Color col, VoidCallback onTap) => InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(children: [_ib(ic, col), const SizedBox(width: 14), Expanded(child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))), Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22)])));
  Widget _ib(IconData ic, Color c) => Container(width: 32, height: 32, decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Icon(ic, size: 18, color: c));
  Widget _div() => Divider(height: 0.5, indent: 64, color: Colors.grey.withAlpha(30));
}
