import '../../domain/entities/comment.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.postId,
    required super.parent,
    required super.authorName,
    required super.authorAvatar,
    required super.content,
    required super.date,
    required super.dateHuman,
  });

  factory CommentModel.fromAlmadarJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as int? ?? 0,
        postId: json['post_id'] as int? ?? 0,
        parent: json['parent'] as int? ?? 0,
        authorName: json['author_name'] as String? ?? '',
        authorAvatar: json['author_avatar'] as String? ?? '',
        content: json['content'] as String? ?? '',
        date: json['date'] as String? ?? '',
        dateHuman: json['date_human'] as String? ?? '',
      );
}
