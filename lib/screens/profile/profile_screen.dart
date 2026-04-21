import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/supabase_service.dart';

/// Profile Screen — displays user info, fitness stats, and settings menu.
///
/// Design follows the FitPro Volt reference:
/// - Volt-gradient header with back arrow & settings icon
/// - Hero avatar + name/email + Edit Profile button
/// - Stats card (Workouts, Day Streak, Steps)
/// - Fitness Overview grid (Height, Weight, Goal, BMI)
/// - Preferences menu list
/// - Logout button
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalWorkouts = 0;
  int _streak = 0;
  int _totalSteps = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Store provider before async gap
      final homeProvider = context.read<HomeProvider>();
      
      final supabase = SupabaseService.instance;
      final workoutCount = await supabase.getTotalWorkoutCount();
      final streakCount = await supabase.getWorkoutStreak();

      // Get total steps from HomeProvider if available
      final steps = homeProvider.todayStepCount;

      if (mounted) {
        setState(() {
          _totalWorkouts = workoutCount;
          _streak = streakCount;
          _totalSteps = steps;
        });
      }
    } catch (e) {
      // Ignore gracefully
    }
  }

  String _formatSteps(int steps) {
    if (steps >= 1000000) {
      return '${(steps / 1000000).toStringAsFixed(0)}M';
    } else if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(0)}K';
    }
    return steps.toString();
  }

  double _calculateBMI(double? heightCm, double? weightKg) {
    if (heightCm == null || weightKg == null || heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Volt Gradient Header ──────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(context)),

          // ── Hero Profile Section ─────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeroProfile(context, user)),

          // ── Stats Card ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _buildStatsCard(context),
            ),
          ),

          // ── Fitness Overview ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _buildFitnessOverview(context, user),
            ),
          ),

          // ── Preferences Menu ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _buildPreferencesMenu(context),
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              child: Center(
                child: Text(
                  'FITPRO VOLT V1.0.0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER — Volt gradient App Bar
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              // Settings icon placeholder (no settings_screen needed)
              Icon(
                Icons.settings_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO PROFILE — Avatar + Name + Email + Edit Button
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroProfile(BuildContext context, user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Curved volt glow background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              // Avatar with white border
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerLowest,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    color: colorScheme.surfaceContainerHigh,
                  ),
                  child: ClipOval(
                    child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? Image.network(
                            user.avatarUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarFallback(context, user.fullName),
                          )
                        : _buildAvatarFallback(context, user.fullName),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                user.fullName.isNotEmpty ? user.fullName : 'User',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 4),

              // Email
              Text(
                user.email,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              // Edit Profile Button
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).pushNamed(
                    AppRoutes.editProfile,
                  );
                  if (result == true && mounted) {
                    context.read<AuthProvider>().refreshProfile();
                    _loadStats();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: colorScheme.onSurface,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildAvatarFallback(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      height: 100,
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS CARD — Workouts | Day Streak | Steps
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Workouts
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.fitness_center_rounded,
              value: _totalWorkouts.toString(),
              label: 'WORKOUTS',
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          // Day Streak
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.local_fire_department_rounded,
              value: _streak.toString(),
              label: 'DAY STREAK',
              fillIcon: true,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          // Steps
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.directions_walk_rounded,
              value: _formatSteps(_totalSteps),
              label: 'STEPS',
            ),
          ),
        ],
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    bool fillIcon = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FITNESS OVERVIEW — 2×2 Grid (Height, Weight, Goal, BMI)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFitnessOverview(BuildContext context, user) {
    final colorScheme = Theme.of(context).colorScheme;
    final bmi = _calculateBMI(user.heightCm, user.weightKg);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FITNESS OVERVIEW',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFitnessCard(
                  context,
                  icon: Icons.height_rounded,
                  label: 'Height',
                  value: user.heightCm != null
                      ? '${user.heightCm!.toInt()} cm'
                      : '-- cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFitnessCard(
                  context,
                  icon: Icons.monitor_weight_rounded,
                  label: 'Weight',
                  value: user.weightKg != null
                      ? '${user.weightKg!.toInt()} kg'
                      : '-- kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFitnessCard(
                  context,
                  icon: Icons.track_changes_rounded,
                  label: 'Goal',
                  value: user.fitnessGoal ?? 'Not Set',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFitnessCard(
                  context,
                  icon: Icons.show_chart_rounded,
                  label: 'BMI',
                  value: bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildFitnessCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colorScheme.onSurface),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREFERENCES MENU
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPreferencesMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'PREFERENCES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: colorScheme.onSurface,
            ),
          ),
        ),

        // Notification Settings
        _buildMenuItem(
          context,
          icon: Icons.notifications_rounded,
          label: 'Notification Settings',
          iconBgColor: colorScheme.onSurface,
          iconColor: colorScheme.primaryContainer,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.notificationSettings,
          ),
        ),
        const SizedBox(height: 10),

        // Appearance
        _buildMenuItem(
          context,
          icon: Icons.palette_rounded,
          label: 'Appearance',
          iconBgColor: colorScheme.primaryContainer,
          iconColor: colorScheme.onPrimaryContainer,
          onTap: () => _showAppearanceDialog(context),
        ),
        const SizedBox(height: 10),

        // Security & Biometric
        _buildMenuItem(
          context,
          icon: Icons.security_rounded,
          label: 'Security & Biometric',
          iconBgColor: colorScheme.onSurface,
          iconColor: colorScheme.primaryContainer,
          onTap: () {
            final authProvider = context.read<AuthProvider>();
            _showBiometricDialog(context, authProvider);
          },
        ),
        const SizedBox(height: 10),

        // About App
        _buildMenuItem(
          context,
          icon: Icons.info_rounded,
          label: 'About App',
          iconBgColor: colorScheme.primaryContainer,
          iconColor: colorScheme.onPrimaryContainer,
          onTap: () => _showAboutDialog(context),
        ),
        const SizedBox(height: 10),

        // Logout
        _buildLogoutButton(context),
      ],
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Center(
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.error.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: colorScheme.error,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Appearance',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded),
              title: Text(
                'Light Mode',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              trailing: themeProvider.themeMode == ThemeMode.light
                  ? const Icon(Icons.check_circle_rounded)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: Text(
                'Dark Mode',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              trailing: themeProvider.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle_rounded)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest_rounded),
              title: Text(
                'System Default',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              trailing: themeProvider.themeMode == ThemeMode.system
                  ? const Icon(Icons.check_circle_rounded)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBiometricDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Security & Biometric',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(
                    'Biometric Login',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    authProvider.biometricAvailable
                        ? 'Use fingerprint or face ID'
                        : 'Not available on this device',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  value: authProvider.biometricEnabled,
                  onChanged: authProvider.biometricAvailable
                      ? (val) {
                          authProvider.setBiometricEnabled(val);
                          setDialogState(() {});
                        }
                      : null,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'About FitPro',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FitPro Volt v1.0.0',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi Mobile Fitness — Tugas Akhir TPM\n\n'
              'Fitur:\n'
              '• Browse & search exercises (wger.de API)\n'
              '• AI Fitness Coach (Gemini)\n'
              '• Workout planning & tracking\n'
              '• Step counter & sensors\n'
              '• Nearby gyms (LBS)\n'
              '• Currency & timezone converter\n'
              '• Reaction Reflex mini game',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
