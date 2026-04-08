import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/task_provider.dart';
import '../../providers/session_provider.dart';

class DataExportScreen extends StatelessWidget {
  const DataExportScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final tasks = context.read<TaskProvider>().tasks;
    final sessions = context.read<SessionProvider>().sessions;
    final buf = StringBuffer();
    buf.writeln('Title,Subject,Priority,Deadline,Completed');
    for (final t in tasks) {
      buf.writeln('"${t.title}","${t.subject}","${t.priority}","${t.deadline.toIso8601String()}","${t.isCompleted}"');
    }
    buf.writeln(); buf.writeln('Title,Subject,Start,End,Duration,Notes');
    for (final s in sessions) {
      buf.writeln('"${s.title}","${s.subject}","${s.startTime.toIso8601String()}","${s.endTime.toIso8601String()}","${s.durationMinutes}","${s.notes}"');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/edunova_export.csv');
    await file.writeAsString(buf.toString());
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'EduNova Export'));
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported!')));
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.watch<TaskProvider>().tasks.length;
    final sc = context.watch<SessionProvider>().sessions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFF5AC8FA).withAlpha(20), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.file_download_rounded, size: 32, color: Color(0xFF5AC8FA)),
          ),
          const SizedBox(height: 20),
          const Text('Export Your Data', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Export tasks and study sessions as CSV.', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
          const SizedBox(height: 28),
          Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              Row(children: [const Icon(Icons.checklist_rounded, size: 20, color: Color(0xFF5856D6)), const SizedBox(width: 12), Text('$tc tasks')]),
              const SizedBox(height: 10),
              Row(children: [const Icon(Icons.timer_outlined, size: 20, color: Color(0xFFFF9500)), const SizedBox(width: 12), Text('$sc sessions')]),
            ]),
          )),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: const Icon(Icons.share_rounded),
            label: const Text('Export as CSV'),
            onPressed: () => _export(context),
          ),
        ]),
      ),
    );
  }
}
