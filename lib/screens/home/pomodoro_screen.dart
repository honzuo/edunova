/// pomodoro_screen.dart — Focus timer with ambient backgrounds.
///
/// Features:
/// - Configurable timer durations (5–60 minutes)
/// - Circular progress indicator with countdown
/// - Video backgrounds (rain, fire, forest, ocean, night)
/// - White noise sound mixer with volume control
/// - Task linking for automatic study session logging
/// - Start/pause/reset controls with haptic feedback

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/study_task.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/white_noise_selector.dart';


class PomodoroScreen extends StatefulWidget {
  final StudyTask? initialTask;
  const PomodoroScreen({super.key, this.initialTask});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  int _bgIdx = 0;
  VideoPlayerController? _videoCtrl;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isStrictMode = false;
  int _distractionCount = 0;

  static const _bgThemes = [
    {'name': 'Default', 'icon': Icons.brightness_auto_rounded, 'video': ''},
    {'name': 'Rain',    'icon': Icons.water_drop_rounded,       'video': 'assets/videos/rain.mp4'},
    {'name': 'Fire',    'icon': Icons.local_fire_department,     'video': 'assets/videos/fire.mp4'},
    {'name': 'Forest',  'icon': Icons.park_rounded,              'video': 'assets/videos/forest.mp4'},
    {'name': 'Ocean',   'icon': Icons.waves_rounded,             'video': 'assets/videos/ocean.mp4'},
    {'name': 'Night',   'icon': Icons.nightlight_rounded,        'video': 'assets/videos/night.mp4'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) Future.microtask(() => context.read<PomodoroProvider>().linkTask(widget.initialTask));
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _videoCtrl?.dispose();
    super.dispose();
  }

  void _toggleStrictMode(bool value) {
    setState(() {
      _isStrictMode = value;
      if (_isStrictMode) {
        _distractionCount = 0;
        _startSensor();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔥 Strict mode enabled: Place phone face down to start focusing!')),
        );
      } else {
        _accelSub?.cancel();
      }
    });
  }

  void _startSensor() {
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!mounted) return;
      final p = context.read<PomodoroProvider>();

      // Face down
      if (event.z < -8.0 && !p.isRunning && p.secondsLeft > 0) {
        HapticFeedback.vibrate(); // 震动反馈
        p.start();
      }
      // Face up during focus
      else if (event.z > 8.0 && p.isRunning && _isStrictMode) {
        p.pause();
        HapticFeedback.heavyImpact();
        setState(() => _distractionCount++);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('😡 Caught you!'),
            content: Text('Why did you pick up your phone? Get back to studying!\n\nDistractions: $_distractionCount'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('I will put it back', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    });
  }

  bool get _hasBg => _bgIdx > 0;

  Future<void> _switchBg(int idx) async {
    _videoCtrl?.dispose();
    _videoCtrl = null;
    setState(() => _bgIdx = idx);

    if (idx == 0) return;
    final path = _bgThemes[idx]['video'] as String;
    if (path.isEmpty) return;

    try {
      // mixWithOthers: true allows just_audio to play simultaneously
      final ctrl = VideoPlayerController.asset(path,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      await ctrl.play();
      if (mounted) setState(() => _videoCtrl = ctrl);
    } catch (e) {
      debugPrint('Video load failed: $e');
    }
  }

  // generate QR code
  void _showQRCode() {
    final p = context.read<PomodoroProvider>();
    final qrData = 'pomodoro:${p.selectedMinutes}:${p.linkedTask?.title ?? "Group Study"}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Invite Friends', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 240,
          height: 240,
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 240.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // open camera
  void _scanToJoin() {
    bool hasDetected = false;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (innerCtx) => Scaffold(
        appBar: AppBar(title: const Text('Scan to Join')),
        body: MobileScanner(
          onDetect: (capture) {
            if (hasDetected) return;

            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final data = barcode.rawValue;
              if (data != null && data.startsWith('pomodoro:')) {
                hasDetected = true;

                Navigator.pop(innerCtx);

                final parts = data.split(':');
                final mins = int.tryParse(parts[1]) ?? 25;
                final taskName = parts.length > 2 ? parts[2] : 'Focus';

                final p = context.read<PomodoroProvider>();
                p.setDuration(mins);
                HapticFeedback.vibrate();
                p.start();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🔥 Successfully joined! Goal: $taskName, $mins mins')),
                  );
                }
                break;
              }
            }
          },
        ),
      ),
    ));
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PomodoroProvider>();
    final cs = Theme.of(context).colorScheme;
    final fg = _hasBg ? Colors.white : cs.onSurface;

    return Scaffold(
      extendBodyBehindAppBar: _hasBg,
      appBar: AppBar(
          backgroundColor: _hasBg ? Colors.transparent : null,
          elevation: 0,
          foregroundColor: fg,
          title: Text('Focus', style: TextStyle(color: fg)),
          actions: [
            if (!p.isRunning) IconButton(
              icon: const Icon(Icons.qr_code_2_rounded),
              tooltip: 'Generate Room Code',
              onPressed: _showQRCode,
            ),
            if (!p.isRunning) IconButton(
              icon: const Icon(Icons.document_scanner_rounded),
              tooltip: 'Scan to Join',
              onPressed: _scanToJoin,
            ),
            if (p.isRunning)
              TextButton(
                  onPressed: () async {
                    await p.stopAll();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('End', style: TextStyle(color: Colors.red))
              )
          ]
      ),
      body: Stack(children: [
        // ── Video background ──
        if (_hasBg && _videoCtrl != null && _videoCtrl!.value.isInitialized)
          SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(
            width: _videoCtrl!.value.size.width, height: _videoCtrl!.value.size.height,
            child: VideoPlayer(_videoCtrl!)))),

        // ── Dark overlay for readability ──
        if (_hasBg) Container(color: Colors.black.withAlpha(_videoCtrl != null ? 100 : 180)),

        // ── Fallback gradient if no video loaded ──
        if (_hasBg && _videoCtrl == null)
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)]))),

        // ── Main content ──
        SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
          const SizedBox(height: 12),
          _TaskSelector(enabled: !p.isRunning, linkedTask: p.linkedTask, onSelect: (t) => p.linkTask(t), onClear: () => p.linkTask(null)),
          const SizedBox(height: 20),

          // Duration chips
          AnimatedOpacity(opacity: p.isRunning ? 0.3 : 1.0, duration: const Duration(milliseconds: 200),
            child: IgnorePointer(ignoring: p.isRunning,
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
                children: PomodoroProvider.durationOptions.map((m) {
                  final sel = m == p.selectedMinutes;
                  return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); p.setDuration(m); },
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? (_hasBg ? Colors.white.withAlpha(40) : cs.primary) : (_hasBg ? Colors.white.withAlpha(10) : cs.primary.withAlpha(10)),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: sel ? (_hasBg ? Colors.white60 : cs.primary) : (_hasBg ? Colors.white24 : cs.primary.withAlpha(40)))),
                      child: Text('$m min', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : (_hasBg ? Colors.white70 : cs.primary))))));
                }).toList())))),
          const SizedBox(height: 32),

          // Timer ring
          SizedBox(width: 260, height: 260, child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 260, height: 260, child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: p.progress), duration: const Duration(milliseconds: 300),
              builder: (_, v, __) => CircularProgressIndicator(value: v, strokeWidth: 6, strokeCap: StrokeCap.round,
                backgroundColor: (_hasBg ? Colors.white : cs.outline).withAlpha(30),
                color: p.isRunning ? const Color(0xFFFF9500) : (_hasBg ? Colors.white : cs.primary)))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_fmt(p.secondsLeft), style: TextStyle(fontSize: 64, fontWeight: FontWeight.w100, letterSpacing: -3, color: fg)),
              const SizedBox(height: 4),
              Text(p.isRunning ? (p.linkedTask?.title ?? 'Focusing…') : '${p.selectedMinutes} min session',
                style: TextStyle(fontSize: 14, color: _hasBg ? Colors.white60 : Colors.grey[500], fontWeight: FontWeight.w500),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)])])),
          const SizedBox(height: 36),

          // Controls
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _circBtn(Icons.refresh_rounded, () { HapticFeedback.lightImpact(); p.reset(); }, 48),
            const SizedBox(width: 24),
            GestureDetector(onTap: () { HapticFeedback.mediumImpact(); p.isRunning ? p.pause() : p.start(); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 72, height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: p.isRunning ? const Color(0xFFFF9500) : (_hasBg ? Colors.white.withAlpha(40) : cs.primary),
                  boxShadow: [BoxShadow(color: (p.isRunning ? const Color(0xFFFF9500) : cs.primary).withAlpha(60), blurRadius: 20, offset: const Offset(0, 6))]),
                child: Icon(p.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: Colors.white))),
            const SizedBox(width: 24),
            AnimatedOpacity(opacity: p.isRunning ? 1 : 0, duration: const Duration(milliseconds: 200),
              child: _circBtn(Icons.skip_next_rounded, p.isRunning ? () { HapticFeedback.lightImpact(); p.reset(); } : () {}, 48))]),
          const SizedBox(height: 36),

          // ── Strict Mode Toggle (Flip to Focus) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _hasBg ? Colors.white.withAlpha(20) : cs.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _hasBg ? Colors.white30 : cs.primary.withAlpha(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.screen_rotation_rounded,
                        color: _isStrictMode ? const Color(0xFFFF9500) : (_hasBg ? Colors.white70 : Colors.grey[600])),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Strict Mode', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: _hasBg ? Colors.white : cs.onSurface)),
                        Text('Flip phone face down to start', style: TextStyle(
                            fontSize: 12, color: _hasBg ? Colors.white60 : Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _isStrictMode,
                  onChanged: _toggleStrictMode,
                  activeColor: const Color(0xFFFF9500),
                ),
              ],
            ),
          ),

          if (_isStrictMode && _distractionCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Distractions: $_distractionCount',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ),

          const SizedBox(height: 36),

          // Background selector
          Align(alignment: Alignment.centerLeft, child: Text('Background',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _hasBg ? Colors.white70 : Colors.grey[600]))),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
            children: List.generate(_bgThemes.length, (i) {
              final t = _bgThemes[i]; final sel = i == _bgIdx;
              return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                onTap: () => _switchBg(i),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? (_hasBg ? Colors.white.withAlpha(30) : cs.primary.withAlpha(20)) : (_hasBg ? Colors.white.withAlpha(8) : Colors.grey.withAlpha(15)),
                    borderRadius: BorderRadius.circular(20),
                    border: sel ? Border.all(color: _hasBg ? Colors.white54 : cs.primary, width: 1.5) : null),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(t['icon'] as IconData, size: 16, color: sel ? (_hasBg ? Colors.white : cs.primary) : (_hasBg ? Colors.white60 : Colors.grey)),
                    const SizedBox(width: 6),
                    Text(t['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? (_hasBg ? Colors.white : cs.primary) : (_hasBg ? Colors.white60 : Colors.grey[600])))]))));}))),
          const SizedBox(height: 24),
          const WhiteNoiseMixer(),
          const SizedBox(height: 40),
        ])))]),
    );
  }

  Widget _circBtn(IconData ic, VoidCallback onTap, double sz) => GestureDetector(onTap: onTap,
    child: Container(width: sz, height: sz,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _hasBg ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(30)),
      child: Icon(ic, size: sz * 0.45, color: _hasBg ? Colors.white60 : Colors.grey[400])));
}

class _TaskSelector extends StatelessWidget {
  final bool enabled; final StudyTask? linkedTask;
  final void Function(StudyTask) onSelect; final VoidCallback onClear;
  const _TaskSelector({required this.enabled, required this.linkedTask, required this.onSelect, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks.where((t) => !t.isCompleted).toList();
    if (linkedTask != null) return Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF5856D6).withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.book_rounded, size: 16, color: Color(0xFF5856D6))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Studying', style: TextStyle(fontSize: 11, color: Colors.grey)),
          Text(linkedTask!.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)])),
        if (enabled) GestureDetector(onTap: onClear, child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400]))])));
    if (!enabled || tasks.isEmpty) return const SizedBox.shrink();
    return GestureDetector(onTap: () => _showPicker(context, tasks),
      child: Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 10), Text('Link to a task', style: TextStyle(fontSize: 14, color: Colors.grey[500]))]))));
  }

  void _showPicker(BuildContext context, List<StudyTask> tasks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Select Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: tasks.take(8).map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF5856D6).withAlpha(15), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.checklist_rounded, size: 18, color: Color(0xFF5856D6))),
                      title: Text(t.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      subtitle: Text(t.subject, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      onTap: () { onSelect(t); Navigator.pop(ctx); }
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
