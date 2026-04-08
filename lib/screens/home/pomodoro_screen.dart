import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pomodoro_provider.dart';
import '../../widgets/white_noise_selector.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PomodoroProvider>();
    final progress = 1.0 - (p.secondsLeft / (25 * 60));

    return Scaffold(
      appBar: AppBar(title: const Text('Focus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 40),
          SizedBox(
            width: 240, height: 240,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 240, height: 240,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Theme.of(context).colorScheme.outline.withAlpha(40),
                  color: p.isRunning ? const Color(0xFFFF9500) : Theme.of(context).colorScheme.primary,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_fmt(p.secondsLeft), style: TextStyle(
                  fontSize: 56, fontWeight: FontWeight.w200, letterSpacing: -2,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
                Text(p.isRunning ? 'Focusing…' : 'Ready',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ]),
            ]),
          ),
          const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _circleBtn(
              icon: p.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Theme.of(context).colorScheme.primary,
              onTap: p.isRunning ? p.pause : p.start,
              size: 64,
            ),
            const SizedBox(width: 20),
            _circleBtn(
              icon: Icons.refresh_rounded,
              color: Colors.grey[400]!,
              onTap: p.reset,
              size: 48,
            ),
          ]),
          const SizedBox(height: 48),
          const WhiteNoiseSelector(onChanged: _noOp),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  static void _noOp(String? _) {}

  Widget _circleBtn({required IconData icon, required Color color, required VoidCallback onTap, double size = 56}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(20)),
        child: Icon(icon, size: size * 0.5, color: color),
      ),
    );
  }
}
