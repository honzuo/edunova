/// search_screen.dart — Global search across tasks and sessions.
///
/// Provides real-time search filtering by title, subject,
/// and description. Results are grouped into Tasks and Sessions
/// sections with appropriate icons and details.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/session_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final sessions = context.watch<SessionProvider>().sessions;
    final ft = tasks.where((t) => t.title.toLowerCase().contains(_q) || t.subject.toLowerCase().contains(_q) || t.description.toLowerCase().contains(_q)).toList();
    final fs = sessions.where((s) => s.title.toLowerCase().contains(_q) || s.subject.toLowerCase().contains(_q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _ctrl, autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search…', border: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey[500]),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: false,
            ),
            onChanged: (v) => setState(() => _q = v.toLowerCase()),
          ),
        ),
        actions: [
          if (_q.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _ctrl.clear(); setState(() => _q = ''); }),
        ],
      ),
      body: _q.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_rounded, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('Type to search', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            ]))
          : ListView(padding: const EdgeInsets.all(20), children: [
              if (ft.isNotEmpty) ...[
                Text('TASKS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Card(child: Column(children: ft.map((t) => ListTile(
                  leading: Icon(t.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 20, color: t.isCompleted ? const Color(0xFF34C759) : Colors.grey),
                  title: Text(t.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: Text('${t.subject} · ${t.priority}', style: const TextStyle(fontSize: 13)),
                )).toList())),
                const SizedBox(height: 20),
              ],
              if (fs.isNotEmpty) ...[
                Text('SESSIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Card(child: Column(children: fs.map((s) => ListTile(
                  leading: const Icon(Icons.timer_outlined, size: 20),
                  title: Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: Text('${s.subject} · ${s.durationMinutes} min', style: const TextStyle(fontSize: 13)),
                )).toList())),
              ],
              if (ft.isEmpty && fs.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(40),
                    child: Text('No results', style: TextStyle(color: Colors.grey[400], fontSize: 16)))),
            ]),
    );
  }
}
