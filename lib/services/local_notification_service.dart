import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Phase 2: simple daily local reminder.
///
/// - Once per day at 8:00 PM (local timezone)
/// - No XP-based logic
/// - No Firestore writes
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const int _dailyReminderId = 9001;
  static const String _channelId = 'daily_learning_reminder';
  static const String _channelName = 'Daily Learning Reminder';
  static const String _channelDescription = 'Daily reminder to nudge learning.';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone is required for zonedSchedule.
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );

    await _plugin.initialize(initSettings);

    // Android 13+ runtime notification permission
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> scheduleDailyReminder({
    String title = 'Mindful App',
    String body = '5 minutes of learning today?',
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    final scheduled = _nextInstanceOfEightPm();

    // Overwrite the same ID so we never create duplicates.
    //
    // NOTE:
    // On Android 12+ (especially Android 14/15), using an *exact* schedule
    // requires the SCHEDULE_EXACT_ALARM permission / user approval.
    // If the app doesn't have it, flutter_local_notifications can throw:
    //   PlatformException(exact_alarms_not_permitted, ...)
    //
    // To avoid crashing the app at startup, we use an inexact schedule.
    // (Real fix: if you truly need exact delivery, request exact alarm
    // permission and declare it in AndroidManifest.)
    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to schedule daily reminder: ${e.code} ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to schedule daily reminder: $e');
      }
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('Scheduled daily reminder at: $scheduled');
    }
  }

  tz.TZDateTime _nextInstanceOfEightPm() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}


