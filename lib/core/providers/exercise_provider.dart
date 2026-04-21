import 'package:flutter/foundation.dart';

import '../models/exercise_model.dart';
import '../models/exercise_category_model.dart';
import '../models/muscle_model.dart';
import '../services/wger_api_service.dart';

/// Provider for exercise-related state across the app.
///
/// Manages categories, paginated exercise lists, search, filtering,
/// exercise detail, and favorite exercises.
class ExerciseProvider extends ChangeNotifier {
  final _api = WgerApiService.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────────────────────

  // Categories
  List<ExerciseCategory> _categories = [];
  List<ExerciseCategory> get categories => _categories;
  bool _categoriesLoading = false;
  bool get categoriesLoading => _categoriesLoading;

  // Exercises (paginated)
  List<Exercise> _exercises = [];
  List<Exercise> get exercises => _exercises;
  bool _exercisesLoading = false;
  bool get exercisesLoading => _exercisesLoading;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  int _currentOffset = 0;
  int _totalCount = 0;
  int get totalCount => _totalCount;

  // Filter
  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;

  // Search
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  List<Exercise> _searchResults = [];
  List<Exercise> get searchResults => _searchResults;
  bool _searchLoading = false;
  bool get searchLoading => _searchLoading;

  // Exercise Detail
  Exercise? _selectedExercise;
  Exercise? get selectedExercise => _selectedExercise;
  bool _detailLoading = false;
  bool get detailLoading => _detailLoading;

  // Muscles (cached)
  List<Muscle> _muscles = [];
  List<Muscle> get muscles => _muscles;

  // Equipment (cached)
  Map<int, String> _equipment = {};
  Map<int, String> get equipment => _equipment;

  // Error
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads categories and initial exercise list.
  Future<void> init() async {
    await Future.wait([
      loadCategories(),
      loadExercises(),
      loadMuscles(),
      loadEquipment(),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadCategories() async {
    _categoriesLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _categories = await _api.getCategories();
    } catch (e) {
      _errorMessage = 'Failed to load categories: $e';
      debugPrint(_errorMessage);
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXERCISES (Paginated)
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads exercises from beginning with optional category filter.
  Future<void> loadExercises({int? categoryId}) async {
    _exercisesLoading = true;
    _exercises = [];
    _currentOffset = 0;
    _hasMore = true;
    _selectedCategoryId = categoryId;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _api.getExerciseInfoList(
        offset: 0,
        limit: 20,
        categoryId: categoryId,
      );
      _exercises = result.exercises;
      _totalCount = result.totalCount;
      _hasMore = result.hasMore;
      _currentOffset = _exercises.length;
    } catch (e) {
      _errorMessage = 'Failed to load exercises: $e';
      debugPrint(_errorMessage);
    } finally {
      _exercisesLoading = false;
      notifyListeners();
    }
  }

  /// Loads the next page of exercises.
  Future<void> loadMoreExercises() async {
    if (_exercisesLoading || !_hasMore) return;

    _exercisesLoading = true;
    notifyListeners();

    try {
      final result = await _api.getExerciseInfoList(
        offset: _currentOffset,
        limit: 20,
        categoryId: _selectedCategoryId,
      );
      _exercises.addAll(result.exercises);
      _totalCount = result.totalCount;
      _hasMore = result.hasMore;
      _currentOffset += result.exercises.length;
    } catch (e) {
      _errorMessage = 'Failed to load more exercises: $e';
      debugPrint(_errorMessage);
    } finally {
      _exercisesLoading = false;
      notifyListeners();
    }
  }

  /// Selects a category filter and reloads exercises.
  Future<void> selectCategory(int? categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    await loadExercises(categoryId: categoryId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────────────────────────────────

  /// Sets search query and performs search.
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _searchLoading = true;
    notifyListeners();

    try {
      _searchResults = await _api.searchExercises(query);
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      debugPrint(_errorMessage);
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  /// Clears search state.
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXERCISE DETAIL
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads full exercise detail by ID.
  Future<void> loadExerciseDetail(int exerciseId) async {
    _detailLoading = true;
    _selectedExercise = null;
    _errorMessage = '';
    notifyListeners();

    try {
      _selectedExercise = await _api.getExerciseDetail(exerciseId);
    } catch (e) {
      _errorMessage = 'Failed to load exercise detail: $e';
      debugPrint(_errorMessage);
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  /// Sets exercise directly (for navigating from list with pre-fetched data).
  void setSelectedExercise(Exercise exercise) {
    _selectedExercise = exercise;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MUSCLES & EQUIPMENT (Cached)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadMuscles() async {
    if (_muscles.isNotEmpty) return;
    try {
      _muscles = await _api.getMuscles();
    } catch (e) {
      debugPrint('Failed to load muscles: $e');
    }
  }

  Future<void> loadEquipment() async {
    if (_equipment.isNotEmpty) return;
    try {
      _equipment = await _api.getEquipment();
    } catch (e) {
      debugPrint('Failed to load equipment: $e');
    }
  }

  /// Returns muscle name by ID.
  String getMuscleNameById(int id) {
    final muscle = _muscles.where((m) => m.id == id).firstOrNull;
    return muscle?.displayName ?? 'Unknown';
  }

  /// Returns equipment name by ID.
  String getEquipmentNameById(int id) {
    return _equipment[id] ?? 'Unknown';
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
