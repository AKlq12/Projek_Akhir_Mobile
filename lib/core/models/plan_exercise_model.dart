/// Plan exercise model that maps to the `plan_exercises` join table.
///
/// Links an exercise to a [WorkoutPlanModel] with target sets/reps/weight.
class PlanExerciseModel {
  final String id;
  final String planId;
  final int exerciseId;
  final String exerciseName;
  final int? targetSets;
  final int? targetReps;
  final double? targetWeightKg;
  final int sortOrder;

  const PlanExerciseModel({
    required this.id,
    required this.planId,
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets,
    this.targetReps,
    this.targetWeightKg,
    this.sortOrder = 0,
  });

  factory PlanExerciseModel.fromJson(Map<String, dynamic> json) {
    return PlanExerciseModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      exerciseId: json['exercise_id'] as int,
      exerciseName: json['exercise_name'] as String,
      targetSets: json['target_sets'] as int?,
      targetReps: json['target_reps'] as int?,
      targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight_kg': targetWeightKg,
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'plan_id': planId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight_kg': targetWeightKg,
      'sort_order': sortOrder,
    };
  }

  PlanExerciseModel copyWith({
    String? id,
    String? planId,
    int? exerciseId,
    String? exerciseName,
    int? targetSets,
    int? targetReps,
    double? targetWeightKg,
    int? sortOrder,
  }) {
    return PlanExerciseModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() =>
      'PlanExerciseModel(id: $id, exercise: $exerciseName, sets: $targetSets×$targetReps)';
}
