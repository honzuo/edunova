/// user_preference.dart — Data model for user preference settings.
///
/// Maps to the [user_preferences] table. Stores dark mode toggle,
/// notification preferences, and default reminder type.

class UserPreference {
  final int? id;
  final String userId;
  final bool darkMode;
  final bool notificationEnabled;
  final String defaultReminderType;
  final bool dailySummaryEnabled;

  UserPreference({
    this.id,
    required this.userId,
    required this.darkMode,
    required this.notificationEnabled,
    required this.defaultReminderType,
    required this.dailySummaryEnabled,
  });

  UserPreference copyWith({
    int? id,
    String? userId,
    bool? darkMode,
    bool? notificationEnabled,
    String? defaultReminderType,
    bool? dailySummaryEnabled,
  }) {
    return UserPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      darkMode: darkMode ?? this.darkMode,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      defaultReminderType: defaultReminderType ?? this.defaultReminderType,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'dark_mode': darkMode ? 1 : 0,
      'notification_enabled': notificationEnabled ? 1 : 0,
      'default_reminder_type': defaultReminderType,
      'daily_summary_enabled': dailySummaryEnabled ? 1 : 0,
    };
  }

  factory UserPreference.fromMap(Map<String, dynamic> map) {
    return UserPreference(
      id: (map['id'] as num?)?.toInt(),
      userId: map['user_id'] as String? ?? '',
      darkMode: map['dark_mode'] == 1 || map['dark_mode'] == true,
      notificationEnabled: map['notification_enabled'] == 1 ||
          map['notification_enabled'] == true,
      defaultReminderType:
      map['default_reminder_type'] as String? ?? '1 hour before',
      dailySummaryEnabled: map['daily_summary_enabled'] == 1 ||
          map['daily_summary_enabled'] == true,
    );
  }
}