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
    Future.microtask(() => context.read<TaskProvider>().loadTasks());
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return const Color(0xFFFF3B30);
      case 'medium': return const Color(0xFFFF9500);
      default: return const Color(0xFF34C759);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.filteredTasks;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, snap: true, title: Text('Tasks')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(children: [
                _filterChip('All', TaskFilter.all, provider),
                const SizedBox(width: 8),
                _filterChip('Done', TaskFilter.completed, provider),
                const SizedBox(width: 8),
                _filterChip('Pending', TaskFilter.pending, provider),
              ]),
            ),
          ),
          if (tasks.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_rounded, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No tasks yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              )),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _taskCard(tasks[i]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _filterChip(String label, TaskFilter filter, TaskProvider provider) {
    final selected = provider.filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => provider.setFilter(filter),
      showCheckmark: false,
    );
  }

  Widget _taskCard(StudyTask task) {
    return Card(
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Delete Task?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ));
        },
        onDismissed: (_) { if (task.id != null) context.read<TaskProvider>().removeTask(task.id!); },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditSheet(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.read<TaskProvider>().toggleComplete(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? const Color(0xFF34C759) : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted ? const Color(0xFF34C759) : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(task.title, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey : null,
                  )),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _priorityColor(task.priority).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(task.priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _priorityColor(task.priority))),
                    ),
                    const SizedBox(width: 8),
                    Text(task.subject, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const Spacer(),
                    Text('${task.deadline.day}/${task.deadline.month}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    String priority = 'Medium';
    DateTime deadline = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft,
              child: Text('New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description')),
          const SizedBox(height: 10),
          TextField(controller: subjectCtrl, decoration: const InputDecoration(hintText: 'Subject')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setSt(() => priority = v!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: deadline, firstDate: DateTime(2024), lastDate: DateTime(2100));
                  if (d != null) setSt(() => deadline = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text('${deadline.day}/${deadline.month}/${deadline.year}',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              context.read<TaskProvider>().addTask(
                title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
                subject: subjectCtrl.text.trim(), deadline: deadline, priority: priority,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Add Task'),
          ),
        ]),
      )),
    );
  }

  void _showEditSheet(StudyTask task) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);
    final subjectCtrl = TextEditingController(text: task.subject);
    String priority = task.priority;
    DateTime deadline = task.deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft,
              child: Text('Edit Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description')),
          const SizedBox(height: 10),
          TextField(controller: subjectCtrl, decoration: const InputDecoration(hintText: 'Subject')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: priority,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setSt(() => priority = v!),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<TaskProvider>().updateTask(task.copyWith(
                title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
                subject: subjectCtrl.text.trim(), priority: priority, deadline: deadline,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          ),
        ]),
      )),
    );
  }
}
