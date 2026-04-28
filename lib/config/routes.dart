/// Named route constants for FitPro navigation.
///
/// All route strings are defined here to prevent typos
/// and allow centralized route management.
class AppRoutes {
  AppRoutes._();

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';

  // ── Main Tabs ──────────────────────────────────────────────────────────
  static const String main = '/main';
  static const String home = '/home';
  static const String exercises = '/exercises';
  static const String tools = '/tools';
  static const String aiChat = '/ai-chat';
  static const String profile = '/profile';

  // ── Exercise ───────────────────────────────────────────────────────────
  static const String exerciseDetail = '/exercise/detail';
  static const String exerciseCategory = '/exercise/category';

  // ── Workout ────────────────────────────────────────────────────────────
  static const String workoutList = '/workout/list';
  static const String workoutCreate = '/workout/create';
  static const String workoutDetail = '/workout/detail';
  static const String workoutSession = '/workout/session';

  // ── Tools ──────────────────────────────────────────────────────────────
  static const String currencyConverter = '/tools/currency';
  static const String timezoneConverter = '/tools/timezone';
  static const String nearbyGym = '/tools/nearby-gym';
  static const String miniGame = '/tools/mini-game';
  static const String stepCounter = '/tools/step-counter';
  static const String shakeExercise = '/tools/shake-exercise';

  // ── Profile ────────────────────────────────────────────────────────────
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings';
  static const String notificationSettings = '/profile/notification-settings';
  static const String feedback = '/profile/feedback';
}
