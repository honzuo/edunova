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

  Future<void> _showAddReminderDialog() async {
    final tasks = context.read<TaskProvider>().tasks;

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a task first')),
      );
      return;
    }

    int selectedTaskId = tasks.first.id!;
    String selectedType = 'Custom';
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reminder'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedTaskId,
                      items: tasks
                          .where((task) => task.id != null)
                          .map(
                            (task) => DropdownMenuItem<int>(
                          value: task.id!,
                          child: Text(task.title),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedTaskId = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Task'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: const [
                        DropdownMenuItem(
                          value: 'Custom',
                          child: Text('Custom'),
                        ),
                        DropdownMenuItem(
                          value: '1 hour before',
                          child: Text('1 hour before'),
                        ),
                        DropdownMenuItem(
                          value: '1 day before',
                          child: Text('1 day before'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                      decoration:
                      const InputDecoration(labelText: 'Reminder Type'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        'Trigger: '
                            '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} '
                            '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate == null) return;

                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime == null) return;

                        setDialogState(() {
                          selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<ReminderProvider>().addReminder(
                  taskId: selectedTaskId,
                  reminderType: selectedType,
                  triggerTime: selectedDateTime,
                );

                if (context.mounted) {
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

  Future<void> _confirmDeleteReminder(int reminderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: const Text(
            'Are you sure you want to delete this reminder?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await context.read<ReminderProvider>().removeReminder(reminderId);
      await context.read<ReminderProvider>().loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>().reminders;
    final tasks = context.watch<TaskProvider>().tasks;

    String taskTitleById(int taskId) {
      try {
        final task = tasks.firstWhere((t) => t.id == taskId);
        return task.title;
      } catch (_) {
        return 'Unknown Task';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: reminders.isEmpty
          ? const Center(child: Text('No reminders yet'))
          : ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(taskTitleById(reminder.taskId)),
              subtitle: Text(
                '${reminder.reminderType}\n'
                    '${reminder.triggerTime.day}/${reminder.triggerTime.month}/${reminder.triggerTime.year} '
                    '${reminder.triggerTime.hour.toString().padLeft(2, '0')}:${reminder.triggerTime.minute.toString().padLeft(2, '0')}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  if (reminder.id != null) {
                    _confirmDeleteReminder(reminder.id!);
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        child: const Icon(Icons.add_alert),
      ),
    );
  }
}