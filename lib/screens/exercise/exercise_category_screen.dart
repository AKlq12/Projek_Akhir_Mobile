import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/routes.dart';
import '../../core/models/exercise_category_model.dart';
import '../../core/models/exercise_model.dart';
import '../../core/providers/exercise_provider.dart';

/// Exercise category screen — shows exercises filtered by a specific category.
///
/// Navigated to when a user taps a category from the exercise list screen
/// or from a category grid. Features a hero header with category icon,
/// exercise count, and a filtered list of exercise cards.
class ExerciseCategoryScreen extends StatefulWidget {
  final ExerciseCategory? category;

  const ExerciseCategoryScreen({super.key, this.category});

  @override
  State<ExerciseCategoryScreen> createState() => _ExerciseCategoryScreenState();
}

class _ExerciseCategoryScreenState extends State<ExerciseCategoryScreen> {
  final _scrollController = ScrollController();
  ExerciseCategory? _category;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get category from widget or route arguments
      _category = widget.category ??
          ModalRoute.of(context)?.settings.arguments as ExerciseCategory?;

      if (_category != null) {
        context.read<ExerciseProvider>().loadExercises(
              categoryId: _category!.id,
            );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ExerciseProvider>().loadMoreExercises();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Collapsing Header ───────────────────────────────────────
          _buildSliverAppBar(context),

          // ── Exercise Count Badge ────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildCountBadge(context),
          ),

          // ── Exercise List ───────────────────────────────────────────
          _buildExerciseGrid(context),

          // ── Bottom Spacing ──────────────────────────────────────────
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SLIVER APP BAR — Hero header with category icon and gradient
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryName = _category?.name ?? 'Category';

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
      title: Text(
        'TRAIN',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.15),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Category Icon Circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: -4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(_category?.id ?? 0),
                    color: colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                      duration: 500.ms,
                    ),

                const SizedBox(height: 14),

                // Category Name
                Text(
                  categoryName.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: colorScheme.onSurface,
                  ),
                )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.15, end: 0),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  _getCategorySubtitle(_category?.id ?? 0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNT BADGE — Shows total exercise count
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCountBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ExerciseProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_list_numbered_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider.exercisesLoading
                          ? 'Loading...'
                          : '${provider.totalCount} exercises',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Sort button
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sort_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: 400.ms);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXERCISE GRID — Two-column card layout
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExerciseGrid(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, _) {
        // Loading shimmer
        if (provider.exercisesLoading && provider.exercises.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, _) => _buildGridShimmerCard(context),
                childCount: 6,
              ),
            ),
          );
        }

        // Empty state
        if (provider.exercises.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(context),
          );
        }

        // Grid
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Loading indicator at end
                if (index == provider.exercises.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ),
                    ),
                  );
                }

                final exercise = provider.exercises[index];
                return _CategoryExerciseCard(
                  exercise: exercise,
                  index: index,
                  onTap: () => _navigateToDetail(exercise),
                );
              },
              childCount:
                  provider.exercises.length + (provider.hasMore ? 1 : 0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridShimmerCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHigh,
      highlightColor: colorScheme.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 56,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'No exercises found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Exercise exercise) {
    final provider = context.read<ExerciseProvider>();
    provider.setSelectedExercise(exercise);

    if (exercise.description.isEmpty && exercise.muscles.isEmpty) {
      provider.loadExerciseDetail(exercise.id);
    }

    Navigator.of(context).pushNamed(
      AppRoutes.exerciseDetail,
      arguments: exercise.id,
    );
  }

  IconData _getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case 10: return Icons.fitness_center_rounded;   // Abs
      case 8:  return Icons.front_hand_rounded;        // Arms
      case 12: return Icons.accessibility_new_rounded; // Back
      case 14: return Icons.directions_walk_rounded;   // Calves
      case 15: return Icons.directions_run_rounded;    // Cardio
      case 11: return Icons.expand_rounded;            // Chest
      case 9:  return Icons.airline_seat_legroom_extra_rounded; // Legs
      case 13: return Icons.sports_martial_arts_rounded; // Shoulders
      default: return Icons.fitness_center_rounded;
    }
  }

  String _getCategorySubtitle(int categoryId) {
    switch (categoryId) {
      case 10: return 'Build a strong and defined core';
      case 8:  return 'Biceps, triceps & forearms';
      case 12: return 'Lats, traps & lower back';
      case 14: return 'Strengthen your lower legs';
      case 15: return 'Boost endurance & burn fat';
      case 11: return 'Pecs, upper chest & inner chest';
      case 9:  return 'Quads, hamstrings & glutes';
      case 13: return 'Deltoids & rotator cuff';
      default: return 'Browse exercises in this category';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CATEGORY EXERCISE CARD — Two-column grid card variant
// ═════════════════════════════════════════════════════════════════════════════
class _CategoryExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int index;
  final VoidCallback onTap;

  const _CategoryExerciseCard({
    required this.exercise,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  exercise.primaryImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: exercise.primaryImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              _buildPlaceholder(context),
                          errorWidget: (_, _, _) =>
                              _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),

                  // Bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Exercise Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Equipment chip
                    if (exercise.equipmentNames.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exercise.equipmentNames.first.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Exercise name
                    Text(
                      exercise.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Muscle badges
                    if (exercise.muscles.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.sports_gymnastics_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              exercise.muscles
                                  .map((m) => m.displayName)
                                  .join(', '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * (index % 10)))
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
          duration: 350.ms,
        );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: colorScheme.outlineVariant,
          size: 28,
        ),
      ),
    );
  }
}
