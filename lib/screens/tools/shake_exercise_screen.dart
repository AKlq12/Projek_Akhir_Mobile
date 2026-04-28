import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../core/models/exercise_model.dart';
import '../../core/providers/exercise_provider.dart';
import '../../core/providers/sensor_provider.dart';

/// Shake Surprise screen — shake the phone to discover random exercises.
///
/// Design:
/// - Section A: Header with back button
/// - Section B: Animated phone shake illustration + instruction
/// - Section C: Revealed exercise card (after shake)
/// - Section D: Shake history list
class ShakeExerciseScreen extends StatefulWidget {
  const ShakeExerciseScreen({super.key});

  @override
  State<ShakeExerciseScreen> createState() => _ShakeExerciseScreenState();
}

class _ShakeExerciseScreenState extends State<ShakeExerciseScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeAnimController;

  @override
  void initState() {
    super.initState();

    _shakeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SensorProvider>();
      provider.startShakeDetection();
      _loopShakeAnimation();
    });
  }

  void _loopShakeAnimation() async {
    while (mounted) {
      await _shakeAnimController.forward();
      await _shakeAnimController.reverse();
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }

  @override
  void dispose() {
    _shakeAnimController.dispose();
    context.read<SensorProvider>().stopShakeDetection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Consumer<SensorProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader(context)),

                // ── Shake Illustration ──────────────────────
                SliverToBoxAdapter(
                  child: _buildShakeIllustration(context, provider),
                ),

                // ── Exercise Card (if shaken) ───────────────
                if (provider.suggestedExercise != null)
                  SliverToBoxAdapter(
                    child: _buildExerciseCard(
                      context,
                      provider.suggestedExercise!,
                    ),
                  ),

                // ── Manual Shake Button ─────────────────────
                SliverToBoxAdapter(
                  child: _buildShakeButton(context, provider),
                ),

                // ── History ─────────────────────────────────
                if (provider.shakeHistory.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildHistorySection(context, provider),
                  ),

                // Bottom spacing
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION A — Header
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Shake Surprise',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.vibration_rounded,
              color: colorScheme.primary,
              size: 20,
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
  // SECTION B — Shake Illustration
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShakeIllustration(
      BuildContext context, SensorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        children: [
          // Animated phone icon
          AnimatedBuilder(
            animation: _shakeAnimController,
            builder: (context, child) {
              // Wobble left-right
              final offset = ((_shakeAnimController.value - 0.5) * 2) * 12;
              final rotation = ((_shakeAnimController.value - 0.5) * 2) * 0.08;

              return Transform.translate(
                offset: Offset(offset, 0),
                child: Transform.rotate(
                  angle: rotation,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF22D3EE).withValues(alpha: 0.15),
                    const Color(0xFF4ADE80).withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple ring
                  ...List.generate(3, (i) {
                    return Container(
                      width: 120 + (i * 20.0),
                      height: 120 + (i * 20.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF22D3EE)
                              .withValues(alpha: 0.1 - (i * 0.03)),
                          width: 1.5,
                        ),
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(),
                        )
                        .fadeIn(
                          duration: Duration(milliseconds: 1200 + (i * 400)),
                        )
                        .fadeOut(
                          delay: Duration(milliseconds: 600 + (i * 200)),
                          duration: 600.ms,
                        )
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: Duration(
                              milliseconds: 1200 + (i * 400)),
                        );
                  }),
                  // Phone icon
                  Icon(
                    Icons.smartphone_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Instruction text
          Text(
            provider.suggestedExercise == null
                ? 'Shake your phone!'
                : 'Shake again for another!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Discover a random exercise every time you shake',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          if (provider.shakeCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${provider.shakeCount} shakes 🎉',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 600.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION C — Exercise Card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top gradient bar
            Container(
              width: double.infinity,
              height: 6,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [Color(0xFF22D3EE), Color(0xFF4ADE80)],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '✨ SURPRISE PICK',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: const Color(0xFF0891B2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Exercise name
                  Text(
                    exercise.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Category & muscle chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (exercise.categoryName.isNotEmpty)
                        _buildChip(
                          context,
                          Icons.category_rounded,
                          exercise.categoryName,
                        ),
                      if (exercise.muscles.isNotEmpty)
                        _buildChip(
                          context,
                          Icons.fitness_center_rounded,
                          exercise.muscles.first.displayName,
                        ),
                      if (exercise.equipmentNames.isNotEmpty)
                        _buildChip(
                          context,
                          Icons.build_rounded,
                          exercise.equipmentNames.first,
                        ),
                    ],
                  ),

                  if (exercise.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _stripHtml(exercise.description),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // CTA Button
                  GestureDetector(
                    onTap: () {
                      // Navigate to exercise detail
                      context
                          .read<ExerciseProvider>()
                          .setSelectedExercise(exercise);
                      Navigator.of(context)
                          .pushNamed(AppRoutes.exerciseDetail);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22D3EE), Color(0xFF4ADE80)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'VIEW EXERCISE DETAILS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MANUAL SHAKE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShakeButton(BuildContext context, SensorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: GestureDetector(
        onTap: provider.isLoadingExercise
            ? null
            : () => provider.triggerRandomExercise(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (provider.isLoadingExercise)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              else
                Icon(
                  Icons.touch_app_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Text(
                provider.isLoadingExercise
                    ? 'Finding exercise...'
                    : 'Or tap here instead',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION D — History
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHistorySection(
      BuildContext context, SensorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discovery History',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),

          // History list
          ...provider.shakeHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            final isLatest = index == 0;

            return _buildHistoryItem(context, exercise, index, isLatest: isLatest)
                .animate(delay: Duration(milliseconds: index * 80))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
      BuildContext context, Exercise exercise, int index,
      {bool isLatest = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          context.read<ExerciseProvider>().setSelectedExercise(exercise);
          Navigator.of(context).pushNamed(AppRoutes.exerciseDetail);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isLatest
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: isLatest
                      ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5))
                      : null,
                ),
                child: Center(
                  child: Text(
                    '#${index + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isLatest
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        if (exercise.categoryName.isNotEmpty)
                          Text(
                            exercise.categoryName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (isLatest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LATEST',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Strips basic HTML tags from a string.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
