import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../config/constants.dart';
import '../models/gym_model.dart';

/// Service responsible for device location access and
/// fetching nearby gyms via the Overpass API (OpenStreetMap).
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  final Distance _distanceCalculator = const Distance();

  // ─────────────────────────────────────────────────────────────────────────
  // LOCATION PERMISSIONS & POSITION
  // ─────────────────────────────────────────────────────────────────────────

  /// Checks and requests location permissions. Returns `true` when the
  /// permission has been granted, `false` otherwise.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Returns the current device position.
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OVERPASS API — NEARBY GYMS
  // ─────────────────────────────────────────────────────────────────────────

  /// Queries the Overpass API for fitness centres / gyms within [radiusKm]
  /// kilometres of [lat], [lng]. Results are sorted by distance ascending.
  Future<List<GymModel>> fetchNearbyGyms(
    double lat,
    double lng, {
    double radiusKm = 5.0,
  }) async {
    final radiusMeters = (radiusKm * 1000).toInt();

    // OverpassQL: search for fitness-related POIs (nodes, ways, and relations)
    // We use 'nwr' to catch all types and 'out center' to get a coordinate for polygons.
    final query = '''
[out:json][timeout:30];
(
  nwr["leisure"="fitness_centre"](around:$radiusMeters,$lat,$lng);
  nwr["leisure"="sports_centre"](around:$radiusMeters,$lat,$lng);
  nwr["amenity"="gym"](around:$radiusMeters,$lat,$lng);
);
out center;
''';

    final urls = [
      AppConstants.overpassApiUrl,
      'https://lz4.overpass-api.de/api/interpreter',
      'https://z.overpass-api.de/api/interpreter',
    ];

    Object? lastError;

    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'data': query},
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final elements = data['elements'] as List<dynamic>? ?? [];
          return _parseElements(elements, lat, lng);
        } else {
          lastError = 'API Error ${response.statusCode} from $url';
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Failed to fetch gyms from all mirrors: $lastError');
  }

  List<GymModel> _parseElements(List<dynamic> elements, double lat, double lng) {
    final userLocation = LatLng(lat, lng);
    final Map<int, GymModel> seen = {};

    for (final elem in elements) {
      final gym = GymModel.fromOverpassJson(elem as Map<String, dynamic>);
      // Calculate distance
      gym.distanceKm = _distanceCalculator.as(
            LengthUnit.Meter,
            userLocation,
            LatLng(gym.lat, gym.lng),
          ) /
          1000;
      seen.putIfAbsent(gym.id, () => gym);
    }

    final gyms = seen.values.toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return gyms;
  }
}
