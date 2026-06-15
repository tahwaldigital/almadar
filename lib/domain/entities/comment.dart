import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final int id;
  final int postId;
  final int parent;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String date;
  final String dateHuman;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.parent,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.date,
    required this.dateHuman,
  });

  @override
  List<Object?> get props => [id];
}
