import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/local_cache_service.dart';
import 'core/services/notification_service.dart';

import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/exercise_provider.dart';
import 'core/providers/home_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/gym_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/sensor_provider.dart';
import 'core/providers/tools_provider.dart';
import 'core/providers/workout_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/exercise/exercise_list_screen.dart';
import 'screens/exercise/exercise_detail_screen.dart';
import 'screens/exercise/exercise_category_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/workout/workout_list_screen.dart';
import 'screens/workout/workout_create_screen.dart';
import 'screens/workout/workout_session_screen.dart';
import 'screens/tools/currency_converter_screen.dart';
import 'screens/tools/nearby_gym_screen.dart';
import 'screens/tools/shake_exercise_screen.dart';
import 'screens/tools/step_counter_screen.dart';
import 'screens/tools/mini_game_screen.dart';
import 'screens/tools/timezone_converter_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/notification_settings_screen.dart';
import 'screens/profile/feedback_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize local cache (opens all Hive boxes)
  await LocalCacheService.instance.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize notification service
  await NotificationService.instance.init();

  // Initialize theme provider (reads persisted preference)
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => ToolsProvider()),
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const FitProApp(),
    ),
  );
}

class FitProApp extends StatelessWidget {
  const FitProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Update system UI overlay based on current theme
        SystemChrome.setSystemUIOverlayStyle(
          themeProvider.isDarkMode
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFF1B1E32),
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFFFFFFFF),
                ),
        );

        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Routing
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.otpVerification: (_) => const OtpVerificationScreen(),
            AppRoutes.main: (_) => const MainShell(),
            AppRoutes.exercises: (_) => const ExerciseListScreen(),
            AppRoutes.exerciseDetail: (_) => const ExerciseDetailScreen(),
            AppRoutes.exerciseCategory: (_) => const ExerciseCategoryScreen(),
            AppRoutes.workoutList: (_) => const WorkoutListScreen(),
            AppRoutes.workoutCreate: (_) => const WorkoutCreateScreen(),
            AppRoutes.workoutSession: (_) => const WorkoutSessionScreen(),
            AppRoutes.currencyConverter: (_) => const CurrencyConverterScreen(),
            AppRoutes.timezoneConverter: (_) => const TimezoneConverterScreen(),
            AppRoutes.nearbyGym: (_) => const NearbyGymScreen(),
            AppRoutes.stepCounter: (_) => const StepCounterScreen(),
            AppRoutes.shakeExercise: (_) => const ShakeExerciseScreen(),
            AppRoutes.miniGame: (_) => const MiniGameScreen(),
            AppRoutes.editProfile: (_) => const EditProfileScreen(),
            AppRoutes.notificationSettings: (_) => const NotificationSettingsScreen(),
            AppRoutes.feedback: (_) => const FeedbackScreen(),
          },
        );
      },
    );
  }
}
