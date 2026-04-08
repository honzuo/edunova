class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  double get progress =>
      targetValue == 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['icon_name'] as String? ?? 'emoji_events',
      targetValue: (map['target_value'] as num?)?.toInt() ?? 0,
      currentValue: (map['current_value'] as num?)?.toInt() ?? 0,
      isUnlocked: map['is_unlocked'] == 1 || map['is_unlocked'] == true,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.tryParse(map['unlocked_at'] as String)
          : null,
    );
  }
}
