/// about_screen.dart — App information and SDG #4 alignment.
///
/// Displays app name, version, key features, and explains how
/// EduNova supports UN Sustainable Development Goal #4
/// (Quality Education) through its study management tools.

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 20),

          // ── App Icon ──
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withAlpha(20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.school_rounded,
                size: 40, color: Color(0xFF0A84FF)),
          ),
          const SizedBox(height: 16),
          const Text('EduNova',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8)),
          const SizedBox(height: 4),
          Text('Version 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 20),
          Text(
            'A study management app designed to help students stay '
            'organized, focused, and motivated.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 28),

          // ═══════════════════════════════════════
          // ── SDG #4: Quality Education ──
          // ═══════════════════════════════════════
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC5192D), Color(0xFFE8432E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('4',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UN Sustainable Development Goal',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        Text('Quality Education',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                const Text(
                  'EduNova supports SDG #4 by empowering students with '
                  'tools to manage their study habits effectively. Through '
                  'task planning, focused study sessions, progress tracking, '
                  'and GPA management, the app promotes productive and '
                  'organized learning for all students.',
                  style: TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ═══════════════════════════════════════
          // ── Key Features ──
          // ═══════════════════════════════════════
          Card(
            child: Column(children: [
              _feature(Icons.checklist_rounded, 'Task Management',
                  'Organize by subject & priority', const Color(0xFF5856D6)),
              _div(),
              _feature(Icons.timer_rounded, 'Pomodoro Timer',
                  'Stay focused with timed sessions', const Color(0xFFFF9500)),
              _div(),
              _feature(
                  Icons.calculate_rounded,
                  'CGPA Calculator',
                  'Track academic performance by semester',
                  const Color(0xFF0A84FF)),
              _div(),
              _feature(
                  Icons.emoji_events_rounded,
                  'Achievements',
                  'Earn badges as you study',
                  const Color(0xFFFF3B30)),
              _div(),
              _feature(
                  Icons.insights_rounded,
                  'Progress Tracking',
                  'Heatmap, charts & detailed reports',
                  const Color(0xFF34C759)),
              _div(),
              _feature(
                  Icons.notifications_rounded,
                  'Smart Reminders',
                  'Never miss a deadline',
                  const Color(0xFFAF52DE)),
              _div(),
              _feature(Icons.cloud_sync_rounded, 'Cloud Sync',
                  'Data backed up to Supabase', const Color(0xFF5AC8FA)),
            ]),
          ),
          const SizedBox(height: 28),

          // ── Credits ──
          Text(
            'BMIT2073 Mobile Application Development\n'
            'Academic Session 202601',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  /// Feature list tile with icon, title, and subtitle.
  static Widget _feature(
      IconData icon, String title, String sub, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: c),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          Text(sub,
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
      ]),
    );
  }

  /// Divider between feature items.
  static Widget _div() =>
      Divider(height: 0.5, indent: 68, color: Colors.grey.withAlpha(30));
}
