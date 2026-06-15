import '../../domain/entities/page_entity.dart';

class PageModel extends PageEntity {
  const PageModel({
    required super.id,
    required super.slug,
    required super.title,
    required super.content,
    required super.featuredImageUrl,
  });

  factory PageModel.fromAlmadarJson(Map<String, dynamic> json) {
    final image = json['featured_image'] as Map<String, dynamic>?;
    return PageModel(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      featuredImageUrl: image?['url'] as String? ?? '',
    );
  }
}
