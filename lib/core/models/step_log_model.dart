/// Step log model that maps to the `step_logs` table in Supabase.
///
/// Records daily step count, distance, and estimated calorie burn.
class StepLogModel {
  final String id;
  final String userId;
  final int stepCount;
  final DateTime date;
  final double? distanceKm;
  final double? caloriesBurned;

  const StepLogModel({
    required this.id,
    required this.userId,
    required this.stepCount,
    required this.date,
    this.distanceKm,
    this.caloriesBurned,
  });

  factory StepLogModel.fromJson(Map<String, dynamic> json) {
    return StepLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      stepCount: json['step_count'] as int,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'step_count': stepCount,
      'date': date.toIso8601String().split('T').first,
      'distance_km': distanceKm,
      'calories_burned': caloriesBurned,
    };
  }

  /// For upsert (insert or update on conflict).
  Map<String, dynamic> toUpsertJson() {
    return {
      'user_id': userId,
      'step_count': stepCount,
      'date': date.toIso8601String().split('T').first,
      'distance_km': distanceKm,
      'calories_burned': caloriesBurned,
    };
  }

  StepLogModel copyWith({
    String? id,
    String? userId,
    int? stepCount,
    DateTime? date,
    double? distanceKm,
    double? caloriesBurned,
  }) {
    return StepLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stepCount: stepCount ?? this.stepCount,
      date: date ?? this.date,
      distanceKm: distanceKm ?? this.distanceKm,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }

  @override
  String toString() =>
      'StepLogModel(date: ${date.toIso8601String().split('T').first}, steps: $stepCount)';
}
