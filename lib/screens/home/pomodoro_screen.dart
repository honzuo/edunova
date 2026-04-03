import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pomodoro_provider.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatTime(provider.secondsLeft),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: provider.start,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: provider.pause,
                  child: const Text('Pause'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: provider.reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}