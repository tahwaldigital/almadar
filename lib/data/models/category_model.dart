import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.count,
    super.imageUrl,
    super.color,
    super.featured,
  });

  /// Local-cache round-trip (matches [toJson]).
  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        imageUrl: json['imageUrl'] as String?,
        color: json['color'] as String? ?? '#C8102E',
        featured: json['featured'] as bool? ?? false,
      );

  /// Parses the Almadar Mobile API category shape (almadar/v1).
  factory CategoryModel.fromAlmadarJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      imageUrl: image?['url'] as String?,
      color: json['color'] as String? ?? '#C8102E',
      featured: json['featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'count': count,
        'imageUrl': imageUrl,
        'color': color,
        'featured': featured,
      };
}
