import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles all local notification logic for FitPro:
/// - Workout reminder (scheduled daily)
/// - Step goal achievement
/// - Workout completion congratulation
///
/// Uses `flutter_local_notifications` with Android notification channels.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION CHANNELS (Android)
  // ─────────────────────────────────────────────────────────────────────────
  static const String _workoutChannelId = 'fitpro_workout_reminder';
  static const String _workoutChannelName = 'Workout Reminders';
  static const String _workoutChannelDesc =
      'Daily workout reminder notifications';

  static const String _achievementChannelId = 'fitpro_achievements';
  static const String _achievementChannelName = 'Achievements';
  static const String _achievementChannelDesc =
      'Step goals and workout completion notifications';

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION IDs
  // ─────────────────────────────────────────────────────────────────────────
  static const int _workoutReminderId = 1001;
  static const int _stepGoalId = 1002;
  static const int _workoutCompleteId = 1003;
  static const int _testReminderId = 1004;

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Initializes the notification plugin and timezone data.
  ///
  /// Must be called once at app startup (e.g. in main.dart).
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database and set local timezone
    tz.initializeTimeZones();
    _setLocalTimeZone();

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channels explicitly
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Create workout reminder channel
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _workoutChannelId,
          _workoutChannelName,
          description: _workoutChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Create achievements channel
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _achievementChannelId,
          _achievementChannelName,
          description: _achievementChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Request POST_NOTIFICATIONS permission (Android 13+)
      final notifGranted = await android?.requestNotificationsPermission();
      debugPrint(
        '[NotificationService] POST_NOTIFICATIONS permission: $notifGranted',
      );

      // Request SCHEDULE_EXACT_ALARM permission (Android 12+)
      // This opens system settings for user to grant the permission
      final canScheduleExact =
          await android?.canScheduleExactNotifications() ?? false;
      debugPrint(
        '[NotificationService] canScheduleExactNotifications: $canScheduleExact',
      );
      if (!canScheduleExact) {
        await android?.requestExactAlarmsPermission();
      }
    }

    _initialized = true;
    debugPrint('[NotificationService] Initialized successfully');
  }

  /// Sets [tz.local] to the device's actual timezone.
  ///
  /// Without this, [tz.local] defaults to UTC, causing scheduled
  /// notification times to be interpreted in the wrong timezone.
  void _setLocalTimeZone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Preferred timezone names by UTC offset (Indonesia-focused)
      const preferredByOffsetHours = <int, String>{
        7: 'Asia/Jakarta', // WIB
        8: 'Asia/Makassar', // WITA
        9: 'Asia/Jayapura', // WIT
        5: 'Asia/Karachi',
        -5: 'America/New_York',
        -8: 'America/Los_Angeles',
        0: 'Europe/London',
        1: 'Europe/Paris',
      };

      // Try preferred timezone first
      final preferredName = preferredByOffsetHours[offset.inHours];
      if (preferredName != null) {
        try {
          final loc = tz.getLocation(preferredName);
          tz.setLocalLocation(loc);
          debugPrint(
            '[NotificationService] Local timezone set to: $preferredName (offset: $offset)',
          );
          return;
        } catch (_) {
          // Preferred name not found in database, fall through to search
        }
      }

      // Fallback: search for any timezone matching the offset
      for (final entry in tz.timeZoneDatabase.locations.entries) {
        final loc = entry.value;
        final tzNow = tz.TZDateTime.now(loc);
        if (tzNow.timeZoneOffset == offset) {
          tz.setLocalLocation(loc);
          debugPrint(
            '[NotificationService] Local timezone set to: ${entry.key} (offset: $offset)',
          );
          return;
        }
      }

      // Last fallback: log warning but continue (tz.local stays UTC)
      debugPrint(
        '[NotificationService] WARNING: Could not find timezone for offset $offset, using UTC',
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to set local timezone: $e');
    }
  }

  /// Called when user taps a notification.
  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
      '[NotificationService] Tapped notification: ${response.payload}',
    );
    // Navigation can be handled here if needed
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKOUT REMINDER (Scheduled Daily)
  // ─────────────────────────────────────────────────────────────────────────

  /// Schedules a daily workout reminder at the given [hour] and [minute].
  ///
  /// Cancels any existing reminder before scheduling a new one.
  /// Falls back to inexact scheduling if exact alarm permission is not granted.
  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await init();

    // Cancel existing reminder first
    await cancelWorkoutReminder();

    final scheduledTime = _nextInstanceOfTime(hour, minute);

    const androidDetails = AndroidNotificationDetails(
      _workoutChannelId,
      _workoutChannelName,
      channelDescription: _workoutChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Time to crush your workout! 💪 Your body is ready — let\'s make today count.',
        contentTitle: '🏋️ Workout Time!',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Determine the best schedule mode based on permission availability
    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canExact =
          await android?.canScheduleExactNotifications() ?? false;
      if (canExact) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }
      debugPrint(
        '[NotificationService] Using schedule mode: $scheduleMode (canExact: $canExact)',
      );
    }

    try {
      await _plugin.zonedSchedule(
        _workoutReminderId,
        '🏋️ Workout Time!',
        'Time to crush your workout! 💪 Your body is ready — let\'s make today count.',
        scheduledTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      );

      debugPrint(
        '[NotificationService] Workout reminder scheduled at $hour:$minute',
      );

      // Verify the notification was actually scheduled
      final pending = await _plugin.pendingNotificationRequests();
      final found = pending.any((n) => n.id == _workoutReminderId);
      debugPrint(
        '[NotificationService] Pending notifications: ${pending.length}, '
        'workout reminder found: $found',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] ERROR scheduling workout reminder: $e',
      );
      // If zonedSchedule fails completely, try inexact as last resort
      try {
        await _plugin.zonedSchedule(
          _workoutReminderId,
          '🏋️ Workout Time!',
          'Time to crush your workout! 💪 Your body is ready — let\'s make today count.',
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint(
          '[NotificationService] Fallback: scheduled with inexact mode',
        );
      } catch (e2) {
        debugPrint(
          '[NotificationService] CRITICAL: Even inexact scheduling failed: $e2',
        );
      }
    }
  }

  /// Cancels the scheduled daily workout reminder.
  Future<void> cancelWorkoutReminder() async {
    await _plugin.cancel(_workoutReminderId);
    debugPrint('[NotificationService] Workout reminder cancelled');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEST SCHEDULED NOTIFICATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Schedules a test notification [seconds] from now to verify that
  /// scheduled notifications actually fire on this device.
  Future<void> scheduleTestNotification({int seconds = 5}) async {
    if (!_initialized) await init();

    // Cancel any previous test notification
    await _plugin.cancel(_testReminderId);

    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    const androidDetails = AndroidNotificationDetails(
      _workoutChannelId,
      _workoutChannelName,
      channelDescription: _workoutChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Try inexact first (doesn't need special permission)
    try {
      await _plugin.zonedSchedule(
        _testReminderId,
        '🏋️ Workout Time!',
        'Time to crush your workout! 💪 Your body is ready — let\'s make today count.',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        '[NotificationService] Test notification scheduled for $scheduledTime '
        '(${seconds}s from now)',
      );
    } catch (e) {
      debugPrint('[NotificationService] ERROR scheduling test: $e');
      // Last resort: show immediately
      await _plugin.show(
        _testReminderId,
        '🏋️ Workout Time!',
        'Time to crush your workout! 💪 Your body is ready — let\'s make today count.',
        details,
        payload: 'test_workout',
      );
      debugPrint(
        '[NotificationService] Fallback: showed instant notification instead',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP GOAL ACHIEVEMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Shows an instant notification when the user reaches their step goal.
  Future<void> showStepGoalAchieved({required int steps}) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _achievementChannelId,
      _achievementChannelName,
      channelDescription: _achievementChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Amazing! You\'ve hit your daily step goal. Keep up the great work and stay active! 🎯',
        contentTitle: '🎉 Step Goal Reached!',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _stepGoalId,
      '🎉 Step Goal Reached!',
      'You\'ve walked $steps steps today! Amazing work! 🏆',
      details,
      payload: 'step_goal',
    );

    debugPrint('[NotificationService] Step goal notification shown: $steps');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKOUT COMPLETION
  // ─────────────────────────────────────────────────────────────────────────

  /// Shows an instant notification congratulating the user on completing
  /// a workout session.
  Future<void> showWorkoutCompleted({
    required String workoutName,
    required int durationMinutes,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _achievementChannelId,
      _achievementChannelName,
      channelDescription: _achievementChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _workoutCompleteId,
      '🔥 Workout Complete!',
      'Great job finishing "$workoutName"! ${durationMinutes}min of pure effort. Keep the streak going! 💪',
      details,
      payload: 'workout_complete',
    );

    debugPrint(
      '[NotificationService] Workout completion notification: $workoutName',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITY
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the next occurrence of [hour]:[minute] in the local timezone.
  ///
  /// Constructs the time directly as [tz.TZDateTime] in [tz.local] to ensure
  /// the hour and minute represent actual local time.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint(
      '[NotificationService] Next reminder at: $scheduledDate (tz: ${tz.local.name})',
    );
    return scheduledDate;
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  /// Returns a list of pending notification requests (for debugging).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }
}
