import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    // 设置本地时区
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
      final implementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // 请求 Android 13+ 通知权限
      await implementation?.requestNotificationsPermission();
      // 请求 Android 12+ 精确闹钟权限
      await implementation?.requestExactAlarmsPermission();

      debugPrint('Notification Service Initialized');
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
      // 将 DateTime 转换为 TZDateTime
      final scheduledDate = tz.TZDateTime.from(triggerTime, tz.local);

      // 验证时间是否在未来
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('Error: Trigger time is in the past.');
        return;
      }

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
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // 使用 exactAllowWhileIdle 确保在 Android 12+ 上准时弹出
        // 注意：此处已移除导致报错的 uiLocalNotificationDateInterpretation 参数
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('Successfully scheduled at: $scheduledDate');
    } catch (e) {
      debugPrint('Schedule notification error: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }
}