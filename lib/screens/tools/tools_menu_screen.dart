import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../core/providers/auth_provider.dart';

/// Tools menu screen — central hub for accessing all FitPro tools.
///
/// Design: Bento grid layout with gradient icon circles, subtle
/// card shadows on white surfaces, and a featured "Premium" card.
/// Adapted from the HTML reference to the project's light theme.
class ToolsMenuScreen extends StatelessWidget {
  const ToolsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top App Bar ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ── Editorial Header ────────────────────────────────────────
            SliverToBoxAdapter(child: _buildEditorialHeader(context)),

            // ── Bento Grid ──────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildToolsGrid(context)),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final firstName = user.fullName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu icon + Title
          Row(
            children: [
              Icon(
                Icons.menu_rounded,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 14),
              Text(
                'Tools',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? Image.network(
                      user.avatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _buildAvatarFallback(context, firstName),
                    )
                  : _buildAvatarFallback(context, firstName),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildAvatarFallback(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDITORIAL HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEditorialHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tools',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Useful tools for your fitness journey',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BENTO GRID — 6 tool cards
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildToolsGrid(BuildContext context) {
    final tools = [
      _ToolItem(
        icon: Icons.payments_rounded,
        label: 'Currency\nConverter',
        subtitle: 'Convert currencies',
        gradientColors: const [Color(0xFF00B4D8), Color(0xFF4CD6FB)],
        route: AppRoutes.currencyConverter,
      ),
      _ToolItem(
        icon: Icons.public_rounded,
        label: 'World Clock',
        subtitle: 'WIB, WITA, WIT & more',
        gradientColors: const [Color(0xFF6366F1), Color(0xFFA855F7)],
        route: AppRoutes.timezoneConverter,
      ),
      _ToolItem(
        icon: Icons.location_on_rounded,
        label: 'Nearby Gyms',
        subtitle: 'Find gyms around you',
        gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
        route: AppRoutes.nearbyGym,
      ),
      _ToolItem(
        icon: Icons.sports_esports_rounded,
        label: 'Mini Game',
        subtitle: 'Test your reflexes',
        gradientColors: const [Color(0xFFF97316), Color(0xFFFBBF24)],
        route: AppRoutes.miniGame,
      ),
      _ToolItem(
        icon: Icons.directions_walk_rounded,
        label: 'Step Counter',
        subtitle: 'Track daily steps',
        gradientColors: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
        route: AppRoutes.stepCounter,
      ),
      _ToolItem(
        icon: Icons.vibration_rounded,
        label: 'Shake\nSurprise',
        subtitle: 'Shake for random exercise',
        gradientColors: const [Color(0xFF22D3EE), Color(0xFF4ADE80)],
        route: AppRoutes.shakeExercise,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tools.asMap().entries.map((entry) {
          final index = entry.key;
          final tool = entry.value;
          return _buildToolCard(context, tool, index);
        }).toList(),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, _ToolItem tool, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (tool.route != null) {
          Navigator.of(context).pushNamed(tool.route!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: tool.gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tool.gradientColors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                tool.icon,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),

            // Label
            Text(
              tool.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              tool.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 200 + (index * 80)))
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}

/// Internal model for a tool grid item.
class _ToolItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final String? route;

  const _ToolItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
    this.route,
  });
}
