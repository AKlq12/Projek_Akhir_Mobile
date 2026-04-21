/// Notification settings model that maps to the `notification_settings` table.
///
/// Stores per-user notification preferences: workout reminders, time, step goal.
class NotificationSettingsModel {
  final String id;
  final String userId;
  final bool workoutReminder;
  final String reminderTime; // 'HH:mm' format
  final int stepGoal;

  const NotificationSettingsModel({
    required this.id,
    required this.userId,
    this.workoutReminder = true,
    this.reminderTime = '08:00',
    this.stepGoal = 10000,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutReminder: json['workout_reminder'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String? ?? '08:00',
      stepGoal: json['step_goal'] as int? ?? 10000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'workout_reminder': workoutReminder,
      'reminder_time': reminderTime,
      'step_goal': stepGoal,
    };
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'user_id': userId,
      'workout_reminder': workoutReminder,
      'reminder_time': reminderTime,
      'step_goal': stepGoal,
    };
  }

  NotificationSettingsModel copyWith({
    String? id,
    String? userId,
    bool? workoutReminder,
    String? reminderTime,
    int? stepGoal,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutReminder: workoutReminder ?? this.workoutReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      stepGoal: stepGoal ?? this.stepGoal,
    );
  }

  /// Default settings for new users.
  static NotificationSettingsModel defaults(String userId) {
    return NotificationSettingsModel(
      id: '',
      userId: userId,
      workoutReminder: true,
      reminderTime: '08:00',
      stepGoal: 10000,
    );
  }

  @override
  String toString() =>
      'NotificationSettingsModel(userId: $userId, reminder: $workoutReminder, time: $reminderTime)';
}
