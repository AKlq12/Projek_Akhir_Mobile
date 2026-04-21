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

    return GymModel(
      id: json['id'] as int,
      name: (tags['name'] as String?) ?? 'Unnamed Gym',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lon'] as num).toDouble(),
      address: address,
    );
  }
}
