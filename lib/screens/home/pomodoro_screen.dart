import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus'),
        actions: [
          if (p.isRunning)
            TextButton(
              onPressed: () async {
                await p.stopAll();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('End', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 20),

          // ── Duration Selector ──
          AnimatedOpacity(
            opacity: p.isRunning ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: p.isRunning,
              child: _DurationSelector(
                options: PomodoroProvider.durationOptions,
                selected: p.selectedMinutes,
                onSelected: (min) {
                  HapticFeedback.selectionClick();
                  p.setDuration(min);
                },
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Timer Ring ──
          SizedBox(
            width: 260, height: 260,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 260, height: 260,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: p.progress),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, value, __) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: cs.outline.withAlpha(30),
                    color: p.isRunning ? const Color(0xFFFF9500) : cs.primary,
                  ),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_fmt(p.secondsLeft), style: TextStyle(
                  fontSize: 64, fontWeight: FontWeight.w100, letterSpacing: -3,
                  color: cs.onSurface,
                )),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    p.isRunning ? 'Focusing…' : '${p.selectedMinutes} min session',
                    key: ValueKey(p.isRunning),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 36),

          // ── Controls ──
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Reset
            _circleBtn(
              icon: Icons.refresh_rounded,
              color: Colors.grey[400]!,
              onTap: () {
                HapticFeedback.lightImpact();
                p.reset();
              },
              size: 48,
            ),
            const SizedBox(width: 24),
            // Play / Pause
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                p.isRunning ? p.pause() : p.start();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.isRunning ? const Color(0xFFFF9500) : cs.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (p.isRunning ? const Color(0xFFFF9500) : cs.primary).withAlpha(60),
                      blurRadius: 20, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  p.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 36, color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Skip (only when running)
            AnimatedOpacity(
              opacity: p.isRunning ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _circleBtn(
                icon: Icons.skip_next_rounded,
                color: Colors.grey[400]!,
                onTap: p.isRunning ? () {
                  HapticFeedback.lightImpact();
                  p.reset();
                } : () {},
                size: 48,
              ),
            ),
          ]),

          const SizedBox(height: 44),

          // ── Sound Mixer ──
          const WhiteNoiseMixer(),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required Color color, required VoidCallback onTap, double size = 56}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(20)),
        child: Icon(icon, size: size * 0.45, color: color),
      ),
    );
  }
}

// ── Duration Selector Chips ──
class _DurationSelector extends StatelessWidget {
  final List<int> options;
  final int selected;
  final void Function(int) onSelected;

  const _DurationSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((min) {
          final isSelected = min == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(min),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.primary.withAlpha(40),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$min min',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : cs.primary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
