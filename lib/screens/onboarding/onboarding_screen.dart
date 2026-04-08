import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _P(Icons.school_rounded, 'Welcome to\nEduNova', 'Your smart study companion to stay organized and productive.', Color(0xFF0A84FF)),
    _P(Icons.checklist_rounded, 'Manage\nTasks', 'Create tasks with deadlines, priorities, and subjects. Track progress effortlessly.', Color(0xFF5856D6)),
    _P(Icons.timer_rounded, 'Pomodoro\nTimer', 'Stay focused with the built-in pomodoro timer and ambient sounds.', Color(0xFFFF9500)),
    _P(Icons.emoji_events_rounded, 'Achievements\n& Goals', 'Earn badges, set study goals, and track your learning streaks.', Color(0xFF34C759)),
    _P(Icons.insights_rounded, 'Track Your\nProgress', 'View heatmaps, charts, and detailed reports of your study habits.', Color(0xFFFF3B30)),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(color: p.color.withAlpha(20), borderRadius: BorderRadius.circular(32)),
                      child: Icon(p.icon, size: 56, color: p.color),
                    ),
                    const SizedBox(height: 40),
                    Text(p.title, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1, height: 1.1)),
                    const SizedBox(height: 16),
                    Text(p.subtitle, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[500], height: 1.4)),
                  ]),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _page == i ? 24 : 8, height: 8,
              decoration: BoxDecoration(
                color: _page == i ? _pages[i].color : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(onPressed: _finish, child: Text('Skip', style: TextStyle(color: Colors.grey[500]))),
              ElevatedButton(
                onPressed: () {
                  if (_page == _pages.length - 1) { _finish(); }
                  else { _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(140, 50)),
                child: Text(_page == _pages.length - 1 ? 'Get Started' : 'Next'),
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _P {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _P(this.icon, this.title, this.subtitle, this.color);
}
