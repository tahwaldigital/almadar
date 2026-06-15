import 'package:equatable/equatable.dart';

class AuthorEntity extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String bio;
  final String avatar;
  final int postsCount;

  const AuthorEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.bio,
    required this.avatar,
    required this.postsCount,
  });

  @override
  List<Object?> get props => [id];
}
