import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

/// Local cache service using Hive for offline-first data access.
///
/// Caches JSON data from Supabase/APIs locally so the app can
/// display data immediately and sync in the background.
///
/// Cache structure:
/// - Each "collection" is stored in a separate Hive box.
/// - Data is stored as JSON strings keyed by their ID or a composite key.
/// - Each entry includes a `_cachedAt` timestamp for TTL checks.
class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService instance = LocalCacheService._();

  // ─────────────────────────────────────────────────────────────────────────
  // BOX NAMES
  // ─────────────────────────────────────────────────────────────────────────
  static const String exercisesBox = 'exercises_cache';
  static const String exerciseCategoriesBox = 'exercise_categories_cache';
  static const String workoutPlansBox = 'workout_plans_cache';
  static const String workoutLogsBox = 'workout_logs_cache';
  static const String favoritesBox = 'favorites_cache';
  static const String stepLogsBox = 'step_logs_cache';
  static const String profileBox = 'profile_cache';
  static const String settingsBox = 'settings';

  // ─────────────────────────────────────────────────────────────────────────
  // DEFAULT TTL (Time To Live)
  // ─────────────────────────────────────────────────────────────────────────
  /// Default cache duration: 1 hour.
  static const Duration defaultTtl = Duration(hours: 1);

  /// Long TTL for rarely-changing data (e.g., exercise list): 24 hours.
  static const Duration longTtl = Duration(hours: 24);

  /// Short TTL for frequently-changing data (e.g., step logs): 5 minutes.
  static const Duration shortTtl = Duration(minutes: 5);

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Opens all cache boxes. Call once during app startup (after Hive.initFlutter).
  Future<void> init() async {
    try {
      await Future.wait([
        Hive.openBox(exercisesBox),
        Hive.openBox(exerciseCategoriesBox),
        Hive.openBox(workoutPlansBox),
        Hive.openBox(workoutLogsBox),
        Hive.openBox(favoritesBox),
        Hive.openBox(stepLogsBox),
        Hive.openBox(profileBox),
        Hive.openBox(settingsBox),
      ]);
      debugPrint('[LocalCache] All cache boxes opened.');
    } catch (e) {
      debugPrint('[LocalCache] Error initializing: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GENERIC CRUD
  // ─────────────────────────────────────────────────────────────────────────

  /// Caches a single item as JSON.
  Future<void> put(String boxName, String key, Map<String, dynamic> data) async {
    try {
      final box = Hive.box(boxName);
      final cached = {
        ...data,
        '_cachedAt': DateTime.now().toIso8601String(),
      };
      await box.put(key, jsonEncode(cached));
    } catch (e) {
      debugPrint('[LocalCache] Error putting $key in $boxName: $e');
    }
  }

  /// Retrieves a single cached item, or null if not found / expired.
  Map<String, dynamic>? get(String boxName, String key, {Duration? ttl}) {
    try {
      final box = Hive.box(boxName);
      final raw = box.get(key) as String?;
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;

      // Check TTL
      if (ttl != null && data['_cachedAt'] != null) {
        final cachedAt = DateTime.tryParse(data['_cachedAt'] as String);
        if (cachedAt != null &&
            DateTime.now().difference(cachedAt) > ttl) {
          // Expired
          return null;
        }
      }

      return data;
    } catch (e) {
      debugPrint('[LocalCache] Error getting $key from $boxName: $e');
      return null;
    }
  }

  /// Caches a list of items, each keyed by its 'id' field.
  Future<void> putList(
    String boxName,
    List<Map<String, dynamic>> items, {
    String idField = 'id',
  }) async {
    try {
      final box = Hive.box(boxName);
      final now = DateTime.now().toIso8601String();

      for (final item in items) {
        final key = item[idField]?.toString();
        if (key == null) continue;
        final cached = {...item, '_cachedAt': now};
        await box.put(key, jsonEncode(cached));
      }

      // Store the list index
      final keys = items
          .map((item) => item[idField]?.toString())
          .where((k) => k != null)
          .toList();
      await box.put('_index', jsonEncode(keys));
    } catch (e) {
      debugPrint('[LocalCache] Error putting list in $boxName: $e');
    }
  }

  /// Retrieves all cached items from a box as a list.
  List<Map<String, dynamic>> getList(String boxName, {Duration? ttl}) {
    try {
      final box = Hive.box(boxName);
      final indexRaw = box.get('_index') as String?;
      if (indexRaw == null) return [];

      final keys = (jsonDecode(indexRaw) as List).cast<String>();
      final items = <Map<String, dynamic>>[];

      for (final key in keys) {
        final item = get(boxName, key, ttl: ttl);
        if (item != null) {
          items.add(item);
        }
      }

      return items;
    } catch (e) {
      debugPrint('[LocalCache] Error getting list from $boxName: $e');
      return [];
    }
  }

  /// Deletes a single cached item.
  Future<void> delete(String boxName, String key) async {
    try {
      final box = Hive.box(boxName);
      await box.delete(key);
    } catch (e) {
      debugPrint('[LocalCache] Error deleting $key from $boxName: $e');
    }
  }

  /// Clears all data in a specific cache box.
  Future<void> clearBox(String boxName) async {
    try {
      final box = Hive.box(boxName);
      await box.clear();
      debugPrint('[LocalCache] Cleared $boxName');
    } catch (e) {
      debugPrint('[LocalCache] Error clearing $boxName: $e');
    }
  }

  /// Clears ALL cache boxes (e.g., on user logout).
  Future<void> clearAll() async {
    try {
      await Future.wait([
        clearBox(exercisesBox),
        clearBox(exerciseCategoriesBox),
        clearBox(workoutPlansBox),
        clearBox(workoutLogsBox),
        clearBox(favoritesBox),
        clearBox(stepLogsBox),
        clearBox(profileBox),
        // Don't clear settings — keep theme preference etc.
      ]);
      debugPrint('[LocalCache] All cache boxes cleared.');
    } catch (e) {
      debugPrint('[LocalCache] Error clearing all: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONVENIENCE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Checks if a cached item exists and is not expired.
  bool has(String boxName, String key, {Duration? ttl}) {
    return get(boxName, key, ttl: ttl) != null;
  }

  /// Gets the age of a cached item (time since it was cached).
  Duration? getAge(String boxName, String key) {
    try {
      final box = Hive.box(boxName);
      final raw = box.get(key) as String?;
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(data['_cachedAt'] as String? ?? '');
      if (cachedAt == null) return null;

      return DateTime.now().difference(cachedAt);
    } catch (e) {
      return null;
    }
  }

  /// Caches user profile data.
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    await put(profileBox, 'current_user', profile);
  }

  /// Retrieves cached user profile.
  Map<String, dynamic>? getCachedProfile() {
    return get(profileBox, 'current_user', ttl: defaultTtl);
  }

  /// Caches exercise list from wger API.
  Future<void> cacheExercises(List<Map<String, dynamic>> exercises) async {
    await putList(exercisesBox, exercises);
  }

  /// Retrieves cached exercises (valid for 24 hours).
  List<Map<String, dynamic>> getCachedExercises() {
    return getList(exercisesBox, ttl: longTtl);
  }

  /// Caches exercise categories.
  Future<void> cacheExerciseCategories(
      List<Map<String, dynamic>> categories) async {
    await putList(exerciseCategoriesBox, categories);
  }

  /// Retrieves cached exercise categories (valid for 24 hours).
  List<Map<String, dynamic>> getCachedExerciseCategories() {
    return getList(exerciseCategoriesBox, ttl: longTtl);
  }
}
