import 'package:uuid/uuid.dart';

/// Represents a role in the chat conversation.
enum MessageRole { user, ai }

/// A single chat message in the AI Coach conversation.
///
/// Each message has a unique [id], the [text] content, a [role] indicating
/// whether it was sent by the user or the AI, and a [timestamp].
class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.text,
    required this.role,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Whether this message was sent by the user.
  bool get isUser => role == MessageRole.user;

  /// Whether this message was sent by the AI.
  bool get isAi => role == MessageRole.ai;

  /// Creates a user message.
  factory ChatMessage.user(String text) => ChatMessage(
        text: text,
        role: MessageRole.user,
      );

  /// Creates an AI message.
  factory ChatMessage.ai(String text) => ChatMessage(
        text: text,
        role: MessageRole.ai,
      );

  /// Creates a copy with updated text (used for streaming).
  ChatMessage copyWith({String? text}) => ChatMessage(
        id: id,
        text: text ?? this.text,
        role: role,
        timestamp: timestamp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        role: MessageRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => MessageRole.user,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
