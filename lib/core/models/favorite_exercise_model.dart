/// Favorite exercise model that maps to the `favorite_exercises` table.
///
/// Tracks which exercises the user has bookmarked for quick access.
class FavoriteExerciseModel {
  final String id;
  final String userId;
  final int exerciseId;
  final String exerciseName;
  final String? category;
  final DateTime createdAt;

  const FavoriteExerciseModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    this.category,
    required this.createdAt,
  });

  factory FavoriteExerciseModel.fromJson(Map<String, dynamic> json) {
    return FavoriteExerciseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseId: json['exercise_id'] as int,
      exerciseName: json['exercise_name'] as String,
      category: json['category'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'category': category,
    };
  }

  @override
  String toString() =>
      'FavoriteExerciseModel(id: $id, exercise: $exerciseName)';
}
