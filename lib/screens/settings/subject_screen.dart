/// subject_screen.dart — Academic subject management (CRUD).
///
/// Allows users to add, edit, and delete subjects with:
/// - Subject code (e.g. CSC1024)
/// - Subject name (e.g. Programming Principles)
/// - Credit hours (1–6)
/// Synced to Supabase via [SubjectService].

import 'package:flutter/material.dart';

import '../../constants/subjects.dart';
import '../../models/subject.dart';
import '../../widgets/minimal_empty_state.dart';

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

  Future<void> _reload() async {
    await _svc.load();
    if (mounted) {
      setState(() {});
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final subs = _svc.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
      ),
      body: subs.isEmpty
          ? const MinimalEmptyState(
        icon: Icons.book_outlined,
        title: 'No subjects yet',
        subtitle: 'Tap + to add your first subject',
      )
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: subs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final s = subs[i];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).cardTheme.color,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) => AddEditSubjectBottomSheet(
                    editing: s,
                    onSaved: _reload,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
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
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => AddEditSubjectBottomSheet(onSaved: _reload),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class AddEditSubjectBottomSheet extends StatefulWidget {
  final Subject? editing;
  final VoidCallback onSaved;

  const AddEditSubjectBottomSheet({super.key, this.editing, required this.onSaved});

  @override
  State<AddEditSubjectBottomSheet> createState() => _AddEditSubjectBottomSheetState();
}

class _AddEditSubjectBottomSheetState extends State<AddEditSubjectBottomSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late int _creditHour;
  final _svc = SubjectService();

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.editing?.code ?? '');
    _nameCtrl = TextEditingController(text: widget.editing?.name ?? '');
    _creditHour = widget.editing?.creditHour ?? 3;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.editing != null ? 'Edit Subject' : 'Add Subject',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Subject Code (e.g. CSC1024)',
                prefixIcon: Icon(Icons.tag, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Subject Name (e.g. Programming)',
                prefixIcon: Icon(Icons.book_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _creditHour,
                  isExpanded: true,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items: [1, 2, 3, 4, 5, 6].map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text('$c Credit Hours'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => _creditHour = v ?? 3);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_codeCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) return;

                if (widget.editing != null) {
                  await _svc.update(
                    widget.editing!.id!,
                    code: _codeCtrl.text.trim(),
                    name: _nameCtrl.text.trim(),
                    creditHour: _creditHour,
                  );
                } else {
                  await _svc.add(
                    code: _codeCtrl.text.trim(),
                    name: _nameCtrl.text.trim(),
                    creditHour: _creditHour,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  widget.onSaved();
                }
              },
              child: Text(widget.editing != null ? 'Update' : 'Add Subject'),
            ),
          ],
        ),
      ),
    );
  }
}