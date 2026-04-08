import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/reminder_provider.dart';
import '../../providers/task_provider.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});
  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ReminderProvider>().loadReminders();
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>().reminders;
    final tasks = context.watch<TaskProvider>().tasks;

    String taskTitle(int id) {
      try { return tasks.firstWhere((t) => t.id == id).title; }
      catch (_) { return 'Unknown'; }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, snap: true, title: Text('Reminders')),
          if (reminders.isEmpty)
            const SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_off_rounded, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text('No reminders', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ])))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: reminders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = reminders[i];
                  final time = r.triggerTime;
                  return Dismissible(
                    key: ValueKey(r.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete_rounded, color: Colors.white),
                    ),
                    confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                      title: const Text('Delete Reminder?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    )),
                    onDismissed: (_) { if (r.id != null) context.read<ReminderProvider>().removeReminder(r.id!); },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30).withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_rounded, size: 22, color: Color(0xFFFF3B30)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(taskTitle(r.taskId), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A84FF).withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(r.reminderType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0A84FF))),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                              ),
                            ]),
                          ])),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addReminder(context, tasks),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _addReminder(BuildContext context, List tasks) {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a task first')));
      return;
    }

    int taskId = tasks.first.id!;
    String type = 'Custom';
    DateTime dt = DateTime.now().add(const Duration(hours: 1));

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft,
              child: Text('New Reminder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: taskId,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            items: tasks.where((t) => t.id != null).map<DropdownMenuItem<int>>((t) =>
                DropdownMenuItem(value: t.id!, child: Text(t.title))).toList(),
            onChanged: (v) { if (v != null) setSt(() => taskId = v); },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            items: ['Custom', '1 hour before', '1 day before']
                .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) { if (v != null) setSt(() => type = v); },
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: dt, firstDate: DateTime.now(), lastDate: DateTime(2100));
              if (d == null) return;
              final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(dt));
              if (t == null) return;
              setSt(() => dt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(ctx).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text('${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600])),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<ReminderProvider>().addReminder(taskId: taskId, reminderType: type, triggerTime: dt);
              Navigator.pop(ctx);
            },
            child: const Text('Save Reminder'),
          ),
        ]),
      )),
    );
  }
}
