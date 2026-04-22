/// calender_event.dart — Data model for calendar event display.
///
/// Used to represent tasks and sessions on the calendar view.
/// Not persisted directly — constructed from task/session data.

class CalendarEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final String eventType; // task / session / reminder / pomodoro
  final int? relatedTaskId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.eventType,
    this.relatedTaskId,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? eventType,
    int? relatedTaskId,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      eventType: eventType ?? this.eventType,
      relatedTaskId: relatedTaskId ?? this.relatedTaskId,
    );
  }
}