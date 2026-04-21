import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/plan_exercise_model.dart';
import '../models/workout_log_model.dart';
import '../models/workout_plan_model.dart';
import '../services/supabase_service.dart';

/// State management for Workout Management (Phase 7).
///
/// Handles workout plan CRUD, session tracking with set/rep/weight logging,
/// rest timer, and workout flow navigation.
class WorkoutProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // PLAN LIST STATE
  // ─────────────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String _errorMessage = '';
  List<WorkoutPlanModel> _plans = [];
  Map<String, List<PlanExerciseModel>> _planExercises = {};
  String? _selectedDayFilter; // null = "All"

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<WorkoutPlanModel> get plans => _plans;
  Map<String, List<PlanExerciseModel>> get planExercises => _planExercises;
  String? get selectedDayFilter => _selectedDayFilter;

  /// Filtered plans based on selected day.
  List<WorkoutPlanModel> get filteredPlans {
    if (_selectedDayFilter == null) return _plans;
    return _plans
        .where((p) =>
            p.dayOfWeek?.toLowerCase() ==
            _selectedDayFilter!.toLowerCase())
        .toList();
  }

  void setDayFilter(String? day) {
    _selectedDayFilter = day;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE/EDIT FORM STATE
  // ─────────────────────────────────────────────────────────────────────────

  String _formPlanName = '';
  String _formPlanDescription = '';
  String? _formSelectedDay;
  List<PlanExerciseModel> _formExercises = [];
  bool _isSaving = false;

  String get formPlanName => _formPlanName;
  String get formPlanDescription => _formPlanDescription;
  String? get formSelectedDay => _formSelectedDay;
  List<PlanExerciseModel> get formExercises => _formExercises;
  bool get isSaving => _isSaving;

  void setFormPlanName(String name) => _formPlanName = name;
  void setFormPlanDescription(String desc) => _formPlanDescription = desc;
  void setFormSelectedDay(String? day) {
    _formSelectedDay = day;
    notifyListeners();
  }

  /// Resets form to empty state (for create mode).
  void resetForm() {
    _formPlanName = '';
    _formPlanDescription = '';
    _formSelectedDay = null;
    _formExercises = [];
    notifyListeners();
  }

  /// Pre-fills form for edit mode.
  void initFormForEdit(WorkoutPlanModel plan, List<PlanExerciseModel> exercises) {
    _formPlanName = plan.name;
    _formPlanDescription = plan.description ?? '';
    _formSelectedDay = plan.dayOfWeek;
    _formExercises = List.from(exercises);
    notifyListeners();
  }

  void addFormExercise(PlanExerciseModel exercise) {
    _formExercises.add(exercise);
    notifyListeners();
  }

  void removeFormExercise(int index) {
    _formExercises.removeAt(index);
    notifyListeners();
  }

  void updateFormExercise(int index, PlanExerciseModel updated) {
    _formExercises[index] = updated;
    notifyListeners();
  }

  void reorderFormExercises(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _formExercises.removeAt(oldIndex);
    _formExercises.insert(newIndex, item);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION STATE
  // ─────────────────────────────────────────────────────────────────────────

  WorkoutPlanModel? _activePlan;
  List<PlanExerciseModel> _sessionExercises = [];
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _sessionReps = 12;
  double _sessionWeight = 0;
  String _sessionNotes = '';
  final Stopwatch _sessionTimer = Stopwatch();
  Timer? _sessionTickTimer;
  Duration _sessionElapsed = Duration.zero;

  // Rest timer
  bool _isResting = false;
  int _restSeconds = 60;
  int _restRemaining = 0;
  Timer? _restTickTimer;

  // Completed sets log
  final List<WorkoutLogModel> _sessionLogs = [];

  WorkoutPlanModel? get activePlan => _activePlan;
  List<PlanExerciseModel> get sessionExercises => _sessionExercises;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSet => _currentSet;
  int get sessionReps => _sessionReps;
  double get sessionWeight => _sessionWeight;
  String get sessionNotes => _sessionNotes;
  Duration get sessionElapsed => _sessionElapsed;
  bool get isResting => _isResting;
  int get restRemaining => _restRemaining;
  List<WorkoutLogModel> get sessionLogs => _sessionLogs;

  PlanExerciseModel? get currentExercise =>
      _sessionExercises.isNotEmpty && _currentExerciseIndex < _sessionExercises.length
          ? _sessionExercises[_currentExerciseIndex]
          : null;

  int get totalSetsForCurrentExercise => currentExercise?.targetSets ?? 4;

  double get exerciseProgress {
    if (_sessionExercises.isEmpty) return 0.0;
    
    int totalSets = 0;
    for (var ex in _sessionExercises) {
      totalSets += (ex.targetSets ?? 4);
    }
    if (totalSets == 0) return 0.0;

    int completedSets = 0;
    for (int i = 0; i < _currentExerciseIndex; i++) {
      completedSets += (_sessionExercises[i].targetSets ?? 4);
    }
    completedSets += (_currentSet - 1);

    return (completedSets / totalSets).clamp(0.0, 1.0);
  }

  String get sessionTimerDisplay {
    final minutes = _sessionElapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (_sessionElapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void setSessionReps(int reps) {
    _sessionReps = reps.clamp(1, 999);
    notifyListeners();
  }

  void setSessionWeight(double weight) {
    _sessionWeight = weight.clamp(0, 999);
    notifyListeners();
  }

  void setSessionNotes(String notes) => _sessionNotes = notes;

  // ─────────────────────────────────────────────────────────────────────────
  // PLAN CRUD
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads all workout plans and their exercises.
  Future<void> loadPlans() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _plans = await _supabaseService.getWorkoutPlans();

      // Load exercises for each plan
      _planExercises = {};
      for (final plan in _plans) {
        _planExercises[plan.id] =
            await _supabaseService.getPlanExercises(plan.id);
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
      _errorMessage = 'Failed to load workout plans';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Creates a new plan with exercises.
  Future<bool> createPlan() async {
    if (_formPlanName.trim().isEmpty) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final plan = WorkoutPlanModel(
        id: '',
        userId: userId,
        name: _formPlanName.trim(),
        description: _formPlanDescription.trim().isNotEmpty
            ? _formPlanDescription.trim()
            : null,
        dayOfWeek: _formSelectedDay,
        createdAt: DateTime.now(),
      );

      final saved = await _supabaseService.insertWorkoutPlan(plan);

      // Save exercises
      for (int i = 0; i < _formExercises.length; i++) {
        final exercise = _formExercises[i].copyWith(
          planId: saved.id,
          sortOrder: i,
        );
        await _supabaseService.insertPlanExercise(exercise);
      }

      await loadPlans();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating plan: $e');
      _errorMessage = 'Failed to create plan';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing plan.
  Future<bool> updatePlan(String planId) async {
    if (_formPlanName.trim().isEmpty) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final existing = _plans.firstWhere((p) => p.id == planId);
      final updated = existing.copyWith(
        name: _formPlanName.trim(),
        description: _formPlanDescription.trim().isNotEmpty
            ? _formPlanDescription.trim()
            : null,
        dayOfWeek: _formSelectedDay,
      );

      await _supabaseService.updateWorkoutPlan(updated);

      // Delete existing exercises and re-insert
      final oldExercises = _planExercises[planId] ?? [];
      for (final ex in oldExercises) {
        await _supabaseService.deletePlanExercise(ex.id);
      }
      for (int i = 0; i < _formExercises.length; i++) {
        final exercise = _formExercises[i].copyWith(
          planId: planId,
          sortOrder: i,
        );
        await _supabaseService.insertPlanExercise(exercise);
      }

      await loadPlans();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating plan: $e');
      _errorMessage = 'Failed to update plan';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a plan.
  Future<bool> deletePlan(String planId) async {
    try {
      await _supabaseService.deleteWorkoutPlan(planId);
      _plans.removeWhere((p) => p.id == planId);
      _planExercises.remove(planId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting plan: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Starts a workout session.
  void startSession(
      WorkoutPlanModel plan, List<PlanExerciseModel> exercises) {
    _activePlan = plan;
    _sessionExercises = List.from(exercises);
    _currentExerciseIndex = 0;
    _currentSet = 1;
    _sessionLogs.clear();
    _sessionNotes = '';
    _isResting = false;
    _restRemaining = 0;

    // Initialize with first exercise targets
    if (_sessionExercises.isNotEmpty) {
      _sessionReps = _sessionExercises.first.targetReps ?? 12;
      _sessionWeight = _sessionExercises.first.targetWeightKg ?? 0;
    }

    // Start session timer
    _sessionTimer.reset();
    _sessionTimer.start();
    _sessionTickTimer?.cancel();
    _sessionTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionElapsed = _sessionTimer.elapsed;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Completes the current set — logs it and advances.
  Future<void> completeSet() async {
    if (currentExercise == null) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final log = WorkoutLogModel(
        id: '',
        userId: userId,
        exerciseId: currentExercise!.exerciseId,
        exerciseName: currentExercise!.exerciseName,
        sets: _currentSet,
        reps: _sessionReps,
        weightKg: _sessionWeight > 0 ? _sessionWeight : null,
        durationMinutes: null,
        notes: _sessionNotes.isNotEmpty ? _sessionNotes : null,
        performedAt: DateTime.now(),
      );

      final saved = await _supabaseService.insertWorkoutLog(log);
      _sessionLogs.add(saved);

      // Advance set or exercise
      if (_currentSet < totalSetsForCurrentExercise) {
        _currentSet++;
        _sessionNotes = '';
        // Start rest timer automatically
        startRestTimer();
      } else {
        // Move to next exercise
        nextExercise();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error completing set: $e');
    }
  }

  /// Moves to next exercise.
  void nextExercise() {
    if (_currentExerciseIndex < _sessionExercises.length - 1) {
      _currentExerciseIndex++;
      _currentSet = 1;
      _sessionNotes = '';
      _sessionReps = currentExercise?.targetReps ?? 12;
      _sessionWeight = currentExercise?.targetWeightKg ?? 0;
      stopRestTimer();
      notifyListeners();
    }
  }

  /// Moves to previous exercise.
  void previousExercise() {
    if (_currentExerciseIndex > 0) {
      _currentExerciseIndex--;
      _currentSet = 1;
      _sessionNotes = '';
      _sessionReps = currentExercise?.targetReps ?? 12;
      _sessionWeight = currentExercise?.targetWeightKg ?? 0;
      stopRestTimer();
      notifyListeners();
    }
  }

  /// Starts the rest timer.
  void startRestTimer() {
    _isResting = true;
    _restRemaining = _restSeconds;
    _restTickTimer?.cancel();
    _restTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining > 0) {
        _restRemaining--;
        notifyListeners();
      } else {
        stopRestTimer();
      }
    });
    notifyListeners();
  }

  /// Stops the rest timer.
  void stopRestTimer() {
    _isResting = false;
    _restRemaining = 0;
    _restTickTimer?.cancel();
    notifyListeners();
  }

  /// Finishes the workout session.
  Future<void> finishWorkout() async {
    _sessionTimer.stop();
    _sessionTickTimer?.cancel();
    _restTickTimer?.cancel();
    _isResting = false;

    // Log total workout duration
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      if (_activePlan != null && _sessionLogs.isNotEmpty) {
        final totalLog = WorkoutLogModel(
          id: '',
          userId: userId,
          exerciseId: 0,
          exerciseName: '${_activePlan!.name} (Complete)',
          sets: null,
          reps: null,
          weightKg: null,
          durationMinutes: _sessionElapsed.inMinutes,
          notes:
              'Completed ${_sessionLogs.length} sets across ${_sessionExercises.length} exercises',
          performedAt: DateTime.now(),
        );
        await _supabaseService.insertWorkoutLog(totalLog);
      }
    } catch (e) {
      debugPrint('Error finishing workout: $e');
    }

    _activePlan = null;
    notifyListeners();
  }

  /// Whether the session is complete (all exercises done).
  bool get isSessionComplete =>
      _currentExerciseIndex >= _sessionExercises.length - 1 &&
      _currentSet >= totalSetsForCurrentExercise;

  @override
  void dispose() {
    _sessionTickTimer?.cancel();
    _restTickTimer?.cancel();
    super.dispose();
  }
}
