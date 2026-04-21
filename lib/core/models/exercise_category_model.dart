/// Model for exercise categories from wger.de API.
///
/// Maps to `/api/v2/exercisecategory/` endpoint.
/// Categories: Abs(10), Arms(8), Back(12), Calves(14),
/// Cardio(15), Chest(11), Legs(9), Shoulders(13).
class ExerciseCategory {
  final int id;
  final String name;

  const ExerciseCategory({
    required this.id,
    required this.name,
  });

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    return ExerciseCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  /// Returns a Material Icons icon name for each category.
  String get iconName {
    switch (id) {
      case 10: return 'fitness_center'; // Abs
      case 8:  return 'front_hand';     // Arms
      case 12: return 'accessibility_new'; // Back
      case 14: return 'directions_walk'; // Calves
      case 15: return 'directions_run';  // Cardio
      case 11: return 'expand';          // Chest
      case 9:  return 'airline_seat_legroom_extra'; // Legs
      case 13: return 'sports_martial_arts'; // Shoulders
      default: return 'fitness_center';
    }
  }
}
