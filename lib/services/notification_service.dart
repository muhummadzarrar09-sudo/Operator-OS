import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Replaces the Time class removed from flutter_local_notifications v14+.
class Time {
  final int hour;
  final int minute;
  final int second;
  const Time(this.hour, [this.minute = 0, this.second = 0]);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> scheduleAll({
    required Time fajrTime,
    Time? bedtimeTime,
    bool scheduleSlots = true,
    Time slotATime = const Time(9, 0),
    Time slotBTime = const Time(14, 0),
  }) async {
    await cancelAll();

    await _scheduleDaily(
      id: 1,
      title: 'Fajr Wake',
      body: 'Write today\'s 3 quests (CLARITY)',
      time: fajrTime,
    );

    if (bedtimeTime != null) {
      await _scheduleDaily(
        id: 2,
        title: 'Bedtime',
        body: 'Time for bed. Stay on target for Recovery XP.',
        time: bedtimeTime,
      );
    }

    if (scheduleSlots) {
      const weekdays = [1, 2, 3, 4, 5, 6]; // Mon-Sat
      for (final day in weekdays) {
        await _scheduleWeekly(
          id: 10 + day,
          title: 'Slot A',
          body: 'Start your Slot A focus block.',
          time: slotATime,
          weekday: day,
        );
        await _scheduleWeekly(
          id: 20 + day,
          title: 'Slot B',
          body: 'Start your Slot B focus block.',
          time: slotBTime,
          weekday: day,
        );
      }
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required Time time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'operator_os_channel',
          'Operator OS',
          channelDescription: 'Daily reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required Time time,
    required int weekday,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'operator_os_channel',
          'Operator OS',
          channelDescription: 'Daily reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
