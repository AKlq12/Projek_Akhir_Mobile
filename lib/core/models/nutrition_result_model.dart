import 'package:uuid/uuid.dart';

/// A record of a food nutrition scan result.
///
/// Stores the analysis text from Gemini, the local image path,
/// and a timestamp. Supports JSON serialization for Hive persistence.
class NutritionResult {
  final String id;
  final String imagePath;
  final String resultText;
  final DateTime timestamp;

  NutritionResult({
    String? id,
    required this.imagePath,
    required this.resultText,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Creates a copy with updated fields.
  NutritionResult copyWith({String? resultText}) => NutritionResult(
        id: id,
        imagePath: imagePath,
        resultText: resultText ?? this.resultText,
        timestamp: timestamp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'resultText': resultText,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NutritionResult.fromJson(Map<String, dynamic> json) =>
      NutritionResult(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        resultText: json['resultText'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
