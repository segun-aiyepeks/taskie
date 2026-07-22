import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taskie/core/router/app_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../constants/app_strings.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Initialization ───────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization settings.
    // 'app_icon' refers to the drawable resource name — we'll add this below.
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings    = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Initialize timezone data for zonedSchedule usage.
    tz_data.initializeTimeZones();

    // Create the notification channel on Android 8.0+.
    // Channels control sound, vibration, and importance — users can
    // manage them individually in their device's notification settings.
    const channel = AndroidNotificationChannel(
      AppStrings.notifChannelId,
      AppStrings.notifChannelName,
      description: AppStrings.notifChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request the POST_NOTIFICATIONS permission (Android 13+).
    // On older versions this is a no-op.
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation
        <AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // ── Notification tap handler ─────────────────────────────
  // Called when the user taps the notification.
  // The payload is the task ID as a string.
  static void _onNotificationTap(NotificationResponse response) {
    // Navigation from outside the widget tree requires a global navigator key.
    // We'll wire this up in main.dart in the next sub-step.
    final taskId = response.payload;
    if (taskId != null && taskId.isNotEmpty) {
      appRouter.push('task/taskId');
    }
  }

  // ── Schedule ─────────────────────────────────────────────
  Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    // Don't schedule for past due dates or tasks due within 60 seconds —
    // an immediate notification for something already overdue is noise.
    if (dueDate.isBefore(
          DateTime.now().add(const Duration(seconds: 60)),
        )) return;

    // Schedule for 9 AM on the due date, or the exact due time if the
    // user has set a specific time (we store date-only for now, so
    // default to 9 AM of the due day).
    final scheduledTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9, // 9:00 AM
    );

    // Skip if 9 AM has already passed today
    if (scheduledTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      AppStrings.notifChannelId,
      AppStrings.notifChannelName,
      channelDescription: AppStrings.notifChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        AppStrings.notifBody,
        contentTitle: taskTitle,
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    // task.id is the unique Isar int ID — reuse it as the notification ID.
    // This means scheduling for the same task again REPLACES the old
    // notification automatically (same ID = overwrite). Perfect for edits.
    // Use zonedSchedule which is the current API for scheduled notifications.
    final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id: taskId,
      title: taskTitle,
      body:  AppStrings.notifBody,
      scheduledDate: scheduledTz,
      notificationDetails: details,
      payload: taskId.toString(),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  // ── Cancel one ───────────────────────────────────────────
  Future<void> cancelTaskNotification(int taskId) async {
    await _plugin.cancel(id: taskId);
  }

  // ── Cancel all (useful for testing or account reset) ─────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Schedules a weekly recurring notification for a high-priority
// timetable entry. Fires every week on the same day at the same time.
Future<void> scheduleWeeklyTimetableReminder({
  required int    entryId,
  required int    dayOfWeek,    // 1=Mon … 7=Sun
  required String title,
  required int    startMinutes, // minutes from midnight
}) async {
  final scheduledTime = _nextWeekdayTime(dayOfWeek, startMinutes);

  // Skip if the next occurrence is in the past
  if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

  final androidDetails = AndroidNotificationDetails(
    AppStrings.notifChannelId,
    AppStrings.notifChannelName,
    channelDescription: AppStrings.notifChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
    styleInformation: BigTextStyleInformation(
      'Your high-priority schedule entry is starting now.',
      contentTitle: title,
    ),
  );

  // Use entryId * 1000 + dayOfWeek as notification ID.
  // This lets each day of a multi-day entry have its own notification.
  final notifId = entryId * 1000 + dayOfWeek;

  await _plugin.zonedSchedule(
    id: notifId,
    title: '⭐ $title',
    body: 'Your high-priority schedule entry is starting now.',
    scheduledDate: scheduledTime,
    notificationDetails: NotificationDetails(android: androidDetails),
    payload: 'schedule:$entryId',
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    // This is the magic — makes it repeat every week on the same
    // day and time without rescheduling manually
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

// Cancels all notifications for a timetable entry across all days
Future<void> cancelTimetableNotification(int entryId) async {
  // Cancel for all 7 possible days
  for (int day = 1; day <= 7; day++) {
    await _plugin.cancel(id: entryId * 1000 + day);
  }
}

// Returns the next TZDateTime for a given weekday and time
tz.TZDateTime _nextWeekdayTime(int dayOfWeek, int startMinutes) {
  final now    = tz.TZDateTime.now(tz.local);
  final hour   = startMinutes ~/ 60;
  final minute = startMinutes % 60;

  // Start from today at the target time
  var scheduled = tz.TZDateTime(
    tz.local, now.year, now.month, now.day, hour, minute,
  );

  // Advance day by day until we land on the right weekday
  // and the time hasn't passed yet today
  while (scheduled.weekday != dayOfWeek ||
         scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  return scheduled;
}
}

// Global navigator key — declared here so _onNotificationTap can reach it.
// We'll assign it to MaterialApp.router in app.dart next.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();