import 'package:flutter/material.dart';

class WhiteNoiseSelector extends StatefulWidget {
  final void Function(String? selectedNoise) onChanged;
  const WhiteNoiseSelector({super.key, required this.onChanged});
  @override
  State<WhiteNoiseSelector> createState() => _WhiteNoiseSelectorState();
}

class _WhiteNoiseSelectorState extends State<WhiteNoiseSelector> {
  String? _selected;

  static const _noises = [
    ('rain', Icons.water_drop_rounded, 'Rain'),
    ('cafe', Icons.local_cafe_rounded, 'Café'),
    ('fire', Icons.local_fire_department_rounded, 'Fire'),
    ('forest', Icons.forest_rounded, 'Forest'),
    ('ocean', Icons.waves_rounded, 'Ocean'),
    ('library', Icons.menu_book_rounded, 'Library'),
  ];

  void _toggle(String id) {
    setState(() => _selected = _selected == id ? null : id);
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Background Sound',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.3)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: _noises.map((n) {
        final active = _selected == n.$1;
        return GestureDetector(
          onTap: () => _toggle(n.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primary.withAlpha(20)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? Theme.of(context).colorScheme.primary : Colors.grey.withAlpha(40),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(n.$2, size: 16, color: active ? Theme.of(context).colorScheme.primary : Colors.grey[500]),
              const SizedBox(width: 6),
              Text(n.$3, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: active ? Theme.of(context).colorScheme.primary : null,
              )),
            ]),
          ),
        );
      }).toList()),
    ]);
  }
}
