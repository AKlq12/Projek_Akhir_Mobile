/// Workout log model that maps to the `workout_logs` table in Supabase.
///
/// Records a single exercise performance: sets, reps, weight, duration.
class WorkoutLogModel {
  final String id;
  final String userId;
  final int exerciseId;
  final String exerciseName;
  final int? sets;
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;
  final String? notes;
  final DateTime performedAt;

  const WorkoutLogModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    this.sets,
    this.reps,
    this.weightKg,
    this.durationMinutes,
    this.notes,
    required this.performedAt,
  });

  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) {
    return WorkoutLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseId: json['exercise_id'] as int,
      exerciseName: json['exercise_name'] as String,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      durationMinutes: json['duration_minutes'] as int?,
      notes: json['notes'] as String?,
      performedAt:
          DateTime.tryParse(json['performed_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
      'duration_minutes': durationMinutes,
      'notes': notes,
      'performed_at': performedAt.toIso8601String(),
    };
  }

  /// For insert (no id — Supabase generates it).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
      'duration_minutes': durationMinutes,
      'notes': notes,
      'performed_at': performedAt.toIso8601String(),
    };
  }

  WorkoutLogModel copyWith({
    String? id,
    String? userId,
    int? exerciseId,
    String? exerciseName,
    int? sets,
    int? reps,
    double? weightKg,
    int? durationMinutes,
    String? notes,
    DateTime? performedAt,
  }) {
    return WorkoutLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      performedAt: performedAt ?? this.performedAt,
    );
  }

  @override
  String toString() =>
      'WorkoutLogModel(id: $id, exercise: $exerciseName, sets: $sets, reps: $reps)';
}
