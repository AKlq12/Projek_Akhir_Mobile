class FeedbackModel {
  final String id;
  final String userId;
  final String suggestion;
  final String impression;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.suggestion,
    required this.impression,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      suggestion: json['suggestion'] as String,
      impression: json['impression'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'suggestion': suggestion,
      'impression': impression,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
