import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../models/exercise_model.dart';
import '../models/exercise_category_model.dart';
import '../models/muscle_model.dart';

/// Service layer for all wger.de REST API interactions.
///
/// Handles fetching exercise categories, exercises (with pagination),
/// exercise details, muscles, and equipment data.
class WgerApiService {
  WgerApiService._();
  static final WgerApiService instance = WgerApiService._();

  final _client = http.Client();

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (AppConstants.wgerApiKey.isNotEmpty)
          'Authorization': 'Token ${AppConstants.wgerApiKey}',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches all exercise categories.
  Future<List<ExerciseCategory>> getCategories() async {
    final uri = Uri.parse('${AppConstants.wgerExerciseCategory}?format=json');
    final response = await _client.get(uri, headers: _headers).timeout(
      Duration(seconds: AppConstants.apiTimeoutSeconds),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;
      return results
          .map((e) => ExerciseCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load categories: ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXERCISES (Paginated)
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches exercises with pagination and optional category filter.
  ///
  /// Returns a [PaginatedExercises] containing the list and total count.
  Future<PaginatedExercises> getExercises({
    int offset = 0,
    int limit = 20,
    int? categoryId,
    String language = '2', // English
  }) async {
    final params = <String, String>{
      'format': 'json',
      'language': language,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (categoryId != null) {
      params['category'] = categoryId.toString();
    }

    final uri = Uri.parse(AppConstants.wgerExercise).replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers).timeout(
      Duration(seconds: AppConstants.apiTimeoutSeconds),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final count = data['count'] as int;
      final results = data['results'] as List<dynamic>;

      // The basic exercise endpoint only has IDs, not names.
      // We need to fetch exerciseinfo for each to get translations.
      final exercises = <Exercise>[];
      for (final r in results) {
        final basicExercise = Exercise.fromJson(r as Map<String, dynamic>);
        exercises.add(basicExercise);
      }

      return PaginatedExercises(
        exercises: exercises,
        totalCount: count,
        hasMore: data['next'] != null,
      );
    }
    throw Exception('Failed to load exercises: ${response.statusCode}');
  }

  /// Fetches exercises using the exerciseinfo endpoint for richer data.
  /// This gives us names, descriptions, images, and muscles in one call.
  Future<PaginatedExercises> getExerciseInfoList({
    int offset = 0,
    int limit = 20,
    int? categoryId,
    String language = '2',
  }) async {
    final params = <String, String>{
      'format': 'json',
      'language': language,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (categoryId != null) {
      params['category'] = categoryId.toString();
    }

    final uri = Uri.parse(AppConstants.wgerExerciseInfo)
        .replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers).timeout(
      Duration(seconds: AppConstants.apiTimeoutSeconds),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final count = data['count'] as int;
      final results = data['results'] as List<dynamic>;

      final exercises = results
          .map((e) => Exercise.fromInfoJson(e as Map<String, dynamic>))
          .where((ex) => ex.name.isNotEmpty) // Skip exercises without English names
          .toList();

      return PaginatedExercises(
        exercises: exercises,
        totalCount: count,
        hasMore: data['next'] != null,
      );
    }
    throw Exception('Failed to load exercise info: ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXERCISE DETAIL
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches full exercise detail by ID from the exerciseinfo endpoint.
  Future<Exercise> getExerciseDetail(int exerciseId) async {
    final uri = Uri.parse(
      '${AppConstants.wgerExerciseInfo}$exerciseId/?format=json',
    );
    final response = await _client.get(uri, headers: _headers).timeout(
      Duration(seconds: AppConstants.apiTimeoutSeconds),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Exercise.fromInfoJson(data as Map<String, dynamic>);
    }
    throw Exception('Failed to load exercise detail: ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────────────────────────────────

  /// Searches exercises by name using the wger search endpoint.
  Future<List<Exercise>> searchExercises(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final queryParams = {
        'term': query,
        'format': 'json',
      };
      final uri = Uri.parse('${AppConstants.wgerBaseUrl}/exercise/search/')
          .replace(queryParameters: queryParams);

      final response = await _client.get(uri, headers: _headers).timeout(
        Duration(seconds: AppConstants.apiTimeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];
        return suggestions
            .map((s) => Exercise.fromSearchJson(s as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to search exercises: ${response.statusCode}');
    } catch (e) {
      debugPrint('Search API Error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MUSCLES
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches all muscle data.
  Future<List<Muscle>> getMuscles() async {
    final uri = Uri.parse('${AppConstants.wgerMuscle}?format=json');
    final response = await _client.get(uri, headers: _headers).timeout(
      Duration(seconds: AppConstants.apiTimeoutSeconds),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;
      return results
          .map((m) => Muscle.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load muscles: ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EQUIPMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches all equipment data. Returns a map of id → name.
  Future<Map<int, String>> getEquipment() async {
    final uri = Uri.parse('${AppConstants.wgerEquipment}?format=json');
    final response = await _client.get(uri, headers: _headers).timeout(
      Duration(seconds: AppConstants.apiTimeoutSeconds),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;
      return {
        for (final e in results)
          (e as Map<String, dynamic>)['id'] as int:
              e['name'] as String,
      };
    }
    throw Exception('Failed to load equipment: ${response.statusCode}');
  }

  /// Dispose the HTTP client.
  void dispose() {
    _client.close();
  }
}

/// Wrapper for paginated exercise results.
class PaginatedExercises {
  final List<Exercise> exercises;
  final int totalCount;
  final bool hasMore;

  const PaginatedExercises({
    required this.exercises,
    required this.totalCount,
    required this.hasMore,
  });
}
