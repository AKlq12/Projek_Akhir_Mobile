import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/gym_model.dart';
import '../../core/providers/gym_provider.dart';

/// Nearby Gym screen — OpenStreetMap-powered map with an interactive
/// bottom sheet listing gyms fetched from the Overpass API.
///
/// Design adapted from the dark-themed HTML reference to the project's
/// Volt/green-yellow light theme:
/// - AppBar with back + search
/// - Map (55 %) with user-location pulse & gym markers
/// - Draggable bottom sheet (45 %) with distance-filter chips & gym cards
/// - FAB "Recenter" to snap back to user location
/// - Navigate button opens Google Maps for turn-by-turn directions
class NearbyGymScreen extends StatefulWidget {
  const NearbyGymScreen({super.key});

  @override
  State<NearbyGymScreen> createState() => _NearbyGymScreenState();
}

class _NearbyGymScreenState extends State<NearbyGymScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Kick off location + gym fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GymProvider>().init();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Consumer<GymProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              // ── Map ──────────────────────────────────────────────────
              _buildMap(context, provider),

              // ── Top App Bar ──────────────────────────────────────────
              _buildAppBar(context),

              // ── Bottom Sheet ─────────────────────────────────────────
              _buildBottomSheet(context, provider),

              // ── FAB Recenter ─────────────────────────────────────────
              if (provider.userLocation != null)
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.48 + 16,
                  right: 16,
                  child: _buildRecenterFab(context, provider),
                ),

              // ── Loading Overlay ──────────────────────────────────────
              if (provider.isLoading) _buildLoadingOverlay(context),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back_rounded, color: cs.primary),
              ),
              const SizedBox(width: 4),
              Text(
                'Find Nearby Gyms',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Future: search
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Search — coming soon!',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(Icons.search_rounded, color: cs.primary),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMap(BuildContext context, GymProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final center = provider.userLocation ?? const LatLng(-6.2088, 106.8456);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 14,
          onTap: (_, _) => provider.selectGym(null),
        ),
        children: [
          // OSM Tile Layer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.fitpro.fitness',
          ),

          // Markers
          MarkerLayer(
            markers: [
              // — User Location Marker
              if (provider.userLocation != null)
                Marker(
                  point: provider.userLocation!,
                  width: 48,
                  height: 48,
                  child: _UserLocationMarker(color: cs.primary),
                ),

              // — Gym Markers
              ...provider.gyms.map((gym) {
                final isSelected = provider.selectedGym?.id == gym.id;
                return Marker(
                  point: LatLng(gym.lat, gym.lng),
                  width: isSelected ? 160 : 40,
                  height: isSelected ? 80 : 48,
                  child: GestureDetector(
                    onTap: () {
                      provider.selectGym(gym);
                      _mapController.move(
                        LatLng(gym.lat, gym.lng),
                        _mapController.camera.zoom,
                      );
                    },
                    child: isSelected
                        ? _SelectedGymMarker(gym: gym, colorScheme: cs)
                        : _GymMarker(colorScheme: cs),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomSheet(BuildContext context, GymProvider provider) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.20,
      maxChildSize: 0.85,
      controller: _sheetController,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, -12),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // ── Drag Handle ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header & Filter ──────────────────────────────────────
              _buildSheetHeader(context, provider),

              // ── Distance Chips ───────────────────────────────────────
              _buildDistanceChips(context, provider),

              const SizedBox(height: 8),

              // ── Gym List ─────────────────────────────────────────────
              Expanded(
                child: _buildGymList(context, provider, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader(BuildContext context, GymProvider provider) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error / permission denied states
                if (provider.permissionDenied) ...[
                  Text(
                    'Location Access Denied',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Please enable location services in settings.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ] else if (provider.errorMessage != null) ...[
                  Text(
                    'Error Loading Gyms',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to retry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${provider.gyms.length} Gyms Found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Within ${provider.radiusKm.toStringAsFixed(0)} km from your location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sort button (placeholder)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sorting by distance (nearest first)',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list_rounded,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildDistanceChips(BuildContext context, GymProvider provider) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: GymProvider.radiusOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final radius = GymProvider.radiusOptions[index];
          final isActive = provider.radiusKm == radius;

          return GestureDetector(
            onTap: () => provider.setRadius(radius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(colors: [
                        cs.primaryContainer,
                        cs.primary,
                      ])
                    : null,
                color: isActive ? null : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(50),
                border: isActive
                    ? null
                    : Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.25),
                        width: 1,
                      ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: cs.primaryContainer.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${radius.toStringAsFixed(0)} km',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GYM LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGymList(
    BuildContext context,
    GymProvider provider,
    ScrollController scrollController,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (provider.isLoading) {
      return const Center(child: SizedBox.shrink());
    }

    if (provider.permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Enable location access to discover gyms near you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.init(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Could not load gyms. Check your connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.init(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.gyms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center_rounded,
                  size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'No gyms found within ${provider.radiusKm.toStringAsFixed(0)} km.\nTry increasing the search radius.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: provider.gyms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final gym = provider.gyms[index];
        final isSelected = provider.selectedGym?.id == gym.id;
        return _buildGymCard(context, provider, gym, index, isSelected);
      },
    );
  }

  Widget _buildGymCard(
    BuildContext context,
    GymProvider provider,
    GymModel gym,
    int index,
    bool isSelected,
  ) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        provider.selectGym(gym);
        _mapController.move(
          LatLng(gym.lat, gym.lng),
          15,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.surfaceContainerLowest
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.35)
                : cs.outlineVariant.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Subtle accent glow for selected
            if (isSelected)
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primaryContainer.withValues(alpha: 0.08),
                  ),
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              gym.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (index == 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    cs.tertiaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'NEAREST',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: cs.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Address
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: cs.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              gym.address ?? 'OpenStreetMap location',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Distance
                      Row(
                        children: [
                          Icon(Icons.near_me_rounded,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${gym.distanceKm.toStringAsFixed(1)} km',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Navigate button
                GestureDetector(
                  onTap: () => _navigateToGym(gym),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Navigate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 350 + (index * 60)))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.03, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAB RECENTER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecenterFab(BuildContext context, GymProvider provider) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (provider.userLocation != null) {
          _mapController.move(provider.userLocation!, 14);
          provider.selectGym(null);
        }
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer,
              cs.primary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.my_location_rounded,
          color: cs.onPrimaryContainer,
          size: 24,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 500.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingOverlay(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Container(
        color: cs.surface.withValues(alpha: 0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Finding gyms near you…',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Getting your location & searching OpenStreetMap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION — open Google Maps externally
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _navigateToGym(GymModel gym) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${gym.lat},${gym.lng}',
    );

    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && mounted) {
        throw Exception('Could not launch URL');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open Google Maps',
              style:
                  GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARKER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Animated pulsing circle + centre dot for the user's location.
class _UserLocationMarker extends StatefulWidget {
  final Color color;
  const _UserLocationMarker({required this.color});

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse
            Container(
              width: 48 * _controller.value,
              height: 48 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color
                    .withValues(alpha: 0.25 * (1 - _controller.value)),
              ),
            ),
            // Inner dot
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Default (non-selected) gym marker.
class _GymMarker extends StatelessWidget {
  final ColorScheme colorScheme;
  const _GymMarker({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on_rounded,
      size: 36,
      color: colorScheme.tertiary,
      shadows: [
        Shadow(
          color: colorScheme.shadow.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

/// Selected gym marker with a floating label above the pin.
class _SelectedGymMarker extends StatelessWidget {
  final GymModel gym;
  final ColorScheme colorScheme;
  const _SelectedGymMarker({required this.gym, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded,
                  size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  gym.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Pin
        Icon(
          Icons.location_on_rounded,
          size: 40,
          color: colorScheme.primary,
          shadows: [
            Shadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ],
    );
  }
}
