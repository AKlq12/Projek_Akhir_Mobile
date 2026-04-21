import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/providers/sensor_provider.dart';

/// Step Counter screen — real-time pedometer with daily goal progress,
/// estimated calories/distance, and a weekly step bar chart.
///
/// Design:
/// - Section A: App bar with back button
/// - Section B: Large circular progress ring with step count
/// - Section C: Stats row (Steps, Calories, Distance)
/// - Section D: Weekly step bar chart
/// - Section E: Start/Stop tracking toggle
class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<SensorProvider>();
      await provider.initStepCounter();
      _ringController.forward();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    // Save progress when leaving the screen
    context.read<SensorProvider>().saveProgress();
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

                // ── Hero Ring ───────────────────────────────
                SliverToBoxAdapter(
                  child: _buildHeroRing(context, provider),
                ),

                // ── Stats Row ───────────────────────────────
                SliverToBoxAdapter(
                  child: _buildStatsRow(context, provider),
                ),

                // ── Tracking Toggle ─────────────────────────
                SliverToBoxAdapter(
                  child: _buildTrackingToggle(context, provider),
                ),

                // ── Weekly Chart ────────────────────────────
                SliverToBoxAdapter(
                  child: _buildWeeklyChart(context, provider),
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
            'Step Counter',
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
              Icons.directions_walk_rounded,
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
  // SECTION B — Hero Ring
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroRing(BuildContext context, SensorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Center(
        child: AnimatedBuilder(
          animation: _ringAnimation,
          builder: (context, child) {
            final animatedProgress =
                provider.stepProgress * _ringAnimation.value;

            return SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background ring
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: animatedProgress,
                        trackColor:
                            colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        progressColor: colorScheme.primaryContainer,
                        glowColor:
                            colorScheme.primaryContainer.withValues(alpha: 0.4),
                        strokeWidth: 14,
                      ),
                    ),
                  ),

                  // Center content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Step icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_walk_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Step count
                      Text(
                        _formatNumber(provider.currentSteps),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'of ${_formatNumber(provider.dailyGoal)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION C — Stats Row
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow(BuildContext context, SensorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    final stats = [
      _StatItem(
        icon: Icons.directions_walk_rounded,
        value: _formatNumber(provider.currentSteps),
        label: 'Steps',
        gradientColors: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
      ),
      _StatItem(
        icon: Icons.local_fire_department_rounded,
        value: provider.caloriesBurned.toStringAsFixed(0),
        label: 'kcal',
        gradientColors: const [Color(0xFFF97316), Color(0xFFFBBF24)],
      ),
      _StatItem(
        icon: Icons.straighten_rounded,
        value: provider.distanceKm.toStringAsFixed(2),
        label: 'km',
        gradientColors: const [Color(0xFF6366F1), Color(0xFFA855F7)],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: index > 0 ? 6 : 0,
                right: index < stats.length - 1 ? 6 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Gradient icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: stat.gradientColors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: stat.gradientColors.first.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(stat.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    stat.value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 300 + (index * 100)))
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.15, end: 0),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION D — Tracking Toggle
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTrackingToggle(BuildContext context, SensorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTracking = provider.isTracking;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: GestureDetector(
        onTap: () {
          if (isTracking) {
            provider.stopTracking();
          } else {
            provider.startTracking();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isTracking
                  ? [
                      const Color(0xFFF43F5E),
                      const Color(0xFFEC4899),
                    ]
                  : [
                      colorScheme.primaryContainer,
                      colorScheme.primary,
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isTracking
                        ? const Color(0xFFF43F5E)
                        : colorScheme.primaryContainer)
                    .withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTracking
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: isTracking
                    ? Colors.white
                    : colorScheme.onPrimaryContainer,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                isTracking ? 'STOP TRACKING' : 'START TRACKING',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: isTracking
                      ? Colors.white
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 500.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION E — Weekly Chart
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWeeklyChart(BuildContext context, SensorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final weeklySteps = provider.weeklySteps;
    final maxSteps = weeklySteps.reduce((a, b) => a > b ? a : b);
    final chartMax = maxSteps > 0 ? (maxSteps * 1.3) : 10000.0;

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIndex = DateTime.now().weekday - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Steps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'This Week',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bar Chart
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
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
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        colorScheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_formatNumber(weeklySteps[group.x.toInt()])} steps',
                        GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onInverseSurface,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatCompact(value.toInt()),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayLabels[idx],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: idx == todayIndex
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: idx == todayIndex
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final isToday = index == todayIndex;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weeklySteps[index].toDouble(),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isToday
                              ? [
                                  colorScheme.primaryContainer,
                                  colorScheme.primary,
                                ]
                              : [
                                  colorScheme.surfaceContainerHigh,
                                  colorScheme.surfaceContainerHighest,
                                ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: 600.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }

  String _formatCompact(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM RING PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color glowColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.glowColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      // Glow effect
      final glowPaint = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );

      // Main progress
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INTERNAL DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradientColors;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradientColors,
  });
}
