import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalProvider>().goals;

    return Scaffold(
      body: CustomScrollView(slivers: [
        const SliverAppBar(floating: true, snap: true, title: Text('Study Goals')),
        if (goals.isEmpty)
          const SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.flag_rounded, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No goals yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ])))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final g = goals[i];
                return Card(child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(g.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
                      if (g.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF34C759).withAlpha(20), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF34C759))),
                        )
                      else
                        IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey), onPressed: () {
                          if (g.id != null) context.read<GoalProvider>().removeGoal(g.id!);
                        }),
                    ]),
                    const SizedBox(height: 4),
                    Text(_label(g.goalType), style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: g.progress, minHeight: 8,
                          backgroundColor: Colors.grey.withAlpha(30), color: const Color(0xFF0A84FF)),
                    ),
                    const SizedBox(height: 6),
                    Text('${g.currentValue} / ${g.targetValue}', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                  ]),
                ));
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addGoal(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _label(String t) => const {
    'weekly_hours': 'Weekly Study Hours', 'monthly_hours': 'Monthly Study Hours',
    'daily_tasks': 'Daily Completed Tasks', 'streak': 'Study Streak (Days)',
  }[t] ?? t;

  void _addGoal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String type = 'weekly_hours';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft, child: Text('New Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Goal title')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(value: type,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            items: const [
              DropdownMenuItem(value: 'weekly_hours', child: Text('Weekly Study Hours')),
              DropdownMenuItem(value: 'monthly_hours', child: Text('Monthly Study Hours')),
              DropdownMenuItem(value: 'daily_tasks', child: Text('Daily Tasks')),
              DropdownMenuItem(value: 'streak', child: Text('Study Streak')),
            ], onChanged: (v) => setSt(() => type = v!)),
          const SizedBox(height: 10),
          TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Target value')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {
            final t = titleCtrl.text.trim();
            final v = int.tryParse(targetCtrl.text.trim()) ?? 0;
            if (t.isEmpty || v <= 0) return;
            final now = DateTime.now();
            context.read<GoalProvider>().addGoal(title: t, goalType: type, targetValue: v,
                startDate: now, endDate: type.contains('weekly') ? now.add(const Duration(days: 7)) : now.add(const Duration(days: 30)));
            Navigator.pop(ctx);
          }, child: const Text('Create Goal')),
        ]),
      )),
    );
  }
}
