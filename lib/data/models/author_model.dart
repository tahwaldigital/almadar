import '../../domain/entities/author.dart';

class AuthorModel extends AuthorEntity {
  const AuthorModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.bio,
    required super.avatar,
    required super.postsCount,
  });

  factory AuthorModel.fromAlmadarJson(Map<String, dynamic> json) => AuthorModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
        postsCount: json['posts_count'] as int? ?? 0,
      );
}
