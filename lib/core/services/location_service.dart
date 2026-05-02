import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
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

  /// Fetches gyms nearby using the local CSV file.
  Future<List<GymModel>> fetchNearbyGyms(
    double lat,
    double lng, {
    double radiusKm = 5.0,
  }) async {
    try {
      final csvString = await rootBundle.loadString('assets/data/gyms.csv');
      final rows = Csv().decode(csvString);

      final Map<int, GymModel> seen = {};
      final regex = RegExp(r'!3d([-\d.]+)!4d([-\d.]+)');
      int idCounter = 1;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue;

        final url = row[0].toString();
        final name = row[1].toString().trim();
        final category = row[4].toString().toLowerCase();

        // 1. Skip rows that aren't fitness/gyms
        if (name.isEmpty || url.isEmpty) continue;
        if (category.contains('toko') || 
            category.contains('vila') || 
            category.contains('hotel') ||
            category.contains('pakaian') ||
            category.contains('panjat')) {
          continue;
        }

        // 2. Extract Coordinates
        final match = regex.firstMatch(url);
        if (match != null && match.groupCount >= 2) {
          final gymLat = double.tryParse(match.group(1)!);
          final gymLng = double.tryParse(match.group(2)!);

          if (gymLat != null && gymLng != null) {
            // 3. Calculate distance
            final distance = const Distance().as(
              LengthUnit.Kilometer,
              LatLng(lat, lng),
              LatLng(gymLat, gymLng),
            );

            // Filter if it exceeds the maximum radius initially requested
            if (distance > radiusKm) continue;

            // Address logic: usually in row[6]
            String? address;
            if (row.length > 6) {
               final addrStr = row[6].toString().trim();
               if (addrStr.isNotEmpty && addrStr != '·') {
                 address = addrStr;
               }
            }

            final gym = GymModel(
              id: idCounter++,
              name: name,
              lat: gymLat,
              lng: gymLng,
              address: address,
              distanceKm: distance,
            );

            seen[gym.id] = gym;
          }
        }
      }

      final gyms = seen.values.toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return gyms;

    } catch (e) {
      debugPrint('[LocationService] CSV fetch error: $e');
      throw Exception('Gagal membaca data gym lokal.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROUTING (OSRM)
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches a driving route from [start] to [end] using the public OSRM API.
  Future<List<LatLng>?> fetchRoute(LatLng start, LatLng end) async {
    try {
      // OSRM expects longitude,latitude
      final url =
          'https://router.project-osrm.org/route/v1/driving/\${start.longitude},\${start.latitude};\${end.longitude},\${end.latitude}?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          return coordinates.map((coord) {
            // GeoJSON coordinates are [longitude, latitude]
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();
        }
      }
    } catch (e) {
      // Return null if routing fails (e.g., timeout, network issue)
    }
    return null;
  }
}
