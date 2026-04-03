import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/study_task.dart';
import '../../providers/task_provider.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TaskProvider>().loadTasks();
    });
  }

  Future<void> _showEditDialog(StudyTask task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController =
    TextEditingController(text: task.description);
    final subjectController = TextEditingController(text: task.subject);
    final priorityController = TextEditingController(text: task.priority);

    DateTime selectedDeadline = task.deadline;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(labelText: 'Priority'),
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
                final updated = task.copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                  subject: subjectController.text,
                  priority: priorityController.text,
                  deadline: selectedDeadline,
                );

                await context.read<TaskProvider>().updateTask(updated);

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

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final subjectController = TextEditingController();
    final priorityController = TextEditingController(text: 'Medium');

    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 1));

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(labelText: 'Priority'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Deadline: '),
                    Expanded(
                      child: Text(
                        '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDeadline = picked;
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showAddTaskDialogWithValues(
                              titleController.text,
                              descriptionController.text,
                              subjectController.text,
                              priorityController.text,
                              selectedDeadline,
                            );
                          }
                        }
                      },
                    ),
                  ],
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

                await context.read<TaskProvider>().addTask(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  subject: subjectController.text.trim(),
                  deadline: selectedDeadline,
                  priority: priorityController.text.trim().isEmpty
                      ? 'Medium'
                      : priorityController.text.trim(),
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

  Future<void> _showAddTaskDialogWithValues(
      String title,
      String description,
      String subject,
      String priority,
      DateTime deadline,
      ) async {
    final titleController = TextEditingController(text: title);
    final descriptionController = TextEditingController(text: description);
    final subjectController = TextEditingController(text: subject);
    final priorityController = TextEditingController(text: priority);

    DateTime selectedDeadline = deadline;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(labelText: 'Priority'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Deadline: '),
                    Expanded(
                      child: Text(
                        '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                      ),
                    ),
                  ],
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

                await context.read<TaskProvider>().addTask(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  subject: subjectController.text.trim(),
                  deadline: selectedDeadline,
                  priority: priorityController.text.trim().isEmpty
                      ? 'Medium'
                      : priorityController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Tasks'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: provider.filter == TaskFilter.all,
                  onSelected: (_) {
                    context.read<TaskProvider>().setFilter(TaskFilter.all);
                  },
                ),
                ChoiceChip(
                  label: const Text('Completed'),
                  selected: provider.filter == TaskFilter.completed,
                  onSelected: (_) {
                    context.read<TaskProvider>().setFilter(TaskFilter.completed);
                  },
                ),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: provider.filter == TaskFilter.pending,
                  onSelected: (_) {
                    context.read<TaskProvider>().setFilter(TaskFilter.pending);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks yet'))
                : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (_) {
                        context.read<TaskProvider>().toggleComplete(task);
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      '${task.subject} | ${task.priority}\nDeadline: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditDialog(task);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Task'),
                                    content: const Text('Are you sure you want to delete this task?'),
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

                              if (confirm == true && task.id != null) {
                                context.read<TaskProvider>().removeTask(task.id!);
                              }
                            }
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}