import 'muscle_model.dart';

/// Model for exercise data from wger.de API.
///
/// The basic exercise comes from `/api/v2/exercise/` and
/// the full info (with translations, images, muscles) from `/api/v2/exerciseinfo/`.
class Exercise {
  final int id;
  final String uuid;
  final int categoryId;
  final String categoryName;
  final String name;
  final String description;
  final List<Muscle> muscles;
  final List<Muscle> musclesSecondary;
  final List<int> equipmentIds;
  final List<String> equipmentNames;
  final List<String> imageUrls;
  final int? variations;

  const Exercise({
    required this.id,
    this.uuid = '',
    required this.categoryId,
    this.categoryName = '',
    required this.name,
    this.description = '',
    this.muscles = const [],
    this.musclesSecondary = const [],
    this.equipmentIds = const [],
    this.equipmentNames = const [],
    this.imageUrls = const [],
    this.variations,
  });

  /// Creates from the `/api/v2/exercise/` endpoint (basic data).
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as int,
      uuid: (json['uuid'] as String?) ?? '',
      categoryId: json['category'] as int,
      name: '', // Name comes from translations
      muscles: (json['muscles'] as List<dynamic>?)
              ?.map((m) => m is Map<String, dynamic>
                  ? Muscle.fromJson(m)
                  : Muscle(id: m as int, name: ''))
              .toList() ??
          [],
      musclesSecondary: (json['muscles_secondary'] as List<dynamic>?)
              ?.map((m) => m is Map<String, dynamic>
                  ? Muscle.fromJson(m)
                  : Muscle(id: m as int, name: ''))
              .toList() ??
          [],
      equipmentIds: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e is int ? e : 0)
              .toList() ??
          [],
      variations: json['variations'] as int?,
    );
  }

  /// Creates from the `/api/v2/exerciseinfo/` endpoint (full data with translations).
  factory Exercise.fromInfoJson(Map<String, dynamic> json) {
    // Extract English translation (language id = 2)
    String name = '';
    String description = '';
    final translations = json['translations'] as List<dynamic>? ?? [];
    for (final t in translations) {
      if (t is Map<String, dynamic> && t['language'] == 2) {
        name = (t['name'] as String?) ?? '';
        description = (t['description'] as String?) ?? '';
        break;
      }
    }
    // Fallback: use first available translation
    if (name.isEmpty && translations.isNotEmpty) {
      final first = translations.first as Map<String, dynamic>;
      name = (first['name'] as String?) ?? 'Unknown Exercise';
      description = (first['description'] as String?) ?? '';
    }

    // Extract images
    final images = (json['images'] as List<dynamic>? ?? [])
        .map((img) => (img as Map<String, dynamic>)['image'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    // Extract category name
    final category = json['category'] as Map<String, dynamic>?;
    final categoryName = (category?['name'] as String?) ?? '';
    final categoryId = (category?['id'] as int?) ?? 0;

    // Extract muscles
    final muscles = (json['muscles'] as List<dynamic>? ?? [])
        .map((m) => Muscle.fromJson(m as Map<String, dynamic>))
        .toList();
    final musclesSecondary =
        (json['muscles_secondary'] as List<dynamic>? ?? [])
            .map((m) => Muscle.fromJson(m as Map<String, dynamic>))
            .toList();

    // Extract equipment
    final equipment = (json['equipment'] as List<dynamic>? ?? []);
    final equipmentIds = equipment
        .map((e) => (e as Map<String, dynamic>)['id'] as int)
        .toList();
    final equipmentNames = equipment
        .map((e) => (e as Map<String, dynamic>)['name'] as String)
        .toList();

    return Exercise(
      id: json['id'] as int,
      uuid: (json['uuid'] as String?) ?? '',
      categoryId: categoryId,
      categoryName: categoryName,
      name: name,
      description: description,
      muscles: muscles,
      musclesSecondary: musclesSecondary,
      equipmentIds: equipmentIds,
      equipmentNames: equipmentNames,
      imageUrls: images,
      variations: json['variations'] as int?,
    );
  }

  /// Creates from search results that combine exercise + translation data.
  factory Exercise.fromSearchJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['data']?['id'] as int? ?? json['id'] as int? ?? 0,
      categoryId: json['data']?['category'] as int? ?? json['category'] as int? ?? 0,
      name: json['value'] as String? ?? json['name'] as String? ?? '',
      description: '',
      imageUrls: json['data']?['image'] != null
          ? [json['data']['image'] as String]
          : [],
      categoryName: json['data']?['category_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'category': categoryId,
        'category_name': categoryName,
        'name': name,
        'description': description,
        'image_urls': imageUrls,
        'equipment_names': equipmentNames,
      };

  /// Returns the first image URL or null.
  String? get primaryImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Strips HTML tags from description.
  String get cleanDescription =>
      description.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
