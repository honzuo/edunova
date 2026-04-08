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
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withAlpha(20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.school_rounded, size: 40, color: Color(0xFF0A84FF)),
          ),
          const SizedBox(height: 16),
          const Text('EduNova', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
          const SizedBox(height: 4),
          Text('Version 1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 20),
          Text('A study management app designed to help students stay organized, focused, and motivated.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5)),
          const SizedBox(height: 32),
          Card(child: Column(children: [
            _feature(Icons.checklist_rounded, 'Task Management', 'Organize by subject & priority', const Color(0xFF5856D6)),
            _div(),
            _feature(Icons.timer_rounded, 'Pomodoro Timer', 'Stay focused with timed sessions', const Color(0xFFFF9500)),
            _div(),
            _feature(Icons.emoji_events_rounded, 'Achievements', 'Earn badges as you study', const Color(0xFFFF3B30)),
            _div(),
            _feature(Icons.insights_rounded, 'Progress Tracking', 'Heatmap, charts & reports', const Color(0xFF34C759)),
          ])),
        ]),
      ),
    );
  }

  static Widget _feature(IconData icon, String title, String sub, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: c.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: c),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(sub, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
      ]),
    );
  }

  static Widget _div() => Divider(height: 0.5, indent: 68, color: Colors.grey.withAlpha(30));
}
