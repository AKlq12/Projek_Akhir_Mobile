import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/routes.dart';
import '../../core/models/exercise_model.dart';

import '../../core/providers/exercise_provider.dart';

/// Exercise list screen — browse, search, and filter exercises from wger.de.
///
/// Design follows the "Kinetic High-Contrast Editorial" theme:
/// neon-volt accent, rounded cards, editorial typography,
/// horizontal category scroller, and shimmer loading.
class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExerciseProvider>();
      if (provider.categories.isEmpty) {
        provider.init();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ExerciseProvider>().loadMoreExercises();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ExerciseProvider>().search(query);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
            // ── Header + Search ─────────────────────────────────────────
            _buildHeader(context),

            // ── Category Chips ──────────────────────────────────────────
            _buildCategoryScroller(context),

            // ── Exercise List ───────────────────────────────────────────
            Expanded(
              child: _buildExerciseList(context),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER — Title + Filter Icon + Search Bar
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
              // Filter button
              Container(
                height: 48,
                width: 48,
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
                  Icons.filter_list_rounded,
                  color: colorScheme.onSurface,
                  size: 22,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1, end: 0),

          const SizedBox(height: 20),

          // Search Bar
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search your next burn...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.outline,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: colorScheme.outline,
                    size: 24,
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY CHIPS — Horizontal scrollable filter chips
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCategoryScroller(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ExerciseProvider>(
      builder: (context, provider, _) {
        if (provider.categoriesLoading) {
          return _buildCategoryShimmer(context);
        }

        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: provider.categories.length + 1, // +1 for "ALL"
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final bool isSelected;
              final String label;
              final int? categoryId;

              if (isAll) {
                isSelected = provider.selectedCategoryId == null;
                label = 'ALL';
                categoryId = null;
              } else {
                final category = provider.categories[index - 1];
                isSelected = provider.selectedCategoryId == category.id;
                label = category.name.toUpperCase();
                categoryId = category.id;
              }

              return Padding(
                padding: EdgeInsets.only(right: index < provider.categories.length ? 10 : 0),
                child: GestureDetector(
                  onTap: () => provider.selectCategory(categoryId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildCategoryShimmer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 6,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Shimmer.fromColors(
            baseColor: colorScheme.surfaceContainerHigh,
            highlightColor: colorScheme.surfaceContainerLowest,
            child: Container(
              width: 80,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXERCISE LIST — Vertical card list (or search results)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExerciseList(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, _) {
        // Show search results if searching
        if (provider.searchQuery.isNotEmpty) {
          return _buildSearchResults(context, provider);
        }

        // Show shimmer loading on initial load
        if (provider.exercisesLoading && provider.exercises.isEmpty) {
          return _buildListShimmer(context);
        }

        // Show empty state
        if (provider.exercises.isEmpty) {
          return _buildEmptyState(context);
        }

        // Exercise list
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          itemCount: provider.exercises.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.exercises.length) {
              return _buildLoadingIndicator(context);
            }

            final exercise = provider.exercises[index];
            return _ExerciseCard(
              exercise: exercise,
              index: index,
              onTap: () => _navigateToDetail(exercise),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, ExerciseProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    if (provider.searchLoading) {
      return _buildListShimmer(context);
    }

    if (provider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final exercise = provider.searchResults[index];
        return _ExerciseCard(
          exercise: exercise,
          index: index,
          onTap: () => _navigateToDetail(exercise),
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
          Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises available',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<ExerciseProvider>().loadExercises(),
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  Widget _buildListShimmer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      itemCount: 6,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHigh,
          highlightColor: colorScheme.surfaceContainerLowest,
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
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

  void _navigateToDetail(Exercise exercise) {
    final provider = context.read<ExerciseProvider>();
    provider.setSelectedExercise(exercise);

    // Also fetch full detail if needed
    if (exercise.description.isEmpty && exercise.muscles.isEmpty) {
      provider.loadExerciseDetail(exercise.id);
    }

    Navigator.of(context).pushNamed(
      AppRoutes.exerciseDetail,
      arguments: exercise.id,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EXERCISE CARD — Individual exercise card widget
// ═════════════════════════════════════════════════════════════════════════════
class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int index;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 30,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Exercise Image
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: exercise.primaryImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: exercise.primaryImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _buildImagePlaceholder(context),
                        errorWidget: (_, _, _) =>
                            _buildImagePlaceholder(context),
                      )
                    : _buildImagePlaceholder(context),
              ),

              const SizedBox(width: 14),

              // Exercise Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category label
                    Text(
                      exercise.categoryName.isNotEmpty
                          ? exercise.categoryName.toUpperCase()
                          : _getCategoryName(exercise.categoryId),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Exercise name
                    Text(
                      exercise.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Equipment/Muscles info
                    Text(
                      _buildSubtitle(exercise),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.outlineVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * (index % 10)))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.03, end: 0, curve: Curves.easeOut);
  }

  Widget _buildImagePlaceholder(BuildContext context) {
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

  String _getCategoryName(int categoryId) {
    const categories = {
      10: 'ABS',
      8: 'ARMS',
      12: 'BACK',
      14: 'CALVES',
      15: 'CARDIO',
      11: 'CHEST',
      9: 'LEGS',
      13: 'SHOULDERS',
    };
    return categories[categoryId] ?? 'EXERCISE';
  }

  String _buildSubtitle(Exercise exercise) {
    final parts = <String>[];
    if (exercise.equipmentNames.isNotEmpty) {
      parts.add(exercise.equipmentNames.first);
    }
    if (exercise.muscles.isNotEmpty) {
      parts.add(exercise.muscles.first.displayName);
    }
    if (parts.isEmpty) {
      parts.add(_getCategoryName(exercise.categoryId));
    }
    return parts.join(' • ');
  }
}
