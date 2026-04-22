import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );

    try {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      debugPrint('Notification permission granted: $granted');
      debugPrint('Timezone local: ${tz.local.name}');
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }
  }

  Future<void> showNow({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'edunova_now',
          'Immediate Notifications',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime triggerTime,
  }) async {
    try {
      debugPrint('========== SCHEDULE REMINDER ==========');
      debugPrint('Now: ${DateTime.now()}');
      debugPrint('TriggerTime: $triggerTime');
      debugPrint('tz.local: ${tz.local.name}');

      final scheduledDate = tz.TZDateTime.from(triggerTime, tz.local);
      debugPrint('ScheduledDate: $scheduledDate');

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'edunova_reminders',
            'Study Reminders',
            channelDescription: 'Reminder notifications for study tasks',
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('Pending count: ${pending.length}');
      for (final p in pending) {
        debugPrint('Pending -> ${p.id}, ${p.title}, ${p.body}');
      }
    } catch (e) {
      debugPrint('Schedule notification error: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }
}