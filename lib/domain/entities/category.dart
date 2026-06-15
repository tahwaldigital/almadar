import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int id;
  final String name;
  final String slug;
  final int count;
  final String? imageUrl;
  final String color;
  final bool featured;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.count,
    this.imageUrl,
    this.color = '#C8102E',
    this.featured = false,
  });

  @override
  List<Object?> get props => [id, slug];
}
