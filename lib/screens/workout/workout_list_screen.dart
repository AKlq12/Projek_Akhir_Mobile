import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/routes.dart';
import '../../core/providers/workout_provider.dart';
import '../../core/models/workout_plan_model.dart';
import '../../core/models/plan_exercise_model.dart';

/// Workout plans list screen — view, filter, and manage workout plans.
///
/// Design adapted from the dark-theme reference to the FitPro light theme:
/// white card backgrounds, neon-volt accent bar, day filter chips,
/// exercise count/duration info, and FAB for creating new plans.
class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkoutProvider>();
      if (provider.plans.isEmpty) {
        provider.loadPlans();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            _buildHeader(context),

            // ── Day Filter Chips ─────────────────────────────────────
            _buildDayFilter(context),

            const SizedBox(height: 8),

            // ── Plan List ────────────────────────────────────────────
            Expanded(child: _buildPlanList(context)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Workouts',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              color: colorScheme.onSurface,
              size: 22,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAY FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDayFilter(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            children: [
              // "All" chip
              _buildFilterChip(
                context,
                label: 'All',
                isSelected: provider.selectedDayFilter == null,
                onTap: () => provider.setDayFilter(null),
              ),
              const SizedBox(width: 10),
              // Day chips
              ..._days.map((day) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildFilterChip(
                      context,
                      label: day,
                      isSelected: provider.selectedDayFilter == day,
                      onTap: () => provider.setDayFilter(day),
                    ),
                  )),
            ],
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: isSelected
              ? null
              : Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAN LIST
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPlanList(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.plans.isEmpty) {
          return _buildShimmer(context);
        }

        final plans = provider.filteredPlans;

        if (plans.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primaryContainer,
          onRefresh: () => provider.loadPlans(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final exercises = provider.planExercises[plan.id] ?? [];
              return _WorkoutPlanCard(
                plan: plan,
                exercises: exercises,
                index: index,
                onStart: () => _startWorkout(plan, exercises),
                onEdit: () => _editPlan(plan, exercises),
                onDelete: () => _deletePlan(plan.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Workout Plans',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first plan to get started',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.workoutCreate),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'CREATE PLAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHigh,
          highlightColor: colorScheme.surfaceContainerLowest,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFAB(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        context.read<WorkoutProvider>().resetForm();
        Navigator.of(context).pushNamed(AppRoutes.workoutCreate);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          size: 32,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  void _startWorkout(
      WorkoutPlanModel plan, List<PlanExerciseModel> exercises) {
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add exercises to this plan first',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<WorkoutProvider>().startSession(plan, exercises);
    Navigator.of(context).pushNamed(AppRoutes.workoutSession);
  }

  void _editPlan(
      WorkoutPlanModel plan, List<PlanExerciseModel> exercises) {
    context.read<WorkoutProvider>().initFormForEdit(plan, exercises);
    Navigator.of(context).pushNamed(
      AppRoutes.workoutCreate,
      arguments: plan.id,
    );
  }

  Future<void> _deletePlan(String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Plan?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          content: Text(
            'This will permanently delete this workout plan and all its exercises.',
            style: GoogleFonts.plusJakartaSans(
              color: cs.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: cs.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await context.read<WorkoutProvider>().deletePlan(planId);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WORKOUT PLAN CARD
// ═════════════════════════════════════════════════════════════════════════════
class _WorkoutPlanCard extends StatelessWidget {
  final WorkoutPlanModel plan;
  final List<PlanExerciseModel> exercises;
  final int index;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkoutPlanCard({
    required this.plan,
    required this.exercises,
    required this.index,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final estimatedMinutes = exercises.length * 8;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onStart,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 5,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day label + More menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (plan.dayOfWeek ?? 'ANYTIME').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                          _buildMoreMenu(context),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Plan name
                      Text(
                        plan.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Exercise count + duration
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exercises.length} exercises',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$estimatedMinutes min',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Exercise pills
                      if (exercises.isNotEmpty)
                        _buildExercisePills(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + (index * 80)))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildMoreMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colorScheme.surfaceContainerLowest,
      onSelected: (value) {
        if (value == 'start') onStart();
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'start',
          child: Row(
            children: [
              Icon(Icons.play_arrow_rounded,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('Start Workout',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded,
                  size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Edit Plan',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 20, color: colorScheme.error),
              const SizedBox(width: 8),
              Text('Delete',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExercisePills(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shown = exercises.take(3).toList();
    final remaining = exercises.length - shown.length;

    return Row(
      children: [
        ...shown.map((ex) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '+$remaining MORE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}
