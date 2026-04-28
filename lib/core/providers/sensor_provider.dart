import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/constants.dart';
import '../models/exercise_model.dart';
import '../models/step_log_model.dart';
import '../services/sensor_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../services/wger_api_service.dart';

/// Provider for sensor-based features: Step Counter & Shake Surprise.
///
/// Manages:
/// - Real-time step counting with persistence to Supabase
/// - Calorie/distance estimation from step count
/// - Weekly step history for chart display
/// - Shake-triggered random exercise suggestion
class SensorProvider extends ChangeNotifier {
  final SensorService _sensorService = SensorService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final WgerApiService _wgerApi = WgerApiService.instance;

  // Current user ID for per-user persistence (shake history)
  String? _userId;
  static const String _sensorBoxName = 'settings';

  // ─────────────────────────────────────────────────────────────────────────
  // STEP COUNTER STATE
  // ─────────────────────────────────────────────────────────────────────────

  int _currentSteps = 0;
  final int _dailyGoal = AppConstants.defaultStepGoal;
  bool _isTracking = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // Weekly step data: index 0 = Mon, 6 = Sun
  List<int> _weeklySteps = List.filled(7, 0);

  // Step goal notification flag (avoids duplicate notifications per session)
  bool _stepGoalNotified = false;

  // ─────────────────────────────────────────────────────────────────────────
  // SHAKE FEATURE STATE
  // ─────────────────────────────────────────────────────────────────────────

  Exercise? _suggestedExercise;
  bool _isShakeActive = false;
  bool _isLoadingExercise = false;
  int _shakeCount = 0;
  final List<Exercise> _shakeHistory = [];

  // Cached exercise list for random selection
  List<Exercise> _cachedExercises = [];

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS — STEP COUNTER
  // ─────────────────────────────────────────────────────────────────────────

  int get currentSteps => _currentSteps;
  int get dailyGoal => _dailyGoal;
  bool get isTracking => _isTracking;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<int> get weeklySteps => List.unmodifiable(_weeklySteps);

  /// Step progress as 0.0–1.0.
  double get stepProgress {
    if (_dailyGoal == 0) return 0;
    return (_currentSteps / _dailyGoal).clamp(0.0, 1.0);
  }

  /// Estimated calories burned from step count.
  /// ~0.04 kcal per step (average for walking).
  double get caloriesBurned => _currentSteps * 0.04;

  /// Estimated distance in km from step count.
  /// Average stride length ~0.762 m (30 inches).
  double get distanceKm => (_currentSteps * 0.762) / 1000;

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS — SHAKE FEATURE
  // ─────────────────────────────────────────────────────────────────────────

  Exercise? get suggestedExercise => _suggestedExercise;
  bool get isShakeActive => _isShakeActive;
  bool get isLoadingExercise => _isLoadingExercise;
  int get shakeCount => _shakeCount;
  List<Exercise> get shakeHistory => List.unmodifiable(_shakeHistory);

  // ─────────────────────────────────────────────────────────────────────────
  // STEP COUNTER — ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Initializes the step counter: loads today's stored steps and weekly data.
  Future<void> initStepCounter() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _loadTodaySteps();
      await _loadWeeklySteps();
    } catch (e) {
      debugPrint('[SensorProvider] Init error: $e');
      _errorMessage = 'Failed to load step data';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Starts real-time step tracking.
  void startTracking() {
    if (_isTracking) return;

    _sensorService.startStepCounting(
      onStep: (steps) {
        _currentSteps = steps;
        notifyListeners();

        // Check step goal and fire notification once per session
        if (!_stepGoalNotified && _currentSteps >= _dailyGoal) {
          _stepGoalNotified = true;
          NotificationService.instance.showStepGoalAchieved(
            steps: _currentSteps,
          );
        }
      },
      initialSteps: _currentSteps,
    );

    _isTracking = true;
    notifyListeners();
  }

  /// Stops real-time step tracking and persists the count.
  Future<void> stopTracking() async {
    _sensorService.stopStepCounting();
    _isTracking = false;
    notifyListeners();

    // Persist current steps to Supabase
    await _persistSteps();
  }

  /// Persists current step count to Supabase.
  Future<void> _persistSteps() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final log = StepLogModel(
        id: '', // will be generated
        userId: userId,
        stepCount: _currentSteps,
        date: DateTime.now(),
        distanceKm: distanceKm,
        caloriesBurned: caloriesBurned,
      );
      await _supabaseService.upsertStepLog(log);
    } catch (e) {
      debugPrint('[SensorProvider] Persist error: $e');
    }
  }

  /// Saves current progress (can be called periodically).
  Future<void> saveProgress() async {
    await _persistSteps();
  }

  /// Loads today's step count from Supabase.
  Future<void> _loadTodaySteps() async {
    try {
      final today = await _supabaseService.getTodayStepLog();
      if (today != null) {
        _currentSteps = today.stepCount;
      }
    } catch (e) {
      debugPrint('[SensorProvider] Load today steps error: $e');
    }
  }

  /// Loads weekly step data (Mon–Sun) for the chart.
  Future<void> _loadWeeklySteps() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final end = start.add(const Duration(days: 7));

      final logs = await _supabaseService.getStepLogs(start: start, end: end);

      final List<int> weekly = List.filled(7, 0);
      for (final log in logs) {
        final dayIndex = log.date.weekday - 1; // 0=Mon, 6=Sun
        if (dayIndex >= 0 && dayIndex < 7) {
          weekly[dayIndex] = log.stepCount;
        }
      }
      _weeklySteps = weekly;
    } catch (e) {
      debugPrint('[SensorProvider] Load weekly steps error: $e');
    }
  }

  /// Refreshes all step data.
  Future<void> refreshStepData() async {
    await _loadTodaySteps();
    await _loadWeeklySteps();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHAKE FEATURE — ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Starts shake detection. Fetches a random exercise on each shake.
  void startShakeDetection() {
    if (_isShakeActive) return;

    _sensorService.startShakeDetection(
      onShake: () {
        _onShakeDetected();
      },
    );

    _isShakeActive = true;
    notifyListeners();
  }

  /// Stops shake detection.
  void stopShakeDetection() {
    _sensorService.stopShakeDetection();
    _isShakeActive = false;
    notifyListeners();
  }

  /// Handles a shake event: fetches a random exercise.
  Future<void> _onShakeDetected() async {
    if (_isLoadingExercise) return;

    _isLoadingExercise = true;
    _shakeCount++;
    notifyListeners();

    try {
      final exercise = await _getRandomExercise();
      if (exercise != null) {
        _suggestedExercise = exercise;

        // Add to history (avoid duplicates at the front)
        _shakeHistory.removeWhere((e) => e.id == exercise.id);
        _shakeHistory.insert(0, exercise);
        if (_shakeHistory.length > 10) {
          _shakeHistory.removeRange(10, _shakeHistory.length);
        }
        
        _saveShakeHistory();
      }
    } catch (e) {
      debugPrint('[SensorProvider] Shake exercise error: $e');
    }

    _isLoadingExercise = false;
    notifyListeners();
  }

  /// Manually triggers a "shake" (for the button fallback).
  Future<void> triggerRandomExercise() async {
    await _onShakeDetected();
  }

  /// Gets a random exercise from the cache or API.
  Future<Exercise?> _getRandomExercise() async {
    // Fill cache if empty
    if (_cachedExercises.isEmpty) {
      try {
        final result = await _wgerApi.getExerciseInfoList(
          offset: 0,
          limit: 50,
        );
        _cachedExercises = result.exercises;
      } catch (e) {
        debugPrint('[SensorProvider] Cache exercises error: $e');
        return null;
      }
    }

    if (_cachedExercises.isEmpty) return null;

    final random = Random();
    return _cachedExercises[random.nextInt(_cachedExercises.length)];
  }

  /// Clears the suggested exercise (dismiss the card).
  void clearSuggestion() {
    _suggestedExercise = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PER-USER PERSISTENCE
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads user-specific shake history from Hive.
  void loadUserData(String userId) {
    _userId = userId;

    try {
      final box = Hive.box(_sensorBoxName);
      final historyRaw = box.get('shake_history_$userId') as String?;
      
      _shakeHistory.clear();
      if (historyRaw != null) {
        final list = jsonDecode(historyRaw) as List;
        for (final item in list) {
          _shakeHistory.add(Exercise.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('[SensorProvider] Error loading user data: $e');
    }
    
    notifyListeners();
  }

  void _saveShakeHistory() {
    if (_userId == null) return;
    try {
      final box = Hive.box(_sensorBoxName);
      final data = _shakeHistory.map((e) => e.toJson()).toList();
      box.put('shake_history_$_userId', jsonEncode(data));
    } catch (e) {
      debugPrint('[SensorProvider] Error saving shake history: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESET STATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Resets in-memory state on sign-out.
  void resetState() {
    _userId = null;
    // Stop sensors
    _sensorService.stopStepCounting();
    _sensorService.stopShakeDetection();

    // Reset step counter state
    _currentSteps = 0;
    _isTracking = false;
    _isLoading = false;
    _errorMessage = '';
    _weeklySteps = List.filled(7, 0);
    _stepGoalNotified = false;

    // Reset shake feature state
    _suggestedExercise = null;
    _isShakeActive = false;
    _isLoadingExercise = false;
    _shakeCount = 0;
    _shakeHistory.clear();
    _cachedExercises = [];

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sensorService.dispose();
    super.dispose();
  }
}
