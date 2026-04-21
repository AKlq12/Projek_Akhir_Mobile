import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable circular stat card widget for the home dashboard.
///
/// Displays an icon inside a circular progress ring with a large value
/// and an uppercase label below. Matches the reference "FitPro Volt" design:
/// white card, neon-volt progress stroke, rounded corners.
class StatCard extends StatelessWidget {
  /// The stat value to display (e.g. "8,432").
  final String value;

  /// Uppercase label below the value (e.g. "STEPS").
  final String label;

  /// Progress from 0.0 to 1.0 for the circular ring.
  final double progress;

  /// The icon displayed in the center of the ring.
  final IconData icon;

  /// Animation delay for staggered entrance.
  final Duration delay;

  /// Card width.
  final double width;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.progress,
    required this.icon,
    this.delay = Duration.zero,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Circular Progress Ring with Icon ──────────────────────────
          SizedBox(
            width: 80,
            height: 80,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                return CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: animatedProgress,
                    trackColor: colorScheme.surfaceContainerHigh,
                    progressColor: colorScheme.primaryContainer,
                    strokeWidth: 5,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Value ────────────────────────────────────────────────────
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 2),

          // ── Label ────────────────────────────────────────────────────
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

/// Custom painter for a circular progress ring with rounded caps.
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -pi / 2; // Start from top
    final sweepAngle = 2 * pi * progress;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
