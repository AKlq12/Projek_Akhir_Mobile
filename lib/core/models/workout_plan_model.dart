/// Workout plan model that maps to the `workout_plans` table in Supabase.
///
/// Represents a user-created workout plan (e.g. "Push Day", "Leg Day").
class WorkoutPlanModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? dayOfWeek;
  final DateTime createdAt;

  const WorkoutPlanModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.dayOfWeek,
    required this.createdAt,
  });

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      dayOfWeek: json['day_of_week'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'day_of_week': dayOfWeek,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'day_of_week': dayOfWeek,
    };
  }

  WorkoutPlanModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? dayOfWeek,
    DateTime? createdAt,
  }) {
    return WorkoutPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'WorkoutPlanModel(id: $id, name: $name)';
}
