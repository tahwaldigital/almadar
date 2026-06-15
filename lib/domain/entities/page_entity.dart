import 'package:equatable/equatable.dart';

class PageEntity extends Equatable {
  final int id;
  final String slug;
  final String title;
  final String content;
  final String featuredImageUrl;

  const PageEntity({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    required this.featuredImageUrl,
  });

  @override
  List<Object?> get props => [id, slug];
}
