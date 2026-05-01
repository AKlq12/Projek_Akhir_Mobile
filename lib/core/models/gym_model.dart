/// Data model for a nearby gym / fitness centre fetched from
/// the Overpass API (OpenStreetMap).
class GymModel {
  /// OSM node ID.
  final int id;

  /// Display name — falls back to "Unnamed Gym" when OSM has no `name` tag.
  final String name;

  /// Latitude.
  final double lat;

  /// Longitude.
  final double lng;

  /// Optional street address from the `addr:street` + `addr:housenumber` tags.
  final String? address;

  /// Distance from user in kilometres (calculated client-side).
  double distanceKm;

  GymModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.distanceKm = 0.0,
  });

  /// Parses a single Overpass JSON element into a [GymModel].
  factory GymModel.fromOverpassJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final street = tags['addr:street'] as String?;
    final number = tags['addr:housenumber'] as String?;

    String? address;
    if (street != null) {
      address = number != null ? '$street No. $number' : street;
    }

    // Overpass nodes have lat/lon at top level.
    // Ways/Relations with 'out center' have them inside a 'center' object.
    double? lat;
    double? lon;

    if (json.containsKey('lat') && json.containsKey('lon')) {
      lat = (json['lat'] as num).toDouble();
      lon = (json['lon'] as num).toDouble();
    } else if (json.containsKey('center')) {
      final center = json['center'] as Map<String, dynamic>;
      lat = (center['lat'] as num).toDouble();
      lon = (center['lon'] as num).toDouble();
    }

    return GymModel(
      id: json['id'] as int,
      name: (tags['name'] as String?) ?? 'Unnamed Gym',
      lat: lat ?? 0.0,
      lng: lon ?? 0.0,
      address: address,
    );
  }
}
