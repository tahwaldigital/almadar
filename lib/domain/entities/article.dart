import 'package:equatable/equatable.dart';

/// Native video descriptor for an article (YouTube / Vimeo / direct file).
class VideoInfo extends Equatable {
  final String provider; // youtube | vimeo | file
  final String id;
  final String url;
  final String embed;

  const VideoInfo({
    required this.provider,
    required this.id,
    required this.url,
    required this.embed,
  });

  bool get isYoutube => provider == 'youtube';
  bool get isVimeo => provider == 'vimeo';
  bool get isFile => provider == 'file';

  @override
  List<Object?> get props => [provider, id, url];
}

class Article extends Equatable {
  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String featuredImageUrl;
  final String authorName;
  final String authorAvatarUrl;
  final int authorId;
  final String datePublished;
  final String categoryName;
  final int categoryId;
  final List<String> tags;
  final int viewCount;
  final int commentCount;
  final bool isBreaking;
  final bool isTrending;
  final String slug;
  final String link;
  final VideoInfo? video;

  /// اسم المصدر الأصلي للخبر المنقول (مثال: "وكالة الأنباء"). فارغ للأخبار الأصلية.
  final String source;

  /// رابط الخبر الأصلي عند المصدر (اختياري).
  final String sourceUrl;

  bool get hasVideo => video != null;

  /// هل الخبر منقول من مصدر خارجي؟
  bool get hasSource => source.trim().isNotEmpty;

  const Article({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.featuredImageUrl,
    required this.authorName,
    required this.authorAvatarUrl,
    this.authorId = 0,
    required this.datePublished,
    required this.categoryName,
    required this.categoryId,
    required this.tags,
    required this.viewCount,
    required this.commentCount,
    required this.isBreaking,
    required this.isTrending,
    required this.slug,
    required this.link,
    this.video,
    this.source = '',
    this.sourceUrl = '',
  });

  @override
  List<Object?> get props => [id, title, slug];
}
