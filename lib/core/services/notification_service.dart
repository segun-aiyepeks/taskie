import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taskie/core/router/app_router.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/models/timetable_entry.dart';
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_strings.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _exactAlarmPermissionPrompted = false;
  static const _alarmSound = UriAndroidNotificationSound(
    'content://settings/system/alarm_alert',
  );
  static const _testChannelId = 'taskie_alarm_test_v2';

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

    // Android locks channel sound and importance when a channel is first
    // created, so this uses a new channel ID to upgrade existing installs.
    const channel = AndroidNotificationChannel(
      AppStrings.notifChannelId,
      AppStrings.notifChannelName,
      description: AppStrings.notifChannelDesc,
      importance: Importance.max,
      playSound: true,
      sound: _alarmSound,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const testChannel = AndroidNotificationChannel(
      _testChannelId,
      'Test Alarm Reminders',
      description: 'Alarm ringtone used to verify Taskie reminders',
      importance: Importance.max,
      playSound: true,
      sound: _alarmSound,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(testChannel);

    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidNotifications =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> requestPermissions() async {
    if (!await _ensureNotificationPermission(requestIfNeeded: true)) {
      return false;
    }
    return requestExactAlarmPermission();
  }

  Future<bool> requestExactAlarmPermission() async {
    final android = _androidNotifications;
    if (android == null) return true;

    if (await android.canScheduleExactNotifications() == true) return true;
    await android.requestExactAlarmsPermission();
    return await android.canScheduleExactNotifications() ?? false;
  }

  Future<bool> _ensureNotificationPermission({
    required bool requestIfNeeded,
  }) async {
    final android = _androidNotifications;
    if (android == null) return true;

    final enabled = await android.areNotificationsEnabled();
    if (enabled == true) return true;
    if (!requestIfNeeded) return false;

    final requested = await android.requestNotificationsPermission();
    return requested ?? await android.areNotificationsEnabled() ?? false;
  }

  Future<AndroidScheduleMode> _scheduleMode({
    required bool requestIfNeeded,
  }) async {
    final android = _androidNotifications;
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;

    var canScheduleExactly = await android.canScheduleExactNotifications();
    if (canScheduleExactly != true &&
        requestIfNeeded &&
        !_exactAlarmPermissionPrompted) {
      _exactAlarmPermissionPrompted = true;
      await android.requestExactAlarmsPermission();
      canScheduleExactly = await android.canScheduleExactNotifications();
    }

    // Keep reminders working if the user declines exact-alarm access. Android
    // may deliver these a little late while the device is idle.
    return canScheduleExactly == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  // ── Notification tap handler ─────────────────────────────
  // Called when the user taps the notification.
  // The payload is the task ID as a string or schedule:entryId.
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      if (payload.startsWith('schedule:')) {
        appRouter.go('/');
      } else {
        appRouter.push('/task/$payload');
      }
    }
  }

  // ── Schedule ─────────────────────────────────────────────
  Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required DateTime dueDate,
    bool requestPermissions = true,
  }) async {
    try {
      // Cancel first so removing/changing a due date cannot leave an old alarm.
      await _plugin.cancel(id: taskId);
      if (dueDate.isBefore(DateTime.now())) return;
      await _ensureNotificationPermission(
        requestIfNeeded: requestPermissions,
      );

      final androidDetails = _alarmNotificationDetails(
        AppStrings.notifChannelId,
        AppStrings.notifChannelName,
        title: taskTitle,
        body: AppStrings.notifBody,
      );
      final scheduledTz = tz.TZDateTime.from(dueDate, tz.local);

      await _plugin.zonedSchedule(
        id: taskId,
        title: taskTitle,
        body: AppStrings.notifBody,
        scheduledDate: scheduledTz,
        notificationDetails: NotificationDetails(android: androidDetails),
        payload: taskId.toString(),
        androidScheduleMode: await _scheduleMode(
          requestIfNeeded: requestPermissions,
        ),
      );
      debugPrint('Scheduled alarm reminder for task $taskId at $scheduledTz.');
    } catch (e) {
      debugPrint('Failed to schedule task reminder $taskId: $e');
    }
  }

  // ── Cancel one ───────────────────────────────────────────
  Future<void> cancelTaskNotification(int taskId) async {
    await _plugin.cancel(id: taskId);
  }

  // ── Cancel all (useful for testing or account reset) ─────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Schedule a weekly alarm for each selected day of a high-priority entry.
  Future<void> scheduleWeeklyTimetableReminder({
    required int entryId,
    required int dayOfWeek,
    required String title,
    required int startMinutes,
    bool requestPermissions = true,
  }) async {
    if (dayOfWeek < DateTime.monday || dayOfWeek > DateTime.sunday) return;
    if (startMinutes < 0 || startMinutes >= 24 * 60) return;

    try {
      await _ensureNotificationPermission(
        requestIfNeeded: requestPermissions,
      );

      final scheduledTime = _nextWeekdayTime(dayOfWeek, startMinutes);
      final notifId = entryId * 1000 + dayOfWeek;
      final body = 'Your scheduled entry is starting now.';
      final details = _alarmNotificationDetails(
        AppStrings.notifChannelId,
        AppStrings.notifChannelName,
        title: title,
        body: body,
      );

      await _plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: NotificationDetails(android: details),
        payload: 'schedule:$entryId',
        androidScheduleMode: await _scheduleMode(
          requestIfNeeded: requestPermissions,
        ),
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint('Scheduled alarm reminder for entry $entryId on weekday $dayOfWeek at $scheduledTime.');
    } catch (e) {
      debugPrint('Failed to schedule timetable reminder $entryId: $e');
    }
  }

  Future<void> cancelTimetableNotification(int entryId) async {
    for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
      await _plugin.cancel(id: entryId * 1000 + day);
    }
  }

  /// Recreates reminders saved by earlier app versions on the alarm channel.
  /// Permission prompts are avoided during startup; exact alarms fall back to
  /// inexact delivery if Android access has not been granted yet.
  Future<void> restoreSavedReminders({
    required List<Task> tasks,
    required List<TimetableEntry> timetableEntries,
  }) async {
    for (final task in tasks) {
      final dueDate = task.dueDate;
      if (!task.isPending || dueDate == null) {
        await cancelTaskNotification(task.id);
        continue;
      }

      await scheduleTaskReminder(
        taskId: task.id,
        taskTitle: task.title,
        dueDate: dueDate,
        requestPermissions: false,
      );
    }

    for (final entry in timetableEntries) {
      await cancelTimetableNotification(entry.id);
      if (!entry.isHighPriority) continue;

      for (final day in entry.daysOfWeek) {
        await scheduleWeeklyTimetableReminder(
          entryId: entry.id,
          dayOfWeek: day,
          title: entry.title,
          startMinutes: entry.startMinutes,
          requestPermissions: false,
        );
      }
    }
  }

  Future<bool> sendTestNotification() async {
    try {
      if (!await _ensureNotificationPermission(requestIfNeeded: true)) {
        return false;
      }

      final scheduledTime = tz.TZDateTime.now(tz.local).add(
        const Duration(seconds: 10),
      );
      final details = _alarmNotificationDetails(
        _testChannelId,
        'Test Alarm Reminders',
        title: 'Notifications working!',
        body: 'Taskie is using your device alarm ringtone for reminders.',
      );

      await _plugin.zonedSchedule(
        id: 99999,
        title: 'Notifications working!',
        body: 'Taskie is using your device alarm ringtone for reminders.',
        scheduledDate: scheduledTime,
        notificationDetails: NotificationDetails(android: details),
        androidScheduleMode: await _scheduleMode(requestIfNeeded: true),
      );
      debugPrint('Test alarm reminder scheduled for $scheduledTime.');
      return true;
    } catch (e) {
      debugPrint('Failed to schedule test alarm reminder: $e');
      return false;
    }
  }

  AndroidNotificationDetails _alarmNotificationDetails(
    String channelId,
    String channelName, {
    required String title,
    required String body,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: AppStrings.notifChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: _alarmSound,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );
  }

  tz.TZDateTime _nextWeekdayTime(int dayOfWeek, int startMinutes) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = startMinutes ~/ 60;
    final minute = startMinutes % 60;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != dayOfWeek || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
