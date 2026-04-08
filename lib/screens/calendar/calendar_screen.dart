import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/session_provider.dart';
import '../../providers/task_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<TaskProvider>().loadTasks();
      await context.read<SessionProvider>().loadSessions();
    });
  }

  List<Map<String, String>> _eventsFor(DateTime day, List tasks, List sessions) {
    final events = <Map<String, String>>[];
    for (final task in tasks) {
      final d = task.deadline;
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        events.add({'type': 'task', 'title': task.title, 'subtitle': '${task.subject} · ${task.priority}'});
      }
    }
    for (final s in sessions) {
      final d = s.startTime;
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        events.add({'type': 'session', 'title': s.title, 'subtitle': '${s.subject} · ${s.durationMinutes} min'});
      }
    }
    return events;
  }

  bool _hasEvents(DateTime day, List tasks, List sessions) {
    for (final task in tasks) {
      final d = task.deadline;
      if (d.year == day.year && d.month == day.month && d.day == day.day) return true;
    }
    for (final s in sessions) {
      final d = s.startTime;
      if (d.year == day.year && d.month == day.month && d.day == day.day) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final sessions = context.watch<SessionProvider>().sessions;
    final events = _eventsFor(_selectedDay, tasks, sessions);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, snap: true, title: Text('Calendar')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (sel, foc) => setState(() { _selectedDay = sel; _focusedDay = foc; }),
                    calendarFormat: CalendarFormat.month,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded, color: cs.primary),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded, color: cs.primary),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                      weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(color: cs.primary.withAlpha(30), shape: BoxShape.circle),
                      todayTextStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
                      selectedDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                      selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      outsideDaysVisible: false,
                      defaultTextStyle: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black),
                      weekendTextStyle: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (ctx, day, _) {
                        if (_hasEvents(day, tasks, sessions)) {
                          return Positioned(
                            bottom: 4,
                            child: Container(
                              width: 5, height: 5,
                              decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Events · ${_selectedDay.day}/${_selectedDay.month}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
            ),
          ),
          if (events.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event_available_rounded, size: 44, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('No events', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                ])),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final e = events[i];
                  final isTask = e['type'] == 'task';
                  return Dismissible(
                    key: ValueKey('${e['title']}_$i'),
                    direction: isTask ? DismissDirection.none : DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete_rounded, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                        title: const Text('Delete Session?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ));
                    },
                    onDismissed: (_) {
                      final session = sessions.firstWhere((s) =>
                          s.title == e['title'] && s.startTime.year == _selectedDay.year &&
                          s.startTime.month == _selectedDay.month && s.startTime.day == _selectedDay.day);
                      if (session.id != null) context.read<SessionProvider>().removeSession(session.id!);
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: (isTask ? const Color(0xFF5856D6) : const Color(0xFFFF9500)).withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isTask ? Icons.checklist_rounded : Icons.timer_rounded,
                              size: 18,
                              color: isTask ? const Color(0xFF5856D6) : const Color(0xFFFF9500),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(e['subtitle'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
        heroTag: "fab_calendar",
        onPressed: () => _showAddSessionSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddSessionSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime date = _selectedDay;
    TimeOfDay start = TimeOfDay.now();
    TimeOfDay end = TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);

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
              child: Text('New Session', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: subjectCtrl, decoration: const InputDecoration(hintText: 'Subject')),
          const SizedBox(height: 10),
          TextField(controller: notesCtrl, decoration: const InputDecoration(hintText: 'Notes')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _timeTile(ctx, 'Start', start, (t) => setSt(() => start = t))),
            const SizedBox(width: 10),
            Expanded(child: _timeTile(ctx, 'End', end, (t) => setSt(() => end = t))),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final s = DateTime(date.year, date.month, date.day, start.hour, start.minute);
              final e = DateTime(date.year, date.month, date.day, end.hour, end.minute);
              if (!e.isAfter(s)) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('End must be after start')));
                return;
              }
              context.read<SessionProvider>().addSession(
                title: titleCtrl.text.trim(), subject: subjectCtrl.text.trim(),
                startTime: s, endTime: e, notes: notesCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save Session'),
          ),
        ]),
      )),
    );
  }

  Widget _timeTile(BuildContext ctx, String label, TimeOfDay time, void Function(TimeOfDay) onPick) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: ctx, initialTime: time);
        if (t != null) onPick(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(ctx).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ${time.format(ctx)}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ]),
      ),
    );
  }
}
