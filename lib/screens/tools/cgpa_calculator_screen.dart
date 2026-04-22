/// cgpa_calculator_screen.dart — CGPA calculator with semester records.
///
/// Features:
/// - Overall CGPA banner computed from all saved records
/// - Semester record list with edit/delete support
/// - GPA calculator with subject dropdown and grade selection
/// - Grade scale reference table
/// - Auto-fill credit hours from subject database
/// - CRUD operations synced to Supabase

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../constants/subjects.dart';
import '../../models/subject.dart';

import '../../models/cgpa_record.dart';
import '../../services/database_service.dart';

class CgpaCalculatorScreen extends StatefulWidget {
  const CgpaCalculatorScreen({super.key});
  @override
  State<CgpaCalculatorScreen> createState() => _CgpaCalculatorScreenState();
}

class _CgpaCalculatorScreenState extends State<CgpaCalculatorScreen> {
  final DatabaseService _db = DatabaseService();
  String get _userId => AuthService().currentUserId ?? 'demo-user';

  List<CgpaRecord> _records = [];
  bool _showCalculator = false;

  // Calculator state
  int _calcYear = 1;
  int _calcSem = 1;
  final List<_CourseEntry> _courses = [_CourseEntry()];
  double? _calcResult;
  CgpaRecord? _editingRecord; // null = new, non-null = editing

  static const Map<String, double> gradePoints = {
    'A+': 4.0, 'A': 4.0, 'A-': 3.67,
    'B+': 3.33, 'B': 3.0, 'B-': 2.67,
    'C+': 2.33, 'C': 2.0, 'F': 0.0,
  };

  static const Map<String, String> gradeLabels = {
    'A+': 'High Distinction', 'A': 'Distinction', 'A-': 'Distinction',
    'B+': 'Merit', 'B': 'Merit', 'B-': 'Merit',
    'C+': 'Pass', 'C': 'Pass', 'F': 'Fail',
  };

  @override
  @override
  void initState() {
    super.initState();
    _loadRecords();
    SubjectService().load().then((_) { if (mounted) setState(() {}); });
  }

  Future<void> _loadRecords() async {
    final data = await _db.getCgpaRecordsByUser(_userId);
    setState(() => _records = data.map((m) => CgpaRecord.fromMap(m)).toList());
  }

  double get _overallCgpa {
    if (_records.isEmpty) return 0;
    double totalPoints = 0;
    int totalCredits = 0;
    for (final r in _records) {
      totalPoints += r.gpa * r.totalCredits;
      totalCredits += r.totalCredits;
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0;
  }

  void _calculate() {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final c in _courses) {
      if (c.grade != null && c.subjectName != null && c.credits > 0) {
        totalPoints += (gradePoints[c.grade] ?? 0) * c.credits;
        totalCredits += c.credits;
      }
    }
    setState(() => _calcResult = totalCredits > 0 ? totalPoints / totalCredits : null);
  }

  Future<void> _saveRecord() async {
    if (_calcResult == null) { _calculate(); if (_calcResult == null) return; }

    int totalCredits = 0;
    final courseMaps = <Map<String, dynamic>>[];
    for (final c in _courses) {
      if (c.grade != null && c.subjectName != null && c.credits > 0) {
        totalCredits += c.credits;
        courseMaps.add({'name': c.subjectName ?? '', 'code': c.subjectCode ?? '', 'credits': c.credits, 'grade': c.grade});
      }
    }

    final data = {
      'user_id': _userId,
      'year': _calcYear,
      'semester': _calcSem,
      'gpa': _calcResult,
      'total_credits': totalCredits,
      'courses_json': jsonEncode(courseMaps),
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_editingRecord != null && _editingRecord!.id != null) {
      await _db.updateCgpaRecord(_editingRecord!.id!, data);
    } else {
      await _db.insertCgpaRecord(data);
    }

    await _loadRecords();
    _resetCalculator();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPA saved!')));
  }

  Future<void> _deleteRecord(CgpaRecord record) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete GPA Record?'),
      content: Text('${record.label} - GPA: ${record.gpa.toStringAsFixed(2)}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm == true && record.id != null) {
      await _db.deleteCgpaRecord(record.id!);
      await _loadRecords();
    }
  }

  void _editRecord(CgpaRecord record) {
    final courses = (jsonDecode(record.coursesJson) as List).map((m) {
      final entry = _CourseEntry();
      entry.subjectName = m['name'] as String?;
      entry.subjectCode = m['code'] as String?;
      entry.credits = (m['credits'] as num?)?.toInt() ?? 3;
      entry.grade = m['grade'] as String?;
      return entry;
    }).toList();

    setState(() {
      _showCalculator = true;
      _editingRecord = record;
      _calcYear = record.year;
      _calcSem = record.semester;
      _courses.clear();
      _courses.addAll(courses.isEmpty ? [_CourseEntry()] : courses);
      _calcResult = record.gpa;
    });
  }

  void _resetCalculator() {
    setState(() {
      _showCalculator = false;
      _editingRecord = null;
      _calcYear = 1;
      _calcSem = 1;
      _courses.clear();
      _courses.add(_CourseEntry());
      _calcResult = null;
    });
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 3.67) return const Color(0xFF34C759);
    if (gpa >= 3.0) return const Color(0xFF0A84FF);
    if (gpa >= 2.0) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  String _gpaLabel(double gpa) {
    if (gpa >= 3.67) return 'Distinction';
    if (gpa >= 3.0) return 'Merit';
    if (gpa >= 2.0) return 'Pass';
    return 'Fail';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showCalculator ? (_editingRecord != null ? 'Edit GPA' : 'New GPA') : 'CGPA Calculator'),
        leading: _showCalculator
            ? IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _resetCalculator)
            : null,
      ),
      body: _showCalculator ? _buildCalculator() : _buildOverview(),
      floatingActionButton: _showCalculator ? null : FloatingActionButton(
        heroTag: 'fab_cgpa',
        onPressed: () => setState(() => _showCalculator = true),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ═══════════════════════════════
  // ── OVERVIEW (saved records) ──
  // ═══════════════════════════════

  Widget _buildOverview() {
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(slivers: [
      // Overall CGPA banner
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _records.isEmpty
                  ? [Colors.grey[400]!, Colors.grey[500]!]
                  : [_gpaColor(_overallCgpa), _gpaColor(_overallCgpa).withAlpha(180)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Text('Cumulative GPA', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              _records.isEmpty ? '—' : _overallCgpa.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -2),
            ),
            if (_records.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)),
                child: Text(_gpaLabel(_overallCgpa),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            if (_records.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('No records yet', style: TextStyle(color: Colors.white60, fontSize: 13)),
              ),
          ]),
        ),
      )),

      // Semester records
      if (_records.isNotEmpty) ...[
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text('Semester Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        )),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: _records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _recordCard(_records[i]),
          ),
        ),
      ],

      // Grade reference
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
        child: Text('Grade Scale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
      )),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: gradePoints.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(width: 32, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              const SizedBox(width: 8),
              Text(e.value.toStringAsFixed(2), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const Spacer(),
              Text(gradeLabels[e.key] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
          )).toList()),
        )),
      )),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }

  Widget _recordCard(CgpaRecord record) {
    final color = _gpaColor(record.gpa);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editRecord(record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(record.gpa.toStringAsFixed(2),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${record.totalCredits} credits · ${_gpaLabel(record.gpa)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ])),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey[400]),
              onPressed: () => _deleteRecord(record),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════
  // ── CALCULATOR ──
  // ═══════════════════════════════

  Widget _buildCalculator() {
    return Column(children: [
      // Year / Semester selector
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(children: [
          Expanded(child: _dropdownCard('Year', _calcYear, [1, 2, 3, 4, 5],
              (v) => setState(() => _calcYear = v), (v) => 'Year $v')),
          const SizedBox(width: 10),
          Expanded(child: _dropdownCard('Semester', _calcSem, [1, 2, 3],
              (v) => setState(() => _calcSem = v), (v) => 'Sem $v')),
        ]),
      ),

      // Result
      if (_calcResult != null) _resultBanner(),

      // Course list
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: _courses.length + 1,
          itemBuilder: (_, i) {
            if (i == _courses.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _courses.add(_CourseEntry())); HapticFeedback.lightImpact(); },
                  child: Card(child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Add Course', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                    ]),
                  )),
                ),
              );
            }
            return _courseCard(i);
          },
        ),
      ),

      // Buttons
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: _calculate,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
            child: const Text('Calculate'),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () { _calculate(); if (_calcResult != null) _saveRecord(); },
            child: Text(_editingRecord != null ? 'Update' : 'Save'),
          )),
        ]),
      ),
      SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
    ]);
  }

  Widget _resultBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _gpaColor(_calcResult!).withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gpaColor(_calcResult!).withAlpha(50)),
      ),
      child: Row(children: [
        Text('GPA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _gpaColor(_calcResult!))),
        const Spacer(),
        Text(_calcResult!.toStringAsFixed(4),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _gpaColor(_calcResult!), letterSpacing: -0.5)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: _gpaColor(_calcResult!).withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Text(_gpaLabel(_calcResult!),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _gpaColor(_calcResult!))),
        ),
      ]),
    );
  }

  Widget _dropdownCard<T>(String label, T value, List<T> items, void Function(T) onChanged, String Function(T) display) {
    return Card(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        items: items.map((v) => DropdownMenuItem(value: v, child: Text(display(v)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      )),
    ));
  }

  Widget _courseCard(int index) {
    final course = _courses[index];
    final subjects = SubjectService().subjects;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          // Subject selector
          Row(children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: const Color(0xFF5856D6).withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5856D6))))),
            const SizedBox(width: 10),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: course.subjectName != null && subjects.any((s) => s.name == course.subjectName)
                    ? course.subjectName : null,
                isExpanded: true,
                hint: const Text('Select Subject'),
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                items: subjects.map((s) => DropdownMenuItem(value: s.name,
                  child: Text('${s.code} - ${s.name}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) {
                  final sub = subjects.firstWhere((s) => s.name == v);
                  setState(() {
                    course.subjectName = v;
                    course.subjectCode = sub.code;
                    course.credits = sub.creditHour;
                    _calcResult = null;
                  });
                },
              )),
            )),
            const SizedBox(width: 6),
            if (_courses.length > 1)
              GestureDetector(
                onTap: () { setState(() { _courses.removeAt(index); _calcResult = null; }); },
                child: Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.grey[400])),
          ]),
          const SizedBox(height: 10),
          // Credit hours (auto-filled) + Grade
          Row(children: [
            // Credits (read-only, from subject)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(10)),
              child: Text('${course.credits} Credits', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
            ),
            const SizedBox(width: 10),
            // Grade dropdown
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: course.grade,
                isExpanded: true,
                hint: const Text('Grade'),
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                items: gradePoints.keys.map((g) =>
                    DropdownMenuItem(value: g, child: Text('$g (${gradePoints[g]!.toStringAsFixed(2)})'))).toList(),
                onChanged: (v) => setState(() { course.grade = v; _calcResult = null; }),
              )),
            )),
          ]),
        ]),
      )),
    );
  }
}

class _CourseEntry {
  String? subjectName;
  String? subjectCode;
  int credits = 3;
  String? grade;
}
