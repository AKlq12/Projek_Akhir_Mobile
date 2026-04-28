import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/tools_provider.dart';

/// Timezone / World Clock screen — displays current time in multiple timezones.
///
/// Design follows the HTML reference — light theme with:
/// - Local time hero card with large time display
/// - "Change Primary Timezone" dashed button
/// - City list with time offsets relative to primary timezone
/// - FAB to add new timezone
class TimezoneConverterScreen extends StatefulWidget {
  const TimezoneConverterScreen({super.key});

  @override
  State<TimezoneConverterScreen> createState() =>
      _TimezoneConverterScreenState();
}

class _TimezoneConverterScreenState extends State<TimezoneConverterScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick every second to update clocks
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Consumer<ToolsProvider>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ─────────────────────────────────────────────
                    SliverToBoxAdapter(child: _buildHeader(context)),

                    // ── Local Time Hero ───────────────────────────────────
                    SliverToBoxAdapter(
                        child: _buildLocalTimeHero(context, provider)),

                    // ── Change Primary TZ button ──────────────────────────
                    SliverToBoxAdapter(
                        child: _buildChangePrimaryButton(context, provider)),

                    // ── City List ──────────────────────────────────────────
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = provider.timezones[index];
                          return _buildCityCard(context, provider, entry, index);
                        },
                        childCount: provider.timezones.length,
                      ),
                    ),

                    // Bottom spacing for FAB
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),

                // ── FAB ─────────────────────────────────────────────────
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: _buildFab(context, provider),
                ),
              ],
            );
          },
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
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primaryContainer,
                      width: 2,
                    ),
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
              ),
              const SizedBox(width: 14),
              Text(
                'WORLD CLOCK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.settings_rounded, color: colorScheme.onSurface),
            onPressed: () {
              // Settings placeholder
            },
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
  // LOCAL TIME HERO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLocalTimeHero(BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get primary timezone
    final primary = provider.timezones.firstWhere(
      (t) => t.timezoneId == provider.primaryTimezoneId,
      orElse: () => provider.timezones.first,
    );

    final now = provider.getTimeInTimezone(primary.utcOffsetHours);
    final timeStr = DateFormat('HH:mm').format(now);
    final amPm = DateFormat('a').format(now).toUpperCase();
    final dateStr = DateFormat('EEEE, dd MMMM').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 30,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Accent glow
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  'LOCAL TIME — ${primary.city.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3,
                        height: 1.0,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amPm,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date
                Text(
                  dateStr,
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
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.03, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHANGE PRIMARY TIMEZONE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildChangePrimaryButton(
      BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: GestureDetector(
        onTap: () => _showPrimaryTimezonePicker(context, provider),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'CHANGE PRIMARY TIMEZONE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms);
  }

  void _showPrimaryTimezonePicker(
      BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Primary Timezone',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...provider.timezones.map((tz) {
                final isSelected = tz.timezoneId == provider.primaryTimezoneId;
                return ListTile(
                  title: Text(
                    tz.city,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '${tz.abbreviation} (UTC${tz.utcOffsetHours >= 0 ? '+' : ''}${tz.utcOffsetHours})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                          color: colorScheme.primary)
                      : null,
                  onTap: () {
                    provider.setPrimaryTimezone(tz.timezoneId);
                    Navigator.of(context).pop();
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CITY CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCityCard(
    BuildContext context,
    ToolsProvider provider,
    TimezoneEntry entry,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = provider.getTimeInTimezone(entry.utcOffsetHours);
    final timeStr = DateFormat('HH:mm').format(now);
    final offset = provider.getOffsetFromPrimary(entry);
    final dayLabel = provider.getDayLabel(entry);
    final isPrimary = entry.timezoneId == provider.primaryTimezoneId;

    // Format offset label
    String offsetLabel;
    if (offset == 0) {
      offsetLabel = '+0 HRS';
    } else if (offset.abs() == 1) {
      offsetLabel = '${offset > 0 ? '+' : ''}$offset HR';
    } else {
      offsetLabel = '${offset > 0 ? '+' : ''}$offset HRS';
    }

    final isNegative = offset < 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Dismissible(
        key: Key(entry.timezoneId),
        direction: isPrimary
            ? DismissDirection.none
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.delete_rounded, color: colorScheme.error),
        ),
        onDismissed: (_) {
          provider.removeTimezone(entry.timezoneId);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Accent bar for non-Indonesian timezones
              if (!entry.abbreviation.startsWith('WI') &&
                  entry.abbreviation != 'WIB' &&
                  entry.abbreviation != 'WITA' &&
                  entry.abbreviation != 'WIT') ...[
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
              ],

              // City info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.city,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.abbreviation} • $dayLabel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: isPrimary
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Time + offset
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    offsetLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isNegative
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 250 + (index * 60)))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.03, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAB — Add Timezone
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFab(BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showAddTimezoneDialog(context, provider),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: colorScheme.onPrimaryContainer,
          size: 30,
        ),
      ),
    )
        .animate(delay: 600.ms)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  void _showAddTimezoneDialog(BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filter out already-added timezones
    final available = ToolsProvider.availableTimezones
        .where((tz) =>
            !provider.timezones.any((t) => t.timezoneId == tz.timezoneId))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All available timezones have been added!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = available.where((tz) {
              final query = searchQuery.toLowerCase();
              return tz.city.toLowerCase().contains(query) ||
                  tz.abbreviation.toLowerCase().contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Add Timezone',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setModalState(() => searchQuery = val);
                          },
                          autofocus: false,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search city or timezone...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No results found',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final tz = filtered[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.public_rounded,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      tz.city,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${tz.abbreviation} (UTC${tz.utcOffsetHours >= 0 ? '+' : ''}${tz.utcOffsetHours})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    onTap: () {
                                      provider.addTimezone(tz);
                                      Navigator.of(context).pop();
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
          },
        );
      },
    );
  }
}
