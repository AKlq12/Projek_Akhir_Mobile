import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/models/exercise_model.dart';
import '../../core/models/muscle_model.dart';
import '../../core/providers/exercise_provider.dart';

/// Exercise detail screen — full exercise info with hero image,
/// tags, muscles worked, instructions, and pro tips.
///
/// Design follows the reference: hero image with gradient overlay,
/// floating info card, horizontal muscle chips, numbered instruction
/// cards, and a tinted pro-tips section.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If exercise detail isn't loaded yet, load it from route args
      final provider = context.read<ExerciseProvider>();
      if (provider.selectedExercise == null) {
        final exerciseId = ModalRoute.of(context)?.settings.arguments as int?;
        if (exerciseId != null) {
          provider.loadExerciseDetail(exerciseId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<ExerciseProvider>(
        builder: (context, provider, _) {
          if (provider.detailLoading && provider.selectedExercise == null) {
            return _buildLoadingState(context);
          }

          final exercise = provider.selectedExercise;
          if (exercise == null) {
            return _buildErrorState(context, provider.errorMessage);
          }

          return Stack(
            children: [
              // Scrollable content
              CustomScrollView(
                slivers: [
                  // Hero Image
                  SliverToBoxAdapter(
                    child: _buildHeroSection(context, exercise),
                  ),

                  // Info Card
                  SliverToBoxAdapter(
                    child: _buildInfoCard(context, exercise),
                  ),

                  // Muscles Worked
                  if (exercise.muscles.isNotEmpty ||
                      exercise.musclesSecondary.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildMusclesSection(context, exercise),
                    ),

                  // Instructions / Description
                  if (exercise.cleanDescription.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildInstructionsSection(context, exercise),
                    ),

                  // Pro Tips
                  SliverToBoxAdapter(
                    child: _buildProTipsSection(context, exercise),
                  ),

                  // Bottom spacing for action bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),

              // Top Navigation Bar
              _buildTopBar(context),

              // Bottom Action Bar
              _buildBottomActionBar(context, exercise),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR — Back button + TRAIN title + profile
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).padding.top + 56,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface.withValues(alpha: 0.9),
              colorScheme.surface.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: colorScheme.onSurface,
                  size: 22,
                ),
              ),
            ),

            // TRAIN title
            Text(
              'TRAIN',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),

            // Spacer for symmetry
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO SECTION — Large image with gradient fade
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(BuildContext context, Exercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Image
        SizedBox(
          height: 280 + topPadding,
          width: double.infinity,
          child: exercise.primaryImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: exercise.primaryImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: colorScheme.surfaceContainer,
                    child: Center(
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 48,
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: colorScheme.surfaceContainer,
                    child: Center(
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 48,
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                )
              : Container(
                  color: colorScheme.surfaceContainer,
                  child: Center(
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 64,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ),
        ),

        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  colorScheme.surface,
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INFO CARD — Tags, title, duration/calories
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoCard(BuildContext context, Exercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Transform.translate(
        offset: const Offset(0, -40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 40,
                spreadRadius: -10,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Category tag
                  _buildTag(
                    context,
                    label: exercise.categoryName.isNotEmpty
                        ? exercise.categoryName
                        : _getCategoryName(exercise.categoryId),
                    backgroundColor: colorScheme.primaryContainer,
                    textColor: colorScheme.onPrimaryContainer,
                  ),

                  // Equipment tags
                  for (final eq in exercise.equipmentNames.take(2))
                    _buildTag(
                      context,
                      label: eq,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      textColor: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Exercise name
              Text(
                exercise.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _buildStatBlock(
                    context,
                    label: 'MUSCLES',
                    value: exercise.muscles.isNotEmpty
                        ? '${exercise.muscles.length + exercise.musclesSecondary.length}'
                        : '—',
                  ),
                  const SizedBox(width: 40),
                  _buildStatBlock(
                    context,
                    label: 'EQUIPMENT',
                    value: exercise.equipmentNames.isNotEmpty
                        ? '${exercise.equipmentNames.length}'
                        : 'None',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildTag(
    BuildContext context, {
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatBlock(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MUSCLES WORKED — Horizontal scrolling cards
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMusclesSection(BuildContext context, Exercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    final allMuscles = <_MuscleDisplay>[];
    for (final m in exercise.muscles) {
      allMuscles.add(_MuscleDisplay(muscle: m, isPrimary: true));
    }
    for (final m in exercise.musclesSecondary) {
      allMuscles.add(_MuscleDisplay(muscle: m, isPrimary: false));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 8),
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'MUSCLES WORKED',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: allMuscles.length,
                itemBuilder: (context, index) {
                  final md = allMuscles[index];
                  return Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: md.isPrimary
                                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                                : colorScheme.surfaceContainerHigh,
                          ),
                          child: Icon(
                            md.isPrimary
                                ? Icons.sports_gymnastics_rounded
                                : Icons.fitness_center_rounded,
                            color: md.isPrimary
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          md.muscle.displayName.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          md.isPrimary ? 'PRIMARY' : 'SECONDARY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSTRUCTIONS — Numbered step cards
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInstructionsSection(BuildContext context, Exercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    // Split description into sentences for step-by-step instructions
    final description = exercise.cleanDescription;
    final sentences = description
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INSTRUCTIONS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            ...List.generate(sentences.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary.withValues(alpha: 0.6),
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          sentences[index].trim(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: 350 + index * 80))
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.05, end: 0);
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRO TIPS — Tinted section with bullet points
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProTipsSection(BuildContext context, Exercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    // Generate contextual tips based on exercise data
    final tips = _generateTips(exercise);
    if (tips.isEmpty) return const SizedBox.shrink();

    return Transform.translate(
      offset: const Offset(0, -4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primaryContainer.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRO TIPS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 7),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 500.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  List<String> _generateTips(Exercise exercise) {
    final tips = <String>[];
    if (exercise.muscles.isNotEmpty) {
      tips.add(
        'Focus on engaging your ${exercise.muscles.map((m) => m.displayName.toLowerCase()).join(" and ")} for maximum effectiveness.',
      );
    }
    tips.add('Keep the movement controlled throughout — avoid using momentum.');
    if (exercise.equipmentNames.isNotEmpty) {
      tips.add(
        'Start with a lighter weight to perfect your form before increasing the load.',
      );
    }
    return tips;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM ACTION BAR — Add to Workout + Log Exercise
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomActionBar(BuildContext context, Exercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.85),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
        ),
        // Add blur effect with BackdropFilter if desired
        child: Row(
          children: [
            // Add to Workout button
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to add-to-workout flow
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: colorScheme.onSurface,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'ADD TO WORKOUT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Log Exercise button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to logging flow
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shadowColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'LOG EXERCISE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOADING & ERROR STATES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.arrow_back_rounded,
                      color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: colorScheme.surfaceContainerHigh,
              highlightColor: colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(height: 20, width: 120, color: Colors.white),
                    const SizedBox(height: 12),
                    Container(height: 32, width: 250, color: Colors.white),
                    const SizedBox(height: 24),
                    Container(height: 80, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load exercise',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('GO BACK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(int categoryId) {
    const categories = {
      10: 'Abs', 8: 'Arms', 12: 'Back', 14: 'Calves',
      15: 'Cardio', 11: 'Chest', 9: 'Legs', 13: 'Shoulders',
    };
    return categories[categoryId] ?? 'Exercise';
  }
}

class _MuscleDisplay {
  final Muscle muscle;
  final bool isPrimary;

  const _MuscleDisplay({required this.muscle, required this.isPrimary});
}
