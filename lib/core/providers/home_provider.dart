import 'package:flutter/foundation.dart';

import '../../config/constants.dart';
import '../models/step_log_model.dart';
import '../models/workout_log_model.dart';
import '../models/workout_plan_model.dart';
import '../models/plan_exercise_model.dart';
import '../services/supabase_service.dart';

/// State management for the Home Dashboard.
///
/// Loads and caches daily stats (steps, calories, workout minutes),
/// today's workout plan, and weekly activity data from Supabase.
class HomeProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String _errorMessage = '';

  // Today's stats
  StepLogModel? _todaySteps;
  List<WorkoutLogModel> _todayWorkouts = [];

  // Today's workout plan
  WorkoutPlanModel? _todayPlan;
  List<PlanExerciseModel> _todayPlanExercises = [];

  // Weekly activity: weekday (1=Mon, 7=Sun) → total duration minutes
  Map<int, int> _weeklyActivity = {};

  // Streak
  int _workoutStreak = 0;

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  StepLogModel? get todaySteps => _todaySteps;
  List<WorkoutLogModel> get todayWorkouts => _todayWorkouts;
  WorkoutPlanModel? get todayPlan => _todayPlan;
  List<PlanExerciseModel> get todayPlanExercises => _todayPlanExercises;
  Map<int, int> get weeklyActivity => _weeklyActivity;
  int get workoutStreak => _workoutStreak;

  // ── Computed Values ─────────────────────────────────────────────────────

  /// Today's total steps.
  int get todayStepCount => _todaySteps?.stepCount ?? 0;

  /// Today's estimated calories burned (from step log + workout logs).
  double get todayCalories {
    double cal = _todaySteps?.caloriesBurned ?? 0;
    for (final log in _todayWorkouts) {
      // Estimate: ~5 kcal per minute of workout if not tracked
      cal += (log.durationMinutes ?? 0) * 5;
    }
    return cal;
  }

  /// Today's total workout minutes.
  int get todayWorkoutMinutes {
    int total = 0;
    for (final log in _todayWorkouts) {
      total += log.durationMinutes ?? 0;
    }
    return total;
  }

  /// Step progress as 0.0–1.0 (relative to step goal).
  double get stepProgress {
    final goal = AppConstants.defaultStepGoal;
    if (goal == 0) return 0;
    return (todayStepCount / goal).clamp(0.0, 1.0);
  }

  /// Calorie progress as 0.0–1.0 (relative to 500 kcal goal).
  double get calorieProgress {
    const goal = 500.0;
    return (todayCalories / goal).clamp(0.0, 1.0);
  }

  /// Workout duration progress as 0.0–1.0 (relative to 60 min goal).
  double get workoutProgress {
    const goal = 60;
    return (todayWorkoutMinutes / goal).clamp(0.0, 1.0);
  }

  /// Number of exercises in today's plan.
  int get todayExerciseCount => _todayPlanExercises.length;

  /// Estimated duration for today's plan (exercises × ~8 min each).
  int get todayPlanEstimatedMinutes => _todayPlanExercises.length * 8;

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD DASHBOARD DATA
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads all dashboard data. Called on home screen init.
  Future<void> loadDashboard() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await Future.wait([
        _loadTodayStats(),
        _loadTodayPlan(),
        _loadWeeklyActivity(),
        _loadStreak(),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      _errorMessage = 'Failed to load dashboard data';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refreshes all dashboard data (pull-to-refresh).
  Future<void> refreshDashboard() async {
    _errorMessage = '';
    try {
      await Future.wait([
        _loadTodayStats(),
        _loadTodayPlan(),
        _loadWeeklyActivity(),
        _loadStreak(),
      ]);
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
      _errorMessage = 'Failed to refresh data';
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE LOADERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadTodayStats() async {
    try {
      // Load today's step log
      _todaySteps = await _supabaseService.getTodayStepLog();

      // Load today's workout logs
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      _todayWorkouts = await _supabaseService.getWorkoutLogsByDateRange(
        start: startOfDay,
        end: endOfDay,
      );
    } catch (e) {
      debugPrint('Error loading today stats: $e');
    }
  }

  Future<void> _loadTodayPlan() async {
    try {
      // Get all workout plans
      final plans = await _supabaseService.getWorkoutPlans();

      // Find plan for today's day of week
      final todayDow = _getDayOfWeekName(DateTime.now().weekday);
      _todayPlan = plans.cast<WorkoutPlanModel?>().firstWhere(
            (plan) =>
                plan!.dayOfWeek?.toLowerCase() == todayDow.toLowerCase(),
            orElse: () => plans.isNotEmpty ? plans.first : null,
          );

      // Load plan exercises if a plan exists
      if (_todayPlan != null) {
        _todayPlanExercises =
            await _supabaseService.getPlanExercises(_todayPlan!.id);
      } else {
        _todayPlanExercises = [];
      }
    } catch (e) {
      debugPrint('Error loading today plan: $e');
    }
  }

  Future<void> _loadWeeklyActivity() async {
    try {
      final now = DateTime.now();
      // Monday of current week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final end = start.add(const Duration(days: 7));

      final logs = await _supabaseService.getWorkoutLogsByDateRange(
        start: start,
        end: end,
      );

      // Aggregate by weekday
      final Map<int, int> activity = {
        1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0,
      };
      for (final log in logs) {
        final weekday = log.performedAt.weekday;
        activity[weekday] = (activity[weekday] ?? 0) + (log.durationMinutes ?? 0);
      }
      _weeklyActivity = activity;
    } catch (e) {
      debugPrint('Error loading weekly activity: $e');
    }
  }

  Future<void> _loadStreak() async {
    try {
      _workoutStreak = await _supabaseService.getWorkoutStreak();
    } catch (e) {
      debugPrint('Error loading streak: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  String _getDayOfWeekName(int weekday) {
    const days = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return days[weekday] ?? 'Monday';
  }
}
