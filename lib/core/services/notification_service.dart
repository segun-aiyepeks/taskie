import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taskie/core/router/app_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
    tz.initializeTimeZones();

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
}

// Global navigator key — declared here so _onNotificationTap can reach it.
// We'll assign it to MaterialApp.router in app.dart next.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();