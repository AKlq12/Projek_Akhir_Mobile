import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/providers/workout_provider.dart';
import '../../core/services/notification_service.dart';

/// Active workout session screen — tracks sets, reps, weight, and rest.
///
/// Adapted from the dark-theme reference to the FitPro light theme:
/// clean white background, gradient CTA buttons, input card, progress bar,
/// exercise flow carousel, and session timer.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleClose(context);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Consumer<WorkoutProvider>(
            builder: (context, provider, _) {
              if (provider.activePlan == null) {
                return const Center(child: Text('No active session'));
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Top App Bar ─────────────────────────────────────
                    _buildTopBar(context, provider),

                    // ── Current Exercise ────────────────────────────────
                    _buildCurrentExercise(context, provider),

                    // ── Progress Bar ────────────────────────────────────
                    _buildProgressBar(context, provider),

                    // ── Input Card ──────────────────────────────────────
                    _buildInputCard(context, provider),

                    // ── Action Buttons ───────────────────────────────────
                    _buildActionButtons(context, provider),

                    // ── Workout Flow ────────────────────────────────────
                    _buildWorkoutFlow(context, provider),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          GestureDetector(
            onTap: () => _handleClose(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurface,
                size: 22,
              ),
            ),
          ),

          // Plan name
          Text(
            provider.activePlan!.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),

          // Timer
          Text(
            provider.sessionTimerDisplay,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2E7D32), // Green for timer
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CURRENT EXERCISE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCurrentExercise(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final exercise = provider.currentExercise;
    if (exercise == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Exercise image placeholder
          Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.fitness_center_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Exercise name
          Text(
            exercise.exerciseName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Set indicator
          Text(
            'SET ${provider.currentSet} OF ${provider.totalSetsForCurrentExercise}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 20),

          // Reps × Weight display
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${provider.sessionReps} reps',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: ' × ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: '${provider.sessionWeight.toInt()} kg',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.05, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROGRESS BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProgressBar(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = provider.exerciseProgress;
    final total = provider.sessionExercises.length;
    final current = provider.currentExerciseIndex + 1;
    final percent = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXERCISE $current OF $total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInputCard(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Reps stepper
            _buildStepper(
              context,
              label: 'Reps',
              value: provider.sessionReps,
              onDecrement: () =>
                  provider.setSessionReps(provider.sessionReps - 1),
              onIncrement: () =>
                  provider.setSessionReps(provider.sessionReps + 1),
            ),

            const SizedBox(height: 20),

            // Weight stepper
            _buildStepper(
              context,
              label: 'Weight',
              suffix: 'kg',
              value: provider.sessionWeight.toInt(),
              onDecrement: () =>
                  provider.setSessionWeight(provider.sessionWeight - 2.5),
              onIncrement: () =>
                  provider.setSessionWeight(provider.sessionWeight + 2.5),
            ),

            const SizedBox(height: 20),

            // Notes
            TextField(
              controller: _notesController,
              onChanged: provider.setSessionNotes,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Add exercise notes...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.outline.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color:
                        colorScheme.primaryContainer.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms);
  }

  Widget _buildStepper(
    BuildContext context, {
    required String label,
    String? suffix,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (suffix != null)
                TextSpan(
                  text: ' $suffix',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Center(
                child: Text(
                  value.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActionButtons(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Complete Set button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: provider.isSessionComplete
                  ? () => _finishWorkout(context, provider)
                  : () async {
                      await provider.completeSet();
                      _notesController.clear();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor:
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              child: Text(
                provider.isSessionComplete
                    ? 'FINISH WORKOUT'
                    : 'COMPLETE SET',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Rest Timer button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: provider.isResting
                  ? provider.stopRestTimer
                  : provider.startRestTimer,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.isResting
                        ? 'REST ${provider.restRemaining}s'
                        : 'REST TIMER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKOUT FLOW (Exercise carousel)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWorkoutFlow(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              'WORKOUT FLOW',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: provider.sessionExercises.length,
              itemBuilder: (context, index) {
                final exercise = provider.sessionExercises[index];
                final isCurrent = index == provider.currentExerciseIndex;
                final isPast = index < provider.currentExerciseIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      // Allow jumping to any exercise
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? colorScheme.primaryContainer
                                    .withValues(alpha: 0.2)
                                : colorScheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(
                                    color: colorScheme.primaryContainer,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: isPast
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                    color: colorScheme.primary,
                                  )
                                : Icon(
                                    Icons.fitness_center_rounded,
                                    size: 20,
                                    color: isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 60,
                          child: Text(
                            exercise.exerciseName.split(' ').first,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _handleClose(BuildContext context) async {
    final provider = context.read<WorkoutProvider>();
    if (provider.sessionLogs.isEmpty) {
      provider.finishWorkout();
      if (mounted) Navigator.of(context).pop();
      return;
    }

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
            'End Workout?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          content: Text(
            'You have ${provider.sessionLogs.length} sets logged. Do you want to save and finish?',
            style: GoogleFonts.plusJakartaSans(
              color: cs.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Continue',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Finish & Save',
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
      await provider.finishWorkout();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _finishWorkout(
      BuildContext context, WorkoutProvider provider) async {
    await provider.finishWorkout();

    if (!mounted) return;

    // Show summary dialog
    final cs = Theme.of(context).colorScheme;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 32,
              color: cs.primary,
            ),
          ),
          title: Text(
            'Workout Complete! 🎉',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${provider.sessionLogs.length} sets completed\n'
                'Duration: ${provider.sessionTimerDisplay}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'DONE',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (mounted) {
      // Fire workout completion notification
      if (provider.sessionLogs.isNotEmpty) {
        NotificationService.instance.showWorkoutCompleted(
          workoutName: provider.activePlan?.name ?? 'Workout',
          durationMinutes: provider.sessionElapsed.inMinutes,
        );
      }
      Navigator.of(context).pop();
    }
  }
}
