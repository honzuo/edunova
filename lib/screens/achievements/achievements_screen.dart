import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/achievement_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  IconData _icon(String n) {
    const m = {'star': Icons.star_rounded, 'task_alt': Icons.task_alt_rounded,
      'military_tech': Icons.military_tech_rounded, 'timer': Icons.timer_rounded,
      'psychology': Icons.psychology_rounded, 'emoji_events': Icons.emoji_events_rounded,
      'local_fire_department': Icons.local_fire_department_rounded, 'whatshot': Icons.whatshot_rounded,
      'diamond': Icons.diamond_rounded, 'school': Icons.school_rounded,
      'auto_stories': Icons.auto_stories_rounded, 'workspace_premium': Icons.workspace_premium_rounded};
    return m[n] ?? Icons.emoji_events_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AchievementProvider>();
    final all = p.achievements;
    final unlocked = p.unlocked.length;

    return Scaffold(
      body: CustomScrollView(slivers: [
        const SliverAppBar(floating: true, snap: true, title: Text('Achievements')),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Icon(Icons.emoji_events_rounded, size: 44, color: Colors.white),
              const SizedBox(height: 8),
              Text('$unlocked / ${all.length}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1)),
              const Text('Unlocked', style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('${p.currentStreak} day streak', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final a = all[i];
              return Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: (a.isUnlocked ? const Color(0xFFFF9500) : Colors.grey).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon(a.iconName), size: 24,
                        color: a.isUnlocked ? const Color(0xFFFF9500) : Colors.grey),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: a.isUnlocked ? null : Colors.grey)),
                    const SizedBox(height: 2),
                    Text(a.description, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: a.progress, minHeight: 4,
                        backgroundColor: Colors.grey.withAlpha(30),
                        color: a.isUnlocked ? const Color(0xFFFF9500) : const Color(0xFF0A84FF),
                      ),
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Text('${a.currentValue}/${a.targetValue}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                ]),
              ));
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }
}
