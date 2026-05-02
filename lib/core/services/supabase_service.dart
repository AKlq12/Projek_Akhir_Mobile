import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/feedback_model.dart';
import '../models/favorite_exercise_model.dart';
import '../models/notification_settings_model.dart';
import '../models/plan_exercise_model.dart';
import '../models/step_log_model.dart';
import '../models/workout_log_model.dart';
import '../models/workout_plan_model.dart';

/// Centralized Supabase database service for all FitPro tables.
///
/// Provides CRUD operations for:
/// - Workout logs
/// - Workout plans & plan exercises
/// - Favorite exercises
/// - Step logs
/// - Saran & Kesan
/// - Notification settings
///
/// All queries are scoped to the authenticated user via RLS policies.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final _client = Supabase.instance.client;

  /// Helper to get the current user's ID.
  String? get _userId => _client.auth.currentUser?.id;

  void _requireAuth() {
    if (_userId == null) {
      throw Exception('User must be authenticated to perform this action.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKOUT LOGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches all workout logs for the current user, newest first.
  Future<List<WorkoutLogModel>> getWorkoutLogs({
    int? limit,
    int? offset,
  }) async {
    _requireAuth();
    var query = _client
        .from('workout_logs')
        .select()
        .eq('user_id', _userId!)
        .order('performed_at', ascending: false);

    if (limit != null) query = query.limit(limit);
    if (offset != null) query = query.range(offset, offset + (limit ?? 20) - 1);

    final data = await query;
    return data.map((row) => WorkoutLogModel.fromJson(row)).toList();
  }

  /// Fetches workout logs for a specific date range.
  Future<List<WorkoutLogModel>> getWorkoutLogsByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    _requireAuth();
    final data = await _client
        .from('workout_logs')
        .select()
        .eq('user_id', _userId!)
        .gte('performed_at', start.toIso8601String())
        .lte('performed_at', end.toIso8601String())
        .order('performed_at', ascending: false);

    return data.map((row) => WorkoutLogModel.fromJson(row)).toList();
  }

  /// Inserts a new workout log.
  Future<WorkoutLogModel> insertWorkoutLog(WorkoutLogModel log) async {
    _requireAuth();
    final data = await _client
        .from('workout_logs')
        .insert(log.toInsertJson())
        .select()
        .single();

    return WorkoutLogModel.fromJson(data);
  }

  /// Updates an existing workout log.
  Future<WorkoutLogModel> updateWorkoutLog(WorkoutLogModel log) async {
    _requireAuth();
    final data = await _client
        .from('workout_logs')
        .update(log.toJson())
        .eq('id', log.id)
        .select()
        .single();

    return WorkoutLogModel.fromJson(data);
  }

  /// Deletes a workout log by ID.
  Future<void> deleteWorkoutLog(String logId) async {
    _requireAuth();
    await _client.from('workout_logs').delete().eq('id', logId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKOUT PLANS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches all workout plans for the current user.
  Future<List<WorkoutPlanModel>> getWorkoutPlans() async {
    _requireAuth();
    final data = await _client
        .from('workout_plans')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return data.map((row) => WorkoutPlanModel.fromJson(row)).toList();
  }

  /// Fetches a single workout plan by ID.
  Future<WorkoutPlanModel> getWorkoutPlan(String planId) async {
    _requireAuth();
    final data = await _client
        .from('workout_plans')
        .select()
        .eq('id', planId)
        .single();

    return WorkoutPlanModel.fromJson(data);
  }

  /// Creates a new workout plan.
  Future<WorkoutPlanModel> insertWorkoutPlan(WorkoutPlanModel plan) async {
    _requireAuth();
    final data = await _client
        .from('workout_plans')
        .insert(plan.toInsertJson())
        .select()
        .single();

    return WorkoutPlanModel.fromJson(data);
  }

  /// Updates an existing workout plan.
  Future<WorkoutPlanModel> updateWorkoutPlan(WorkoutPlanModel plan) async {
    _requireAuth();
    final data = await _client
        .from('workout_plans')
        .update(plan.toJson())
        .eq('id', plan.id)
        .select()
        .single();

    return WorkoutPlanModel.fromJson(data);
  }

  /// Deletes a workout plan (cascade deletes plan_exercises).
  Future<void> deleteWorkoutPlan(String planId) async {
    _requireAuth();
    await _client.from('workout_plans').delete().eq('id', planId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAN EXERCISES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches all exercises for a specific workout plan, sorted by order.
  Future<List<PlanExerciseModel>> getPlanExercises(String planId) async {
    _requireAuth();
    final data = await _client
        .from('plan_exercises')
        .select()
        .eq('plan_id', planId)
        .order('sort_order', ascending: true);

    return data.map((row) => PlanExerciseModel.fromJson(row)).toList();
  }

  /// Adds an exercise to a workout plan.
  Future<PlanExerciseModel> insertPlanExercise(
      PlanExerciseModel exercise) async {
    _requireAuth();
    final data = await _client
        .from('plan_exercises')
        .insert(exercise.toInsertJson())
        .select()
        .single();

    return PlanExerciseModel.fromJson(data);
  }

  /// Updates a plan exercise (e.g. change target sets/reps).
  Future<PlanExerciseModel> updatePlanExercise(
      PlanExerciseModel exercise) async {
    _requireAuth();
    final data = await _client
        .from('plan_exercises')
        .update(exercise.toJson())
        .eq('id', exercise.id)
        .select()
        .single();

    return PlanExerciseModel.fromJson(data);
  }

  /// Removes an exercise from a plan.
  Future<void> deletePlanExercise(String exerciseId) async {
    _requireAuth();
    await _client.from('plan_exercises').delete().eq('id', exerciseId);
  }

  /// Reorders exercises in a plan by updating sort_order.
  Future<void> reorderPlanExercises(List<PlanExerciseModel> exercises) async {
    _requireAuth();
    for (int i = 0; i < exercises.length; i++) {
      await _client
          .from('plan_exercises')
          .update({'sort_order': i})
          .eq('id', exercises[i].id);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAVORITE EXERCISES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches all favorite exercises for the current user.
  Future<List<FavoriteExerciseModel>> getFavoriteExercises() async {
    _requireAuth();
    final data = await _client
        .from('favorite_exercises')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return data.map((row) => FavoriteExerciseModel.fromJson(row)).toList();
  }

  /// Checks if an exercise is favorited.
  Future<bool> isExerciseFavorited(int exerciseId) async {
    _requireAuth();
    final data = await _client
        .from('favorite_exercises')
        .select('id')
        .eq('user_id', _userId!)
        .eq('exercise_id', exerciseId)
        .maybeSingle();

    return data != null;
  }

  /// Adds an exercise to favorites.
  Future<FavoriteExerciseModel> addFavoriteExercise({
    required int exerciseId,
    required String exerciseName,
    String? category,
  }) async {
    _requireAuth();
    final data = await _client
        .from('favorite_exercises')
        .insert({
          'user_id': _userId,
          'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'category': category,
        })
        .select()
        .single();

    return FavoriteExerciseModel.fromJson(data);
  }

  /// Removes an exercise from favorites.
  Future<void> removeFavoriteExercise(int exerciseId) async {
    _requireAuth();
    await _client
        .from('favorite_exercises')
        .delete()
        .eq('user_id', _userId!)
        .eq('exercise_id', exerciseId);
  }

  /// Toggles favorite status and returns the new state.
  Future<bool> toggleFavoriteExercise({
    required int exerciseId,
    required String exerciseName,
    String? category,
  }) async {
    final isFav = await isExerciseFavorited(exerciseId);
    if (isFav) {
      await removeFavoriteExercise(exerciseId);
      return false;
    } else {
      await addFavoriteExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        category: category,
      );
      return true;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP LOGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches today's step log.
  Future<StepLogModel?> getTodayStepLog() async {
    _requireAuth();
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('step_logs')
        .select()
        .eq('user_id', _userId!)
        .eq('date', today)
        .maybeSingle();

    return data != null ? StepLogModel.fromJson(data) : null;
  }

  /// Fetches step logs for a date range.
  Future<List<StepLogModel>> getStepLogs({
    required DateTime start,
    required DateTime end,
  }) async {
    _requireAuth();
    final data = await _client
        .from('step_logs')
        .select()
        .eq('user_id', _userId!)
        .gte('date', start.toIso8601String().split('T').first)
        .lte('date', end.toIso8601String().split('T').first)
        .order('date', ascending: false);

    return data.map((row) => StepLogModel.fromJson(row)).toList();
  }

  /// Upserts today's step log (insert or update on conflict).
  Future<StepLogModel> upsertStepLog(StepLogModel log) async {
    _requireAuth();
    final data = await _client
        .from('step_logs')
        .upsert(
          log.toUpsertJson(),
          onConflict: 'user_id,date',
        )
        .select()
        .single();

    return StepLogModel.fromJson(data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches the user's notification settings.
  Future<NotificationSettingsModel> getNotificationSettings() async {
    _requireAuth();
    final data = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', _userId!)
        .maybeSingle();

    if (data != null) {
      return NotificationSettingsModel.fromJson(data);
    }
    // Return defaults if no settings exist yet
    return NotificationSettingsModel.defaults(_userId!);
  }

  /// Creates or updates notification settings.
  Future<NotificationSettingsModel> upsertNotificationSettings(
      NotificationSettingsModel settings) async {
    _requireAuth();
    final upsertData = settings.toUpsertJson();
    upsertData['user_id'] = _userId!;
    
    final data = await _client
        .from('notification_settings')
        .upsert(
          upsertData,
          onConflict: 'user_id',
        )
        .select()
        .single();

    return NotificationSettingsModel.fromJson(data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS / AGGREGATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets total workout count for the current user.
  Future<int> getTotalWorkoutCount() async {
    _requireAuth();
    try {
      final data = await _client
          .from('workout_logs')
          .select('id')
          .eq('user_id', _userId!);
      return data.length;
    } catch (e) {
      debugPrint('Error getting workout count: $e');
      return 0;
    }
  }

  /// Gets workout count for the current week (Mon-Sun).
  Future<int> getWeeklyWorkoutCount() async {
    _requireAuth();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    try {
      final data = await _client
          .from('workout_logs')
          .select('id')
          .eq('user_id', _userId!)
          .gte('performed_at', start.toIso8601String());
      return data.length;
    } catch (e) {
      debugPrint('Error getting weekly workout count: $e');
      return 0;
    }
  }

  /// Gets the user's current workout streak (consecutive days).
  Future<int> getWorkoutStreak() async {
    _requireAuth();
    try {
      final data = await _client
          .from('workout_logs')
          .select('performed_at')
          .eq('user_id', _userId!)
          .order('performed_at', ascending: false)
          .limit(90); // Check last 90 days max

      if (data.isEmpty) return 0;

      // Group by date
      final dates = data
          .map((row) =>
              DateTime.parse(row['performed_at'] as String)
                  .toIso8601String()
                  .split('T')
                  .first)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Newest first

      if (dates.isEmpty) return 0;

      int streak = 1;
      for (int i = 1; i < dates.length; i++) {
        final current = DateTime.parse(dates[i]);
        final previous = DateTime.parse(dates[i - 1]);
        final diff = previous.difference(current).inDays;

        if (diff == 1) {
          streak++;
        } else {
          break;
        }
      }

      // Check if streak is still active (includes today or yesterday)
      final latest = DateTime.parse(dates.first);
      final today = DateTime.now();
      final daysDiff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(latest.year, latest.month, latest.day))
          .inDays;

      if (daysDiff > 1) return 0; // Streak broken

      return streak;
    } catch (e) {
      debugPrint('Error getting workout streak: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEEDBACK (SARAN & KESAN)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submits suggestions and impressions for the TPM course to Supabase.
  Future<void> submitFeedback({
    required String suggestion,
    required String impression,
  }) async {
    _requireAuth();
    await _client.from('course_feedback').insert({
      'user_id': _userId,
      'suggestion': suggestion,
      'impression': impression,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetches all feedback submitted by the current user.
  Future<List<FeedbackModel>> getFeedback() async {
    _requireAuth();
    final data = await _client
        .from('course_feedback')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return data.map((row) => FeedbackModel.fromJson(row)).toList();
  }
}
