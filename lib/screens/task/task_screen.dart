/// task_screen.dart — Task management screen with date-based view.
///
/// Features:
/// - Horizontal date selector strip (30 days)
/// - Filter chips (All / Done / Pending)
/// - Task cards with priority colors and swipe-to-delete
/// - Add/edit task bottom sheet with subject/priority/deadline
/// - Quick-launch Pomodoro timer for any task
/// - Upcoming tasks section for today's view

import '../../constants/subjects.dart';
import '../../models/subject.dart';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/study_task.dart';
import '../../providers/task_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/database_service.dart';
import '../home/pomodoro_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  DateTime _selectedDate = DateTime.now();
  late final PageController _datePageCtrl;
  List<Subject> _subjectList = [];

  // We show 14 days: 7 past + today + 6 future
  static const _daysBefore = 7;
  static const _totalDays = 30;

  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(_totalDays, (i) {
      return DateTime(today.year, today.month, today.day - _daysBefore + i);
    });
    _datePageCtrl = PageController(initialPage: _daysBefore);
    Future.microtask(() => context.read<TaskProvider>().loadTasks());
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    await SubjectService().load();
    if (mounted) setState(() => _subjectList = SubjectService().subjects);
  }

  List<String> get _subjectNames => _subjectList.map((s) => s.name).toList();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<StudyTask> _tasksForDate(List<StudyTask> all, DateTime date) {
    return all.where((t) => _isSameDay(t.deadline, date)).toList();
  }

  String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return const Color(0xFFFF3B30);
      case 'medium': return const Color(0xFFFF9500);
      default: return const Color(0xFF34C759);
    }
  }

  // ── Complete Task with Photo Proof (Camera Access) ──
  Future<void> _completeTaskWithPhoto(dynamic task) async {
    final wantPhoto = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Task Completed!'),
        content: const Text('Do you want to capture a photo of your work as proof?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Take Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5856D6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (wantPhoto != true) {
      context.read<TaskProvider>().toggleComplete(task);
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        if (!mounted) return;
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading proof... Please wait.')),
        );

        try {
          await DatabaseService().uploadProofAndUpdateTask(File(photo.path), task.id);
        } catch (e) {
          debugPrint('Upload Error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
          return;
        }

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🏆 Awesome Work!', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<TaskProvider>().loadTasks();
                },
                child: const Text('Done', style: TextStyle(color: Color(0xFF5856D6), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open camera.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final allTasks = provider.filteredTasks;
    final dayTasks = _tasksForDate(allTasks, _selectedDate);
    final cs = Theme.of(context).colorScheme;
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    // Count tasks per date for dots
    final Map<String, int> taskCounts = {};
    for (final t in allTasks) {
      final key = '${t.deadline.year}-${t.deadline.month}-${t.deadline.day}';
      taskCounts[key] = (taskCounts[key] ?? 0) + 1;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, snap: true,
            title: Text('${_monthName(_selectedDate.month)} ${_selectedDate.year}'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => _selectedDate = DateTime.now());
                },
                child: const Text('Today'),
              ),
            ],
          ),

          // ── Filter Chips ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(children: [
                _filterChip('All', TaskFilter.all, provider),
                const SizedBox(width: 8),
                _filterChip('Done', TaskFilter.completed, provider),
                const SizedBox(width: 8),
                _filterChip('Pending', TaskFilter.pending, provider),
              ]),
            ),
          ),

          // ── Date Selector Strip ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 82,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dates.length,
                itemBuilder: (context, i) {
                  final date = _dates[i];
                  final selected = _isSameDay(date, _selectedDate);
                  final today = _isSameDay(date, DateTime.now());
                  final key = '${date.year}-${date.month}-${date.day}';
                  final count = taskCounts[key] ?? 0;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDate = date);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary
                            : today
                            ? cs.primary.withAlpha(15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: today && !selected
                            ? Border.all(color: cs.primary.withAlpha(50), width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekdayShort(date.weekday),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (count > 0)
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? Colors.white70 : cs.primary,
                              ),
                            )
                          else
                            const SizedBox(width: 6, height: 6),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Date Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                Text(
                  isToday
                      ? 'Today'
                      : '${_selectedDate.day} ${_monthName(_selectedDate.month)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${dayTasks.length}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
                  ),
                ),
              ]),
            ),
          ),

          // ── Task List ──
          if (dayTasks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      isToday ? 'No tasks for today' : 'No tasks on this day',
                      style: TextStyle(color: Colors.grey[400], fontSize: 15),
                    ),
                  ],
                )),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: dayTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _taskCard(dayTasks[i]),
              ),
            ),

          // ── Upcoming Section ──
          if (isToday && allTasks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Text('Upcoming',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: _upcomingTasks(allTasks).length.clamp(0, 5),
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final task = _upcomingTasks(allTasks)[i];
                  return _compactTaskRow(task);
                },
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "fab_task",
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (ctx) => AddTaskBottomSheet(selectedDate: _selectedDate),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  List<StudyTask> _upcomingTasks(List<StudyTask> all) {
    final today = DateTime.now();
    return all
        .where((t) => t.deadline.isAfter(DateTime(today.year, today.month, today.day)) && !t.isCompleted)
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  Widget _compactTaskRow(StudyTask task) {
    final daysLeft = task.deadline.difference(DateTime.now()).inDays;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 4, height: 32,
            decoration: BoxDecoration(
              color: _priorityColor(task.priority),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(task.subject, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: daysLeft <= 1 ? const Color(0xFFFF3B30).withAlpha(15) : Colors.grey.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysLeft == 0 ? 'Tomorrow' : 'In $daysLeft days',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: daysLeft <= 1 ? const Color(0xFFFF3B30) : Colors.grey[600],
              ),
            ),
          ),
        ]),
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
    final studyMinutes = task.id != null
        ? context.watch<SessionProvider>().minutesForTask(task.id!)
        : 0;

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
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).cardTheme.color,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (ctx) => EditTaskBottomSheet(task: task),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  if (!task.isCompleted) {
                    _completeTaskWithPhoto(task);
                  } else {
                    context.read<TaskProvider>().toggleComplete(task);
                  }
                },
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
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _priorityColor(task.priority).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(task.priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _priorityColor(task.priority))),
                    ),
                    if (task.subject.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.book_outlined, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(task.subject, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                    if (studyMinutes > 0) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text('${studyMinutes}m', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ]),
                ]),
              ),
              // Study button
              if (!task.isCompleted)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => PomodoroScreen(initialTask: task)));
                  },
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 20, color: Color(0xFFFF9500)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class AddTaskBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  const AddTaskBottomSheet({super.key, required this.selectedDate});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedSubject = '';
  String _priority = 'Medium';
  late DateTime _deadline;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _deadline = widget.selectedDate;
    final subs = SubjectService().names;
    if (subs.isNotEmpty) {
      _selectedSubject = subs.first;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    if (_isListening) _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subs = SubjectService().names;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft,
                child: Text('New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'Title (e.g., Do Math Homework)',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _isListening ? const Color(0xFFFF3B30) : const Color(0xFF5856D6),
                  ),
                  tooltip: 'Tap to speak',
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (!_isListening) {
                      bool available = await _speech.initialize(
                        onStatus: (val) {
                          if (val == 'done' || val == 'notListening') {
                            if (mounted) setState(() => _isListening = false);
                          }
                        },
                        onError: (val) => debugPrint('onError: $val'),
                      );
                      if (available) {
                        setState(() => _isListening = true);
                        _speech.listen(
                          onResult: (val) => setState(() {
                            _titleCtrl.text = val.recognizedWords;
                          }),
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Speech recognition not available on this device.')),
                          );
                        }
                      }
                    } else {
                      setState(() => _isListening = false);
                      _speech.stop();
                    }
                  },
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),

            const SizedBox(height: 10),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(hintText: 'Description')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: subs.contains(_selectedSubject) ? _selectedSubject : (subs.isNotEmpty ? subs.first : null),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              items: subs.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _selectedSubject = v ?? ''),
              validator: (v) => (v == null || v.isEmpty) ? 'Please select a subject' : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _priority = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _deadline, firstDate: DateTime(2024), lastDate: DateTime(2100));
                    if (d != null) setState(() => _deadline = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text('${_deadline.day}/${_deadline.month}/${_deadline.year}',
                          style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                context.read<TaskProvider>().addTask(
                  title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(),
                  subject: _selectedSubject, deadline: _deadline, priority: _priority,
                );
                Navigator.pop(context);
              },
              child: const Text('Add Task'),
            ),
          ]),
        ),
      ),
    );
  }
}

class EditTaskBottomSheet extends StatefulWidget {
  final StudyTask task;
  const EditTaskBottomSheet({super.key, required this.task});

  @override
  State<EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends State<EditTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  String _selectedSubject = '';
  String _priority = 'Medium';
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
    _deadline = widget.task.deadline;

    final subs = SubjectService().names;
    if (widget.task.subject.isNotEmpty && subs.contains(widget.task.subject)) {
      _selectedSubject = widget.task.subject;
    } else if (subs.isNotEmpty) {
      _selectedSubject = subs.first;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subs = SubjectService().names;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft,
                child: Text('Edit Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(hintText: 'Description')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: subs.contains(_selectedSubject) ? _selectedSubject : (subs.isNotEmpty ? subs.first : null),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              items: subs.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _selectedSubject = v ?? ''),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _priority = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _deadline, firstDate: DateTime(2024), lastDate: DateTime(2100));
                    if (d != null) setState(() => _deadline = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text('${_deadline.day}/${_deadline.month}/${_deadline.year}',
                          style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                context.read<TaskProvider>().updateTask(widget.task.copyWith(
                  title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(),
                  subject: _selectedSubject, priority: _priority, deadline: _deadline,
                ));
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ]),
        ),
      ),
    );
  }
}