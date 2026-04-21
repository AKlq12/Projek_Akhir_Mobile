/// Model for muscle data from wger.de API.
///
/// Maps to `/api/v2/muscle/` endpoint.
class Muscle {
  final int id;
  final String name;
  final String nameEn;
  final bool isFront;
  final String? imageUrlMain;
  final String? imageUrlSecondary;

  const Muscle({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.isFront = true,
    this.imageUrlMain,
    this.imageUrlSecondary,
  });

  factory Muscle.fromJson(Map<String, dynamic> json) {
    return Muscle(
      id: json['id'] as int,
      name: json['name'] as String,
      nameEn: (json['name_en'] as String?) ?? '',
      isFront: (json['is_front'] as bool?) ?? true,
      imageUrlMain: json['image_url_main'] as String?,
      imageUrlSecondary: json['image_url_secondary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_en': nameEn,
        'is_front': isFront,
        'image_url_main': imageUrlMain,
        'image_url_secondary': imageUrlSecondary,
      };

  /// Returns the display name — prefers English name, falls back to Latin name.
  String get displayName => nameEn.isNotEmpty ? nameEn : name;
}
