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
  bool _isLoading = true; // 加载状态控制

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// 统一初始化数据并处理异常
  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. 加载每日金句 (API)
      _quote = await ApiService().getQuote();

      // 2. 并行加载所有 Provider 数据以提高效率
      await Future.wait([
        context.read<TaskProvider>().loadTasks(),
        context.read<SessionProvider>().loadSessions(),
        context.read<UserProvider>().loadUser(),
        context.read<AchievementProvider>().loadAchievements(),
        _loadCurrentCgpa(),
      ]);

      if (!mounted) return;

      // 3. 生成进度报告
      context.read<ProgressProvider>().generateReport(
          taskProvider: context.read<TaskProvider>(),
          sessionProvider: context.read<SessionProvider>());

      // 4. 评估成就 (包含 Supabase 查询)
      await _evaluateAchievements();
    } catch (e) {
      debugPrint("Home Data Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync data. Working in offline mode.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _evaluateAchievements() async {
    final ap = context.read<AchievementProvider>();
    final streak = await ap.calculateStreak();
    final tasks = context.read<TaskProvider>().tasks;
    final sessions = context.read<SessionProvider>().sessions;
    final uid = AuthService().currentUserId ?? 'demo-user';

    // 访问远程数据库增加 try-catch
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
    setState(() => _currentCgpa = totalCr > 0 ? totalPts / totalCr : 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(), // 加载动画
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
      body: RefreshIndicator( // 增加下拉刷新功能
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
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SearchScreen())))
                ]),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(
                                    user?.fullName.isNotEmpty == true
                                        ? 'Welcome, ${user!.fullName}'
                                        : 'Welcome',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.8,
                                        color: cs.onSurface))),
                            _streakBadge(streak)
                          ]),

                          // GPA 展示区
                          if (user != null) ...[
                            const SizedBox(height: 16),
                            GestureDetector(
                                onTap: _showEditGpaGoal,
                                child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF34C759).withAlpha(15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFF34C759).withAlpha(50))),
                                    child: Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Target GPA',
                                                    style: TextStyle(
                                                        fontSize: 12, color: Colors.grey[500])),
                                                Text(user.targetGpa.toStringAsFixed(2),
                                                    style: const TextStyle(
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF34C759))),
                                              ])),
                                      Container(
                                          width: 1, height: 40, color: Colors.grey.withAlpha(40)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Current GPA',
                                                    style: TextStyle(
                                                        fontSize: 12, color: Colors.grey[500])),
                                                Text(_currentCgpa > 0 ? _currentCgpa.toStringAsFixed(2) : '—',
                                                    style: TextStyle(
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.w700,
                                                        color: _currentCgpa >= user.targetGpa
                                                            ? const Color(0xFF34C759)
                                                            : const Color(0xFFFF9500))),
                                              ])),
                                      Icon(Icons.edit_rounded, size: 16, color: Colors.grey[400]),
                                    ]))),
                          ],

                          // 每日金句卡片
                          if (_quote.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Icon(Icons.format_quote_rounded,
                                                size: 20, color: cs.primary),
                                            const SizedBox(width: 6),
                                            Text('Daily Inspiration',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.primary))
                                          ]),
                                          const SizedBox(height: 8),
                                          Text(_quote['quote'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontStyle: FontStyle.italic,
                                                  height: 1.4)),
                                          const SizedBox(height: 6),
                                          Text('— ${_quote['author'] ?? ''}',
                                              style: TextStyle(
                                                  fontSize: 13, color: Colors.grey[500]))
                                        ])))
                          ],

                          const SizedBox(height: 20),
                          Row(children: [
                            _statCard(
                                'Tasks',
                                '${report.completedTasks + report.pendingTasks}',
                                Icons.checklist_rounded,
                                const Color(0xFF5856D6)),
                            const SizedBox(width: 10),
                            _statCard('Studied', '${totalH}h', Icons.timer_outlined,
                                const Color(0xFFFF9500)),
                            const SizedBox(width: 10),
                            _statCard('Done', '${report.completionRate.toStringAsFixed(0)}%',
                                Icons.pie_chart_rounded, const Color(0xFF34C759))
                          ]),
                          const SizedBox(height: 24),

                          _sectionTitle('Today\'s Overview'),
                          const SizedBox(height: 10),
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(children: [
                                    Row(children: [
                                      _iconBubble(Icons.access_time_rounded, const Color(0xFFFF9500)),
                                      const SizedBox(width: 14),
                                      Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Study Time',
                                                style: TextStyle(fontSize: 13, color: Colors.grey)),
                                            Text('$todayMin min',
                                                style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -0.5))
                                          ])
                                    ]),
                                    if (todayTasks.isNotEmpty) ...[
                                      const Divider(height: 28),
                                      ...todayTasks.take(3).map((t) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(children: [
                                            Icon(
                                                t.isCompleted
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle_outlined,
                                                size: 20,
                                                color: t.isCompleted
                                                    ? const Color(0xFF34C759)
                                                    : Colors.grey[400]),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Text(t.title,
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        decoration: t.isCompleted
                                                            ? TextDecoration.lineThrough
                                                            : null,
                                                        color: t.isCompleted ? Colors.grey : null)))
                                          ])))
                                    ],
                                    if (todayTasks.isEmpty)
                                      Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text('No tasks for today',
                                              style: TextStyle(
                                                  color: Colors.grey[400], fontSize: 14)))
                                  ]))),
                          const SizedBox(height: 24),

                          _sectionTitle('Tools'),
                          const SizedBox(height: 10),
                          GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                              children: [
                                _toolTile(
                                    'Pomodoro',
                                    Icons.timer_rounded,
                                    const Color(0xFFFF9500),
                                        () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const PomodoroScreen()))),
                                _toolTile('CGPA', Icons.calculate_rounded, const Color(0xFF5856D6),
                                        () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const CgpaCalculatorScreen()));
                                      _loadCurrentCgpa();
                                    }),
                                _toolTile(
                                    'Goals',
                                    Icons.flag_rounded,
                                    const Color(0xFF34C759),
                                        () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const GoalScreen()))),
                                _toolTile(
                                    'Badges',
                                    Icons.emoji_events_rounded,
                                    const Color(0xFFFF3B30),
                                        () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const AchievementsScreen()))),
                                _toolTile('Tasks', Icons.checklist_rounded, const Color(0xFF0A84FF),
                                        () => widget.onNavigate(1)),
                                _toolTile(
                                    'Calendar',
                                    Icons.calendar_month_rounded,
                                    const Color(0xFFFF6482),
                                        () => widget.onNavigate(2)),
                                _toolTile('Progress', Icons.insights_rounded, const Color(0xFFAF52DE),
                                        () => widget.onNavigate(3)),
                                _toolTile(
                                    'Location',
                                    Icons.location_on_rounded,
                                    const Color(0xFF5AC8FA),
                                        () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const StudyLocationScreen()))),
                              ]),
                        ])))
          ],
        ),
      ),
    );
  }

  /// 改进后的 GPA 设置，包含完整 Input Validation
  void _showEditGpaGoal() {
    final ctrl = TextEditingController(
        text: context.read<UserProvider>().currentUser?.targetGpa.toString() ?? '3.5');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardTheme.color,
        shape:
        const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 36,
                    height: 4,
                    decoration:
                    BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Set Target GPA',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 3.75',
                    labelText: 'Enter Target GPA (0.0 - 4.0)',
                    border: OutlineInputBorder(),
                  ),
                  // 输入校验逻辑
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
                        if (formKey.currentState!.validate()) {
                          final g = double.parse(ctrl.text.trim());
                          context.read<UserProvider>().setTargetGpa(g);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Save Target')),
                )
              ]),
            )));
  }

  // 辅助 UI 组件 (保持原样但优化布局)
  Widget _streakBadge(int s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFFFF9500).withAlpha(20), borderRadius: BorderRadius.circular(24)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9500), size: 18),
        const SizedBox(width: 4),
        Text('$s',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFF9500)))
      ]));
  Widget _statCard(String l, String v, IconData ic, Color c) => Expanded(
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _iconBubble(ic, c, size: 32),
                const SizedBox(height: 12),
                Text(v,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(l, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
              ]))));
  Widget _iconBubble(IconData ic, Color c, {double size = 36}) => Container(
      width: size,
      height: size,
      decoration:
      BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(ic, size: size * 0.5, color: c));
  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5));
  Widget _toolTile(String l, IconData ic, Color c, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 52,
            height: 52,
            decoration:
            BoxDecoration(color: c.withAlpha(20), borderRadius: BorderRadius.circular(16)),
            child: Icon(ic, size: 26, color: c)),
        const SizedBox(height: 8),
        Text(l,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis)
      ]));
}