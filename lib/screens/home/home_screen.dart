/// home_screen.dart — The main dashboard of EduNova.
///
/// Displays the user's daily progress, CGPA, daily inspirational quote,
/// today's tasks, and a minimal navigation grid to all major tools.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/cgpa_record.dart';

import '../../providers/progress_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/user_provider.dart';

import '../search/search_screen.dart';
import '../achievements/achievements_screen.dart';
import '../goals/goal_screen.dart';
import '../tools/cgpa_calculator_screen.dart';
import '../location/study_location_screen.dart';
import 'pomodoro_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> _quote = {};
  double _currentCgpa = 0;
  bool _isLoading = true; // Controls the initial loading screen state

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // ── Data Initialization ──

  /// Initializes all required data concurrently and handles exceptions.
  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch daily inspirational quote from API
      _quote = await ApiService().getQuote();

      // 2. Load all Provider data concurrently for better performance
      await Future.wait([
        context.read<TaskProvider>().loadTasks(),
        context.read<SessionProvider>().loadSessions(),
        context.read<UserProvider>().loadUser(),
        context.read<AchievementProvider>().loadAchievements(),
        _loadCurrentCgpa(),
      ]);

      if (!mounted) return;

      // 3. Generate the latest progress report
      context.read<ProgressProvider>().generateReport(
        taskProvider: context.read<TaskProvider>(),
        sessionProvider: context.read<SessionProvider>(),
      );

      // 4. Evaluate and update achievements (includes Supabase queries)
      await _evaluateAchievements();

    } catch (e) {
      debugPrint("Home Data Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync data. Working in offline mode.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Calculates the current streak and checks for new achievements.
  Future<void> _evaluateAchievements() async {
    final ap = context.read<AchievementProvider>();
    final streak = await ap.calculateStreak();
    final tasks = context.read<TaskProvider>().tasks;
    final sessions = context.read<SessionProvider>().sessions;
    final uid = AuthService().currentUserId ?? 'demo-user';

    try {
      final pomData = await DatabaseService().getPomodorosByUser(uid);
      final pomCount = pomData.where((p) => p['completed'] == 1 || p['completed'] == true).length;

      await ap.evaluate(
        completedTasks: tasks.where((t) => t.isCompleted).length,
        pomodoroCount: pomCount,
        totalStudyMinutes: sessions.fold(0, (s, e) => s + e.durationMinutes),
        streak: streak,
      );
    } catch (e) {
      debugPrint("Achievement Evaluation Error: $e");
    }
  }

  /// Fetches local CGPA records and calculates the overall GPA.
  Future<void> _loadCurrentCgpa() async {
    final uid = AuthService().currentUserId ?? 'demo-user';
    final data = await DatabaseService().getCgpaRecordsByUser(uid);

    if (data.isEmpty) {
      setState(() => _currentCgpa = 0);
      return;
    }

    double totalPts = 0;
    int totalCr = 0;

    for (final m in data) {
      final r = CgpaRecord.fromMap(m);
      totalPts += r.gpa * r.totalCredits;
      totalCr += r.totalCredits;
    }

    setState(() {
      _currentCgpa = totalCr > 0 ? totalPts / totalCr : 0;
    });
  }

  // ── Main UI Build ──

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading EduNova...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final report = context.watch<ProgressProvider>().report;
    final totalH = (report.totalStudyMinutes / 60).toStringAsFixed(1);
    final todayTasks = context.watch<TaskProvider>().todayTasks;
    final todayMin = context.watch<SessionProvider>().todayStudyMinutes;
    final streak = context.watch<AchievementProvider>().currentStreak;
    final user = context.watch<UserProvider>().currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _initData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: const Text('EduNova'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Welcome Section & Streak Badge ──
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? 'Welcome, ${user!.fullName}'
                                : 'Welcome',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        _streakBadge(streak),
                      ],
                    ),

                    // ── 2. GPA Tracking Section ──
                    if (user != null) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Theme.of(context).cardTheme.color,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (ctx) => const EditGpaBottomSheet(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759).withAlpha(15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF34C759).withAlpha(50),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Target GPA',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                    Text(
                                      user.targetGpa.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF34C759),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.withAlpha(40),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current GPA',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                    Text(
                                      _currentCgpa > 0 ? _currentCgpa.toStringAsFixed(2) : '—',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: _currentCgpa >= user.targetGpa
                                            ? const Color(0xFF34C759)
                                            : const Color(0xFFFF9500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.edit_rounded, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── 3. Daily Inspiration Quote ──
                    if (_quote.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.format_quote_rounded, size: 20, color: cs.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Daily Inspiration',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _quote['quote'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '— ${_quote['author'] ?? ''}',
                                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── 4. Quick Stats Row ──
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _statCard(
                          'Tasks',
                          '${report.completedTasks + report.pendingTasks}',
                          Icons.checklist_rounded,
                          const Color(0xFF5856D6),
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          'Studied',
                          '${totalH}h',
                          Icons.timer_outlined,
                          const Color(0xFFFF9500),
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          'Done',
                          '${report.completionRate.toStringAsFixed(0)}%',
                          Icons.pie_chart_rounded,
                          const Color(0xFF34C759),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── 5. Today's Overview ──
                    _sectionTitle("Today's Overview"),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _iconBubble(Icons.access_time_rounded, const Color(0xFFFF9500)),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Study Time',
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                    Text(
                                      '$todayMin min',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (todayTasks.isNotEmpty) ...[
                              const Divider(height: 28),
                              ...todayTasks.take(3).map((t) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        t.isCompleted
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 20,
                                        color: t.isCompleted
                                            ? const Color(0xFF34C759)
                                            : Colors.grey[400],
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          t.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                                            color: t.isCompleted ? Colors.grey : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            if (todayTasks.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'No tasks for today',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 6. Minimal Tools Section ──
                    _sectionTitle('Tools'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // First Row of Tools
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _minimalToolTile(
                                'Pomodoro',
                                Icons.timer_rounded,
                                const Color(0xFFFF9500),
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PomodoroScreen())),
                              ),
                              _minimalToolTile(
                                'CGPA',
                                Icons.calculate_rounded,
                                const Color(0xFF5856D6),
                                    () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const CgpaCalculatorScreen()));
                                  _loadCurrentCgpa();
                                },
                              ),
                              _minimalToolTile(
                                'Goals',
                                Icons.flag_rounded,
                                const Color(0xFF34C759),
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalScreen())),
                              ),
                              _minimalToolTile(
                                'Badges',
                                Icons.emoji_events_rounded,
                                const Color(0xFFFF3B30),
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Second Row of Tools
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _minimalToolTile(
                                'Tasks',
                                Icons.checklist_rounded,
                                const Color(0xFF0A84FF),
                                    () => widget.onNavigate(1),
                              ),
                              _minimalToolTile(
                                'Calendar',
                                Icons.calendar_month_rounded,
                                const Color(0xFFFF6482),
                                    () => widget.onNavigate(2),
                              ),
                              _minimalToolTile(
                                'Progress',
                                Icons.insights_rounded,
                                const Color(0xFFAF52DE),
                                    () => widget.onNavigate(3),
                              ),
                              _minimalToolTile(
                                'Location',
                                Icons.location_on_rounded,
                                const Color(0xFF5AC8FA),
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyLocationScreen())),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ── UI Helper Widgets ──
  // ═══════════════════════════════════════

  /// Displays the user's current consecutive study day streak.
  Widget _streakBadge(int s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withAlpha(20),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9500), size: 18),
          const SizedBox(width: 4),
          Text(
            '$s',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF9500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconBubble(icon, color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBubble(IconData icon, Color color, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _minimalToolTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class EditGpaBottomSheet extends StatefulWidget {
  const EditGpaBottomSheet({super.key});

  @override
  State<EditGpaBottomSheet> createState() => _EditGpaBottomSheetState();
}

class _EditGpaBottomSheetState extends State<EditGpaBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final initialGpa = context.read<UserProvider>().currentUser?.targetGpa.toString() ?? '3.5';
    _ctrl = TextEditingController(text: initialGpa);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Set Target GPA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'e.g. 3.75',
                  labelText: 'Enter Target GPA (0.0 - 4.0)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'GPA cannot be empty';
                  final g = double.tryParse(value);
                  if (g == null) return 'Please enter a valid number';
                  if (g < 0 || g > 4.0) return 'GPA must be between 0.0 and 4.0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final g = double.parse(_ctrl.text.trim());
                      context.read<UserProvider>().setTargetGpa(g);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Target'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}