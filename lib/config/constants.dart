import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized constants and API configuration for FitPro.
///
/// All API keys are loaded from the `.env` file via flutter_dotenv.
/// Base URLs and app-wide constants live here to avoid magic strings.
class AppConstants {
  AppConstants._();

  // ─────────────────────────────────────────────────────────────────────────
  // APP INFO
  // ─────────────────────────────────────────────────────────────────────────
  static const String appName = 'FitPro';
  static const String appVersion = '0.1.0';

  // ─────────────────────────────────────────────────────────────────────────
  // SUPABASE
  // ─────────────────────────────────────────────────────────────────────────
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // ─────────────────────────────────────────────────────────────────────────
  // WGER.DE API
  // ─────────────────────────────────────────────────────────────────────────
  static const String wgerBaseUrl = 'https://wger.de/api/v2';
  static String get wgerApiKey => dotenv.env['WGER_API_KEY'] ?? '';

  /// Endpoints
  static const String wgerExerciseCategory = '$wgerBaseUrl/exercisecategory/';
  static const String wgerExercise = '$wgerBaseUrl/exercise/';
  static const String wgerExerciseInfo = '$wgerBaseUrl/exerciseinfo/';
  static const String wgerExerciseImage = '$wgerBaseUrl/exerciseimage/';
  static const String wgerMuscle = '$wgerBaseUrl/muscle/';
  static const String wgerEquipment = '$wgerBaseUrl/equipment/';

  // ─────────────────────────────────────────────────────────────────────────
  // EXCHANGE RATE API
  // ─────────────────────────────────────────────────────────────────────────
  static String get exchangeRateApiKey =>
      dotenv.env['EXCHANGE_RATE_API_KEY'] ?? '';
  static String get exchangeRateBaseUrl =>
      'https://v6.exchangerate-api.com/v6/$exchangeRateApiKey';

  // ─────────────────────────────────────────────────────────────────────────
  // GOOGLE GEMINI AI
  // ─────────────────────────────────────────────────────────────────────────
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ─────────────────────────────────────────────────────────────────────────
  // OPENSTREETMAP / OVERPASS (LBS)
  // ─────────────────────────────────────────────────────────────────────────
  static const String overpassApiUrl =
      'https://overpass-api.de/api/interpreter';

  // ─────────────────────────────────────────────────────────────────────────
  // DEFAULTS & LIMITS
  // ─────────────────────────────────────────────────────────────────────────
  static const int defaultStepGoal = 10000;
  static const int apiTimeoutSeconds = 15;
  static const int exercisePageSize = 20;
  static const String defaultLanguageId = '2'; // English
  static const double defaultNearbyRadiusKm = 5.0;
}
