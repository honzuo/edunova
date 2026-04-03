import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
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
    final scheduledDate = tz.TZDateTime.from(triggerTime, tz.local);

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
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }
}