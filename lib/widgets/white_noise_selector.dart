/// white_noise_selector.dart — Ambient sound mixer widget.
///
/// Provides toggle controls for 6 ambient sounds (rain, cafe,
/// fire, forest, ocean, library) with individual volume sliders.
/// Sounds play simultaneously using [AudioService].
/// Used on the Pomodoro screen for focus enhancement.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_service.dart';

/// Full sound mixer: toggle multiple sounds, adjust individual volumes.
class WhiteNoiseMixer extends StatefulWidget {
  const WhiteNoiseMixer({super.key});
  @override
  State<WhiteNoiseMixer> createState() => _WhiteNoiseMixerState();
}

class _WhiteNoiseMixerState extends State<WhiteNoiseMixer> {
  final AudioService _audio = AudioService();

  static const _sounds = [
    ('rain', Icons.water_drop_rounded, 'Rain', Color(0xFF5AC8FA)),
    ('cafe', Icons.local_cafe_rounded, 'Café', Color(0xFFFF9500)),
    ('fire', Icons.local_fire_department_rounded, 'Fire', Color(0xFFFF3B30)),
    ('forest', Icons.forest_rounded, 'Forest', Color(0xFF34C759)),
    ('ocean', Icons.waves_rounded, 'Ocean', Color(0xFF5856D6)),
    ('library', Icons.menu_book_rounded, 'Library', Color(0xFFAF52DE)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = _audio.activeSounds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Sound Mixer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: Colors.grey[500], letterSpacing: 0.3)),
            const Spacer(),
            if (active.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  await _audio.stopAll();
                  setState(() {});
                },
                child: Text('Stop All',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: cs.primary)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Sound Tiles ──
        ...(_sounds.map((s) {
          final id = s.$1;
          final icon = s.$2;
          final label = s.$3;
          final color = s.$4;
          final isActive = active.contains(id);
          final volume = _audio.getVolume(id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withAlpha(15)
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? color.withAlpha(80) : Colors.grey.withAlpha(30),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  // ── Header Row: icon + label + toggle ──
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await _audio.toggle(id);
                      setState(() {});
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: color.withAlpha(isActive ? 30 : 15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 16, color: isActive ? color : Colors.grey[500]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label, style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: isActive ? color : null,
                          )),
                        ),
                        // Animated play/stop indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? color : Colors.grey.withAlpha(30),
                          ),
                          child: Icon(
                            isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 16,
                            color: isActive ? Colors.white : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Volume Slider (visible when active) ──
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.volume_down_rounded, size: 16, color: Colors.grey[400]),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: color,
                                thumbColor: color,
                                inactiveTrackColor: color.withAlpha(30),
                                overlayColor: color.withAlpha(20),
                              ),
                              child: Slider(
                                value: volume,
                                min: 0, max: 1,
                                onChanged: (v) {
                                  _audio.setVolume(id, v);
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          Icon(Icons.volume_up_rounded, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${(volume * 100).round()}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: isActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              ),
            ),
          );
        })),
      ],
    );
  }
}
