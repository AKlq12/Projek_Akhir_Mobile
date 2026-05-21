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
Anda adalah FitPro AI Coach, asisten kebugaran yang profesional dan ramah.

Kemampuan Anda:
- Membuat rencana latihan yang dipersonalisasi berdasarkan tujuan, tingkat kebugaran, dan peralatan yang dimiliki pengguna
- Memberikan saran nutrisi secara mendetail termasuk rencana makan, makro nutrisi, dan panduan suplemen
- Menawarkan tips postur latihan dengan instruksi langkah demi langkah
- Menyarankan strategi pemulihan termasuk peregangan, tidur, dan aktivitas hari istirahat
- Menjawab pertanyaan seputar kesehatan dan kebugaran umum dengan informasi berbasis sains/bukti

Panduan:
- Selalu memberikan semangat, dukungan, dan motivasi
- Berikan respons terstruktur menggunakan daftar bernomor atau poin-poin (bullet points) jika sesuai
- Gunakan emoji yang relevan untuk membuat percakapan lebih menarik (💪🏋️‍♂️🥗🔥)
- Jika ditanya tentang kondisi medis yang serius, sarankan pengguna untuk berkonsultasi dengan profesional kesehatan/dokter
- Jaga agar respons tetap singkat, padat, dan informatif
- Saat menyarankan latihan, pastikan untuk menyertakan set, repetisi (reps), dan waktu istirahat
- Sesuaikan bahasa Anda agar mudah dipahami oleh semua tingkat kebugaran
- SELALU gunakan Bahasa Indonesia dalam setiap respons Anda, apa pun bahasa yang digunakan oleh pengguna.
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
  // FOOD NUTRITION ANALYSIS (Multimodal — Image + Text)
  // ───────────────────────────────────────────────────────────────────────────

  GenerativeModel? _nutritionModel;

  static const _nutritionSystemInstruction = '''
You are a professional nutritionist AI specializing in food recognition and nutritional analysis.

When given a food image, you MUST provide:

1. 🍽️ **Nama Makanan** — Identify all food items visible in the image
2. 📏 **Estimasi Porsi** — Estimate the portion size
3. 🔥 **Informasi Nutrisi** (per porsi):
   - Kalori (kkal)
   - Protein (g)
   - Karbohidrat (g)
   - Lemak (g)
   - Serat (g)
4. 💊 **Vitamin & Mineral** — Key vitamins and minerals present
5. 💡 **Tips Kesehatan** — Health tips or suggestions related to the food

Guidelines:
- If you cannot identify the food, say so honestly
- Provide estimated ranges when exact values are uncertain
- Use emojis to make the response engaging
- If the image is not food, politely inform the user
- Respond in the same language the user uses (default: Indonesian/Bahasa Indonesia)
- Format your response clearly with sections and bullet points
''';

  /// Ensures the nutrition model is initialized.
  void _ensureNutritionModelInitialized() {
    if (_nutritionModel != null) return;

    final apiKey = AppConstants.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY tidak ditemukan di .env');
    }

    debugPrint('[GeminiService] Initializing nutrition model');
    _nutritionModel = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      systemInstruction: Content.text(_nutritionSystemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 0.9,
        maxOutputTokens: 2048,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  /// Analyzes a food image and returns nutrition info as a stream.
  Stream<String> analyzeFoodStream(
    Uint8List imageBytes,
    String mimeType,
  ) async* {
    _ensureNutritionModelInitialized();

    try {
      debugPrint(
        '[GeminiService] Analyzing food image (${imageBytes.length} bytes, $mimeType)',
      );

      final prompt = Content.multi([
        DataPart(mimeType, imageBytes),
        TextPart(
          'Analisis makanan pada gambar ini dan berikan informasi nutrisi lengkap. '
          'Gunakan format yang rapi dengan emoji.',
        ),
      ]);

      final response = _nutritionModel!.generateContentStream([prompt]);
      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          debugPrint(
            '[GeminiService] Food analysis chunk: ${text.length} chars',
          );
          yield text;
        }
      }
    } on GenerativeAIException catch (e) {
      debugPrint(
        '[GeminiService] Food analysis GenerativeAIException: ${e.message}',
      );
      throw _mapError(e);
    } catch (e) {
      debugPrint('[GeminiService] Food analysis error: $e');
      throw Exception('Gagal menganalisis gambar makanan: $e');
    }
  }

  /// Analyzes a food image and returns complete nutrition info.
  Future<String> analyzeFood(Uint8List imageBytes, String mimeType) async {
    _ensureNutritionModelInitialized();

    try {
      debugPrint(
        '[GeminiService] Analyzing food image (${imageBytes.length} bytes, $mimeType)',
      );

      final prompt = Content.multi([
        DataPart(mimeType, imageBytes),
        TextPart(
          'Analisis makanan pada gambar ini dan berikan informasi nutrisi lengkap. '
          'Gunakan format yang rapi dengan emoji.',
        ),
      ]);

      final response = await _nutritionModel!.generateContent([prompt]);
      debugPrint('[GeminiService] Food analysis complete');
      return response.text ?? 'Maaf, tidak dapat menganalisis gambar makanan.';
    } on GenerativeAIException catch (e) {
      debugPrint(
        '[GeminiService] Food analysis GenerativeAIException: ${e.message}',
      );
      throw _mapError(e);
    } catch (e) {
      debugPrint('[GeminiService] Food analysis error: $e');
      throw Exception('Gagal menganalisis gambar makanan: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ERROR MAPPING
  // ───────────────────────────────────────────────────────────────────────────
  Exception _mapError(GenerativeAIException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('rate limit') ||
        msg.contains('quota') ||
        msg.contains('429')) {
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
