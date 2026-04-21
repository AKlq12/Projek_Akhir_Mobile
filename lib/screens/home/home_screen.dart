import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/workout_provider.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/weekly_chart.dart';
import '../main_shell.dart';

/// Home Dashboard screen — the main landing page after login.
///
/// Design follows the FitPro Volt reference:
/// - Section A: Top App Bar (greeting + avatar)
/// - Section B: Today's Stats (horizontal scroll of circular stat cards)
/// - Section C: Today's Workout (gradient hero card with CTA)
/// - Section D: Quick Actions (2×2 grid)
/// - Section E: Weekly Activity (bar chart)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadDashboard();
    });
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, homeProvider, _) {
            return RefreshIndicator(
              color: colorScheme.primaryContainer,
              onRefresh: () => homeProvider.refreshDashboard(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── Top App Bar ─────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader(context)),

                  // ── Today's Stats ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildTodayStats(context, homeProvider),
                  ),

                  // ── Today's Workout ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildTodayWorkout(context, homeProvider),
                  ),

                  // ── Quick Actions ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildQuickActions(context),
                  ),

                  // ── Weekly Activity ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildWeeklyActivity(context, homeProvider),
                  ),

                  // Bottom spacing for nav bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION A — Top App Bar / Header
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final firstName = user.fullName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName 👋',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ready to workout?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Avatar
          GestureDetector(
            onTap: () {
              final shell = context.findAncestorStateOfType<MainShellState>();
              shell?.switchTab(4); // Profile tab
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primaryContainer,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            child: Stack(
              children: [
                ClipOval(
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? Image.network(
                          user.avatarUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(
                              context, firstName),
                        )
                      : _buildAvatarFallback(context, firstName),
                ),
                // Online indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildAvatarFallback(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION B — Today's Stats
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTodayStats(BuildContext context, HomeProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Stats",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '', // Empty details string as requested
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Horizontal scrollable stat cards
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              children: [
                // Steps
                StatCard(
                  value: _formatNumber(provider.todayStepCount),
                  label: 'steps',
                  progress: provider.stepProgress,
                  icon: Icons.directions_walk_rounded,
                  delay: 150.ms,
                ),
                const SizedBox(width: 14),

                // Calories
                StatCard(
                  value: provider.todayCalories.toInt().toString(),
                  label: 'kcal burned',
                  progress: provider.calorieProgress,
                  icon: Icons.local_fire_department_rounded,
                  delay: 250.ms,
                ),
                const SizedBox(width: 14),

                // Workout Duration
                StatCard(
                  value: provider.todayWorkoutMinutes.toString(),
                  label: 'min workout',
                  progress: provider.workoutProgress,
                  icon: Icons.timer_rounded,
                  delay: 350.ms,
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION C — Today's Workout (Hero Card)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTodayWorkout(BuildContext context, HomeProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPlan = provider.todayPlan != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withValues(alpha: 0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Title
              Text(
                hasPlan
                    ? provider.todayPlan!.name
                    : 'No Workout Today',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onPrimaryContainer,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle info chips
              Row(
                children: [
                  if (hasPlan) ...[
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 14,
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.todayExerciseCount} exercises',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '~${provider.todayPlanEstimatedMinutes} min',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ] else
                    Text(
                      'Create a plan to get started',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // CTA Button
              GestureDetector(
                onTap: () {
                  if (hasPlan) {
                    // Start workout session
                    final wp = context.read<WorkoutProvider>();
                    final hp = context.read<HomeProvider>();
                    if (hp.todayPlan != null) {
                      final exercises = hp.todayPlanExercises;
                      if (exercises.isNotEmpty) {
                        wp.startSession(hp.todayPlan!, exercises);
                        Navigator.of(context)
                            .pushNamed(AppRoutes.workoutSession);
                      }
                    }
                  } else {
                    // Navigate to create plan
                    context.read<WorkoutProvider>().resetForm();
                    Navigator.of(context)
                        .pushNamed(AppRoutes.workoutCreate);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primaryContainer
                            .withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    hasPlan ? 'START WORKOUT' : 'CREATE PLAN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colorScheme.primaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION D — Quick Actions (2×2 Grid)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final actions = [
      _QuickAction(
        icon: Icons.fitness_center_rounded,
        label: 'Workouts',
        onTap: () {
          // Switch to exercises tab via the parent MainShell
          final shell = context.findAncestorStateOfType<MainShellState>();
          shell?.switchTab(1);
        },
      ),
      _QuickAction(
        icon: Icons.smart_toy_rounded,
        label: 'AI Coach',
        onTap: () {
          final shell = context.findAncestorStateOfType<MainShellState>();
          shell?.switchTab(3);
        },
      ),
      _QuickAction(
        icon: Icons.location_on_rounded,
        label: 'Gyms',
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.nearbyGym);
        },
      ),
      _QuickAction(
        icon: Icons.sports_esports_rounded,
        label: 'Mini Game',
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.miniGame);
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          )
              .animate(delay: 300.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;

              return GestureDetector(
                onTap: action.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon Circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            action.icon,
                            size: 28,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(
                      delay: Duration(milliseconds: 350 + (index * 80)))
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION E — Weekly Activity
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWeeklyActivity(BuildContext context, HomeProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'This Week',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate(delay: 350.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Chart
          WeeklyChart(data: provider.weeklyActivity),
        ],
      ),
    );
  }
}

/// Internal data class for quick action items.
class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
