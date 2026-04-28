import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/models/plan_exercise_model.dart';
import '../../core/providers/exercise_provider.dart';
import '../../core/providers/workout_provider.dart';

/// Workout plan create/edit screen — "Workout Builder".
///
/// Single-page form with:
/// - Plan name + description input
/// - Day-of-week circular selector
/// - Exercise list with inline sets/reps/weight editors
/// - Exercise picker bottom sheet (wger API search)
/// - Drag-to-reorder + swipe-to-delete exercises
class WorkoutCreateScreen extends StatefulWidget {
  const WorkoutCreateScreen({super.key});

  @override
  State<WorkoutCreateScreen> createState() => _WorkoutCreateScreenState();
}

class _WorkoutCreateScreenState extends State<WorkoutCreateScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _editPlanId;

  static const _dayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNames = [
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
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _editPlanId = args;
      }

      final provider = context.read<WorkoutProvider>();
      _nameController.text = provider.formPlanName;
      _descController.text = provider.formPlanDescription;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isEditMode => _editPlanId != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Nav ──────────────────────────────────────────────
            _buildTopNav(context),

            // ── Form Content ─────────────────────────────────────────
            Expanded(
              child: Consumer<WorkoutProvider>(
                builder: (context, provider, _) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Plan Info
                        _buildPlanInfo(context, provider),

                        const SizedBox(height: 28),

                        // Day Selector
                        _buildDaySelector(context, provider),

                        const SizedBox(height: 28),

                        // Exercise List
                        _buildExerciseSection(context, provider),

                        const SizedBox(height: 32),

                        // Save Button
                        _buildSaveButton(context, provider),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP NAV
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopNav(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: colorScheme.onSurface,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isEditMode ? 'Edit Plan' : 'Create Plan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAN INFO FIELDS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPlanInfo(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan Name
        _buildLabel('WORKOUT NAME'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          onChanged: provider.setFormPlanName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          decoration: _inputDecoration(
            context,
            hint: 'e.g. Upper Body Blast',
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // Description
        _buildLabel('DESCRIPTION (OPTIONAL)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          onChanged: provider.setFormPlanDescription,
          maxLines: 2,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          decoration: _inputDecoration(
            context,
            hint: 'Brief description of this workout...',
          ),
        )
            .animate(delay: 150.ms)
            .fadeIn(duration: 400.ms),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAY SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDaySelector(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('DAY OF WEEK'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final isSelected = provider.formSelectedDay == _dayNames[index];

            return GestureDetector(
              onTap: () {
                provider.setFormSelectedDay(
                  isSelected ? null : _dayNames[index],
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _dayInitials[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXERCISE SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExerciseSection(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('EXERCISES (${provider.formExercises.length})'),
            GestureDetector(
              onTap: () => _showExercisePicker(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
            .animate(delay: 250.ms)
            .fadeIn(duration: 400.ms),

        const SizedBox(height: 12),

        // Exercise list
        if (provider.formExercises.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 32,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add" to add exercises',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.formExercises.length,
            onReorder: provider.reorderFormExercises,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final exercise = provider.formExercises[index];
              return _ExerciseFormCard(
                key: ValueKey('${exercise.exerciseId}_$index'),
                exercise: exercise,
                index: index,
                onUpdate: (updated) =>
                    provider.updateFormExercise(index, updated),
                onDelete: () => provider.removeFormExercise(index),
              );
            },
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXERCISE PICKER BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showExercisePicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final exerciseProvider = context.read<ExerciseProvider>();

    // Initialize exercises if not loaded or list is empty
    if (exerciseProvider.exercises.isEmpty) {
      exerciseProvider.init();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Add Exercise',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Search bar

              // Exercise results
              Expanded(
                child: Consumer<ExerciseProvider>(
                  builder: (context, exProvider, _) {
                    final exercises = exProvider.exercises;

                    // Show loading indicator when initial list is loading
                    if (exProvider.exercisesLoading && exercises.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (exercises.isEmpty) {
                      return Center(
                        child: Text(
                          'No exercises found',
                          style: GoogleFonts.plusJakartaSans(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        return ListTile(
                          onTap: () {
                            final planExercise = PlanExerciseModel(
                              id: '',
                              planId: '',
                              exerciseId: ex.id,
                              exerciseName: ex.name,
                              targetSets: 4,
                              targetReps: 12,
                              targetWeightKg: null,
                              sortOrder:
                                  context
                                      .read<WorkoutProvider>()
                                      .formExercises
                                      .length,
                            );
                            context
                                .read<WorkoutProvider>()
                                .addFormExercise(planExercise);

                            Navigator.pop(ctx);
                          },
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.fitness_center_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            ex.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            ex.categoryName.isNotEmpty
                                ? ex.categoryName
                                : 'Exercise',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(
                            Icons.add_circle_rounded,
                            color: colorScheme.primaryContainer,
                            size: 24,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSaveButton(BuildContext context, WorkoutProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: provider.isSaving ? null : () => _handleSave(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: provider.isSaving
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : Text(
                _isEditMode ? 'UPDATE PLAN' : 'CREATE PLAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Future<void> _handleSave(WorkoutProvider provider) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a workout name',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    bool success;
    if (_isEditMode) {
      success = await provider.updatePlan(_editPlanId!);
    } else {
      success = await provider.createPlan();
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {required String hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.outline,
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.primaryContainer,
          width: 2,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EXERCISE FORM CARD — inline editor for sets/reps/weight
// ═════════════════════════════════════════════════════════════════════════════
class _ExerciseFormCard extends StatelessWidget {
  final PlanExerciseModel exercise;
  final int index;
  final ValueChanged<PlanExerciseModel> onUpdate;
  final VoidCallback onDelete;

  const _ExerciseFormCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('dismiss_${exercise.exerciseId}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.error,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise name + drag handle
            Row(
              children: [
                Icon(
                  Icons.drag_handle_rounded,
                  size: 20,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Sets / Reps / Weight inline
            Row(
              children: [
                _buildMiniStepper(
                  context,
                  label: 'Sets',
                  value: exercise.targetSets ?? 4,
                  onChanged: (v) => onUpdate(
                    exercise.copyWith(targetSets: v),
                  ),
                ),
                const SizedBox(width: 12),
                _buildMiniStepper(
                  context,
                  label: 'Reps',
                  value: exercise.targetReps ?? 12,
                  onChanged: (v) => onUpdate(
                    exercise.copyWith(targetReps: v),
                  ),
                ),
                const SizedBox(width: 12),
                _buildMiniStepper(
                  context,
                  label: 'kg',
                  value: (exercise.targetWeightKg ?? 0).toInt(),
                  onChanged: (v) => onUpdate(
                    exercise.copyWith(targetWeightKg: v.toDouble()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStepper(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onChanged((value - 1).clamp(0, 999)),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove, size: 14,
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    value.toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged((value + 1).clamp(0, 999)),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, size: 14,
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
