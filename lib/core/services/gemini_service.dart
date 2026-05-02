import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/constants.dart';

/// Service for communicating with Google Gemini AI.
///
/// Initializes a [GenerativeModel] with the `gemini-1.5-pro` model and
/// a fitness-coach system instruction. Supports both single-shot and
/// streaming responses via a persistent [ChatSession].
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  GenerativeModel? _model;
  ChatSession? _chat;

  // ───────────────────────────────────────────────────────────────────────────
  // SYSTEM INSTRUCTION
  // ───────────────────────────────────────────────────────────────────────────
  static const _systemInstruction = '''
You are FitPro AI Coach, a professional and friendly fitness assistant.

Your capabilities:
- Create personalized workout plans based on user goals, fitness level, and available equipment
- Provide detailed nutrition advice including meal plans, macros, and supplement guidance
- Offer exercise form tips with step-by-step instructions
- Suggest recovery strategies including stretching, sleep, and rest day activities
- Answer general health and fitness questions with evidence-based information

Guidelines:
- Always be encouraging, supportive, and motivational
- Provide structured responses using numbered lists or bullet points when appropriate
- Use relevant emojis to make responses engaging (💪🏋️‍♂️🥗🔥)
- If asked about medical conditions, recommend consulting a healthcare professional
- Keep responses concise but informative
- When suggesting workouts, include sets, reps, and rest periods
- Adapt your language to be easy to understand for all fitness levels
- Respond in the same language the user uses (e.g., if they write in Indonesian, respond in Indonesian)
''';

  // ───────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ───────────────────────────────────────────────────────────────────────────

  /// Initializes the model and starts a new chat session.
  void _ensureInitialized() {
    if (_model != null) return;

    final apiKey = AppConstants.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      debugPrint('[GeminiService] ERROR: GEMINI_API_KEY is empty!');
      throw Exception('GEMINI_API_KEY tidak ditemukan di .env');
    }

    debugPrint('[GeminiService] Initializing with model: gemini-flash-latest');
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      systemInstruction: Content.text(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );

    _chat = _model!.startChat();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEND MESSAGE (single-shot)
  // ───────────────────────────────────────────────────────────────────────────

  /// Sends a message and waits for the full response.
  Future<String> sendMessage(String message) async {
    _ensureInitialized();

    try {
      debugPrint('[GeminiService] Sending message: $message');
      final response = await _chat!.sendMessage(Content.text(message));
      debugPrint('[GeminiService] Received response: ${response.text}');
      return response.text ?? 'Maaf, saya tidak bisa memproses respons.';
    } on GenerativeAIException catch (e) {
      debugPrint('[GeminiService] GenerativeAIException: ${e.message}');
      throw _mapError(e);
    } catch (e) {
      debugPrint('[GeminiService] Unexpected Error: $e');
      throw Exception('Gagal menghubungi AI: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEND MESSAGE (streaming)
  // ───────────────────────────────────────────────────────────────────────────

  /// Sends a message and returns a stream of partial response chunks.
  Stream<String> sendMessageStream(String message) async* {
    _ensureInitialized();

    try {
      debugPrint('[GeminiService] Starting stream for: $message');
      final response = _chat!.sendMessageStream(Content.text(message));
      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          debugPrint('[GeminiService] Received chunk: ${text.length} chars');
          yield text;
        } else {
          debugPrint(
            '[GeminiService] Warning: Received empty chunk or blocked by safety.',
          );
          if (chunk.candidates.isNotEmpty) {
            final reason = chunk.candidates.first.finishReason;
            debugPrint('[GeminiService] Finish reason: $reason');
          }
        }
      }
    } on GenerativeAIException catch (e) {
      debugPrint('[GeminiService] Stream GenerativeAIException: ${e.message}');
      throw _mapError(e);
    } catch (e) {
      debugPrint('[GeminiService] Stream Unexpected Error: $e');
      throw Exception('Gagal menghubungi AI: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RESET CHAT
  // ───────────────────────────────────────────────────────────────────────────

  /// Resets the chat session (clears history).
  void resetChat() {
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ERROR MAPPING
  // ───────────────────────────────────────────────────────────────────────────
  Exception _mapError(GenerativeAIException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('rate limit') || msg.contains('quota') || msg.contains('429')) {
      return Exception(
        'Batas permintaan tercapai. Tunggu beberapa saat dan coba lagi.',
      );
    }
    if (msg.contains('safety')) {
      return Exception(
        'Pesan tidak dapat diproses karena filter keamanan. '
        'Coba ubah pertanyaan Anda.',
      );
    }
    if (msg.contains('not found') || msg.contains('model')) {
      return Exception(
        'Model AI tidak tersedia. Periksa konfigurasi API key Anda.',
      );
    }
    return Exception('Kesalahan AI: ${e.message}');
  }
}
