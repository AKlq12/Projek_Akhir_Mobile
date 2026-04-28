import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/sensor_provider.dart';
import '../core/providers/tools_provider.dart';
import '../core/services/notification_service.dart';
import '../core/services/supabase_service.dart';

/// Splash screen with dumbbell logo, FITPRO branding, and animated loading bar.
///
/// On launch it initializes [AuthProvider], then:
/// - If authenticated → navigates to main screen
/// - If not → navigates to login screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();

    // Initialize auth (check existing session, biometric availability)
    await authProvider.init();

    // Wait for at least 2.5s for splash animation
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Navigate based on auth state
    if (authProvider.isAuthenticated) {
      // Load per-user data
      context.read<ToolsProvider>().loadUserData(authProvider.user.id);
      context.read<SensorProvider>().loadUserData(authProvider.user.id);
      context.read<ChatProvider>().loadUserData(authProvider.user.id);
      
      // Schedule workout reminder based on saved settings
      _scheduleReminder();
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  /// Loads notification settings and schedules the daily workout reminder.
  Future<void> _scheduleReminder() async {
    try {
      final settings =
          await SupabaseService.instance.getNotificationSettings();
      if (settings.workoutReminder) {
        final parts = settings.reminderTime.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        await NotificationService.instance.scheduleWorkoutReminder(
          hour: hour,
          minute: minute,
        );
      }
    } catch (e) {
      // Non-critical — silently fail
      debugPrint('[Splash] Schedule reminder error: $e');
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Volt neon color (matches the reference design)
    const voltColor = Color(0xFFDFFF00);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo Container ──────────────────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: -5,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: voltColor,
                  size: 56,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 24),

            // ── Brand Name ──────────────────────────────────────────────
            Text(
              'FITPRO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -1,
                height: 1,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0, duration: 500.ms),

            const SizedBox(height: 64),

            // ── Loading Progress Bar ────────────────────────────────────
            SizedBox(
              width: 180,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E3E4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Progress fill
                        FractionallySizedBox(
                          widthFactor: _progressController.value * 0.7 + 0.1,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: voltColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
