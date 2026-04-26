/// subject_screen.dart — Academic subject management (CRUD).
///
/// Allows users to add, edit, and delete subjects with:
/// - Subject code (e.g. CSC1024)
/// - Subject name (e.g. Programming Principles)
/// - Credit hours (1–6)
/// Synced to Supabase via [SubjectService].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/subjects.dart';
import '../../models/subject.dart';

/// Subject management screen — full CRUD operations.
/// Subjects contain: code, name, credit_hour.
class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final _svc = SubjectService();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// Reload subjects from the service and update UI
  Future<void> _reload() async {
    await _svc.load();
    if (mounted) {
      setState(() {});
    }
  }

  // ── Add/Edit Subject Bottom Sheet ──
  void _showAddEdit({Subject? editing}) {
    // Initialize controllers with existing data if editing
    final codeCtrl = TextEditingController(text: editing?.code ?? '');
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    int creditHour = editing?.creditHour ?? 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Indicator Line ──
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // ── Sheet Title ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  editing != null ? 'Edit Subject' : 'Add Subject',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),

              // ── Subject Code Input ──
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Subject Code (e.g. CSC1024)',
                  prefixIcon: Icon(Icons.tag, size: 20),
                ),
              ),
              const SizedBox(height: 10),

              // ── Subject Name Input ──
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Subject Name (e.g. Programming)',
                  prefixIcon: Icon(Icons.book_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 10),

              // ── Credit Hours Dropdown ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: creditHour,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                    items: [1, 2, 3, 4, 5, 6].map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text('$c Credit Hours'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setSt(() => creditHour = v ?? 3);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Save/Update Button ──
              ElevatedButton(
                onPressed: () async {
                  // Validate inputs
                  if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;

                  // Save data
                  if (editing != null) {
                    await _svc.update(
                      editing.id!,
                      code: codeCtrl.text,
                      name: nameCtrl.text,
                      creditHour: creditHour,
                    );
                  } else {
                    await _svc.add(
                      code: codeCtrl.text,
                      name: nameCtrl.text,
                      creditHour: creditHour,
                    );
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  _reload();
                },
                child: Text(editing != null ? 'Update' : 'Add Subject'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete Confirmation Dialog ──
  Future<void> _delete(Subject s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('${s.code} - ${s.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true && s.id != null) {
      await _svc.delete(s.id!);
      _reload();
    }
  }

  // ── Main UI Build ──
  @override
  Widget build(BuildContext context) {
    final subs = _svc.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
      ),
      body: subs.isEmpty
      // ── Empty State ──
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No subjects yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first subject',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      )
      // ── Subject List ──
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: subs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final s = subs[i];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showAddEdit(editing: s), // Tap to edit
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Credit Hour Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5856D6).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${s.creditHour}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5856D6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Subject Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.code,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A84FF),
                            ),
                          ),
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${s.creditHour} credit hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                      onPressed: () => _delete(s),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_subject',
        onPressed: () => _showAddEdit(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}