import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/chat_message_model.dart';
import '../services/gemini_service.dart';

/// Quick action presets for the AI Chat.
class QuickAction {
  final String label;
  final IconLabel icon;
  final String prompt;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.prompt,
  });
}

/// Icon labels for quick actions (mapped to icons in the UI).
enum IconLabel { workout, nutrition, form, recovery }

/// State management for the AI Chat screen.
///
/// Manages the message list, loading state, streaming responses,
/// and quick-action presets.
class ChatProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService.instance;

  // Current user ID for per-user persistence (chat history)
  String? _userId;
  static const String _chatBoxName = 'settings';

  // ───────────────────────────────────────────────────────────────────────────
  // STATE
  // ───────────────────────────────────────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<String>? _streamSub;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ───────────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS
  // ───────────────────────────────────────────────────────────────────────────
  static const List<QuickAction> quickActions = [
    QuickAction(
      label: 'Suggest Workout',
      icon: IconLabel.workout,
      prompt:
          'Suggest a complete workout routine for today. Include warm-up, main exercises with sets and reps, and cool-down.',
    ),
    QuickAction(
      label: 'Nutrition Tips',
      icon: IconLabel.nutrition,
      prompt:
          'Give me practical nutrition tips for muscle building. Include meal timing, macros, and food suggestions.',
    ),
    QuickAction(
      label: 'Form Check',
      icon: IconLabel.form,
      prompt:
          'Explain proper form for the most common compound exercises (squat, deadlift, bench press). Include common mistakes to avoid.',
    ),
    QuickAction(
      label: 'Recovery Advice',
      icon: IconLabel.recovery,
      prompt:
          'What are the best recovery strategies after an intense workout? Include stretching, nutrition, sleep tips.',
    ),
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // WELCOME MESSAGE
  // ───────────────────────────────────────────────────────────────────────────

  /// Initializes the chat with a welcome message if empty.
  void ensureWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage.ai(
          'Hi there! 💪 I\'m your AI Fitness Coach. Ask me anything about '
          'workouts, nutrition, exercise form, or let me create a '
          'personalized plan for you!',
        ),
      );
      _saveChatHistory();
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEND MESSAGE (streaming)
  // ───────────────────────────────────────────────────────────────────────────

  /// Sends a user message and streams the AI response.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _error = null;

    // Add user message
    _messages.add(ChatMessage.user(text.trim()));
    _isLoading = true;
    notifyListeners();

    // Add placeholder AI message for streaming
    final aiMessage = ChatMessage.ai('');
    _messages.add(aiMessage);
    notifyListeners();

    try {
      final buffer = StringBuffer();
      final stream = _gemini.sendMessageStream(text.trim());

      _streamSub = stream.listen(
        (chunk) {
          buffer.write(chunk);
          // Update the last message with accumulated text
          final index = _messages.indexWhere((m) => m.id == aiMessage.id);
          if (index != -1) {
            _messages[index] = aiMessage.copyWith(text: buffer.toString());
            notifyListeners();
          }
        },
        onDone: () {
          _isLoading = false;
          _streamSub = null;
          // If buffer is empty, provide fallback
          if (buffer.isEmpty) {
            final index = _messages.indexWhere((m) => m.id == aiMessage.id);
            if (index != -1) {
              _messages[index] = aiMessage.copyWith(
                text: '⚠️ Maaf, AI tidak memberikan respons. Pastikan API Key Gemini di file .env sudah benar dan koneksi internet stabil.',
              );
            }
          }
          _saveChatHistory();
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          _streamSub = null;
          _error = error.toString().replaceAll('Exception: ', '');
          // Remove empty AI message on error
          final index = _messages.indexWhere((m) => m.id == aiMessage.id);
          if (index != -1) {
            _messages[index] = aiMessage.copyWith(
              text: '⚠️ $_error',
            );
          }
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      // Update placeholder with error
      final index = _messages.indexWhere((m) => m.id == aiMessage.id);
      if (index != -1) {
        _messages[index] = aiMessage.copyWith(text: '⚠️ $_error');
      }
      _saveChatHistory();
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CLEAR CHAT
  // ───────────────────────────────────────────────────────────────────────────

  /// Clears all messages and resets the Gemini chat session.
  void clearChat() {
    _streamSub?.cancel();
    _streamSub = null;
    _messages.clear();
    _isLoading = false;
    _error = null;
    _gemini.resetChat();
    _messages.clear(); // Ensure welcome message clears everything
    ensureWelcomeMessage();
    _saveChatHistory();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PER-USER PERSISTENCE
  // ───────────────────────────────────────────────────────────────────────────

  /// Loads user-specific chat history from Hive.
  void loadUserData(String userId) {
    _userId = userId;

    try {
      final box = Hive.box(_chatBoxName);
      final historyRaw = box.get('chat_history_$userId') as String?;
      
      _messages.clear();
      if (historyRaw != null) {
        final list = jsonDecode(historyRaw) as List;
        for (final item in list) {
          _messages.add(ChatMessage.fromJson(item as Map<String, dynamic>));
        }
        
        // Feed previous messages into Gemini to maintain context
        _gemini.resetChat();
        // Just feed the context without streaming responses.
        // The gemini service might not have a direct "load history" method
        // without causing side effects. For a true implementation we would 
        // need to hydrate the GeminiService history.
      } else {
        ensureWelcomeMessage();
      }
    } catch (e) {
      debugPrint('[ChatProvider] Error loading chat history: $e');
      ensureWelcomeMessage();
    }
    
    notifyListeners();
  }

  void _saveChatHistory() {
    if (_userId == null) return;
    try {
      final box = Hive.box(_chatBoxName);
      // Limit saved history to last 50 messages to avoid huge Hive entries
      final messagesToSave = _messages.length > 50 
          ? _messages.sublist(_messages.length - 50) 
          : _messages;
      final data = messagesToSave.map((e) => e.toJson()).toList();
      box.put('chat_history_$_userId', jsonEncode(data));
    } catch (e) {
      debugPrint('[ChatProvider] Error saving chat history: $e');
    }
  }

  /// Resets all in-memory state. Called on user sign-out.
  void resetState() {
    _userId = null;
    _streamSub?.cancel();
    _streamSub = null;
    _messages.clear();
    _isLoading = false;
    _error = null;
    _gemini.resetChat();
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DISPOSE
  // ───────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
