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

  List<Map<String, String>> _getEventsForDay(
      DateTime day,
      List tasks,
      List sessions,
      ) {
    final events = <Map<String, String>>[];

    for (final task in tasks) {
      final d = task.deadline;
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        events.add({
          'type': 'task',
          'title': task.title,
          'subtitle': 'Task deadline | ${task.subject}',
        });
      }
    }

    for (final session in sessions) {
      final d = session.startTime;
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        events.add({
          'type': 'session',
          'title': session.title,
          'subtitle':
          'Study session | ${session.subject} | ${session.durationMinutes} min',
        });
      }
    }

    return events;
  }

  Future<void> _showAddSessionDialog() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = _selectedDay;
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(
      hour: (TimeOfDay.now().hour + 1) % 24,
      minute: TimeOfDay.now().minute,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Study Session'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                ),
                ListTile(
                  title: Text('Start: ${startTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (picked != null) {
                      startTime = picked;
                    }
                  },
                ),
                ListTile(
                  title: Text('End: ${endTime.format(context)}'),
                  trailing: const Icon(Icons.access_time_filled),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (picked != null) {
                      endTime = picked;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;

                final startDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  startTime.hour,
                  startTime.minute,
                );

                final endDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  endTime.hour,
                  endTime.minute,
                );

                if (!endDateTime.isAfter(startDateTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('End time must be after start time'),
                    ),
                  );
                  return;
                }

                await context.read<SessionProvider>().addSession(
                  title: titleController.text.trim(),
                  subject: subjectController.text.trim(),
                  startTime: startDateTime,
                  endTime: endDateTime,
                  notes: notesController.text.trim(),
                );

                if (context.mounted) {
                  await context.read<SessionProvider>().loadSessions();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final sessions = context.watch<SessionProvider>().sessions;

    final events = _getEventsForDay(_selectedDay, tasks, sessions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Events on ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: events.isEmpty
                ? const Center(child: Text('No events'))
                : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(
                      event['type'] == 'task'
                          ? Icons.task_alt
                          : Icons.menu_book,
                    ),
                    title: Text(event['title'] ?? ''),
                    subtitle: Text(event['subtitle'] ?? ''),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSessionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}