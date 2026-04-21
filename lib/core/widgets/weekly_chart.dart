import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A weekly activity bar chart widget for the home dashboard.
///
/// Shows vertical bars for Mon–Sun with the current day highlighted
/// using the neon-volt accent. Bars animate in on appear.
/// Data is provided as `Map<int, int>` where key = weekday (1=Mon, 7=Sun)
/// and value = activity duration in minutes.
class WeeklyChart extends StatelessWidget {
  /// Activity data: weekday (1–7) → duration minutes.
  final Map<int, int> data;

  /// Maximum value for scaling bars (auto-calculated if null).
  final int? maxValue;

  const WeeklyChart({
    super.key,
    required this.data,
    this.maxValue,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentWeekday = DateTime.now().weekday; // 1=Mon, 7=Sun

    // Calculate max value for scaling
    final max = maxValue ??
        (data.values.isEmpty
            ? 60
            : data.values.reduce((a, b) => a > b ? a : b));
    final effectiveMax = max == 0 ? 60 : max;

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final weekday = index + 1;
            final value = data[weekday] ?? 0;
            final isToday = weekday == currentWeekday;
            final barFraction = (value / effectiveMax).clamp(0.0, 1.0);

            // Minimum bar height so days with 0 still show a stub
            final minBarHeight = 8.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // ── Bar ───────────────────────────────────────────
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxHeight = constraints.maxHeight;
                            final barHeight = barFraction * maxHeight;
                            final displayHeight =
                                barHeight < minBarHeight && value > 0
                                    ? minBarHeight
                                    : barHeight;

                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: displayHeight),
                              duration: Duration(
                                  milliseconds: 600 + (index * 80)),
                              curve: Curves.easeOutCubic,
                              builder: (context, animatedHeight, _) {
                                return Container(
                                  width: double.infinity,
                                  height: animatedHeight,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? colorScheme.primaryContainer
                                        : colorScheme.primaryContainer
                                            .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(50),
                                    border: isToday
                                        ? Border.all(
                                            color: colorScheme
                                                .primaryContainer
                                                .withValues(alpha: 0.5),
                                            width: 2,
                                          )
                                        : null,
                                    boxShadow: isToday
                                        ? [
                                            BoxShadow(
                                              color: colorScheme
                                                  .primaryContainer
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Day Label ─────────────────────────────────────
                    Text(
                      _dayLabels[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight:
                            isToday ? FontWeight.w900 : FontWeight.w700,
                        color: isToday
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 500.ms);
  }
}
