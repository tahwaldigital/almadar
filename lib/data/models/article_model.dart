import '../../core/utils/html_parser_utils.dart';
import '../../domain/entities/article.dart';

VideoInfo? _videoFromJson(Map<String, dynamic>? v) {
  if (v == null) return null;
  final url = v['url'] as String? ?? '';
  if (url.isEmpty) return null;
  return VideoInfo(
    provider: v['provider'] as String? ?? 'file',
    id: v['id']?.toString() ?? '',
    url: url,
    embed: v['embed'] as String? ?? url,
  );
}

class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.title,
    required super.excerpt,
    required super.content,
    required super.featuredImageUrl,
    required super.authorName,
    required super.authorAvatarUrl,
    super.authorId,
    required super.datePublished,
    required super.categoryName,
    required super.categoryId,
    required super.tags,
    required super.viewCount,
    required super.commentCount,
    required super.isBreaking,
    required super.isTrending,
    required super.slug,
    required super.link,
    super.video,
  });

  factory ArticleModel.fromWordPressJson(
    Map<String, dynamic> json, {
    String categoryName = '',
    int categoryId = 0,
    String authorName = '',
    String authorAvatarUrl = '',
    String featuredImageUrl = '',
  }) {
    final embeddedData = json['_embedded'] as Map<String, dynamic>?;

    // Extract featured image from embedded data
    String imageUrl = featuredImageUrl;
    if (embeddedData != null) {
      final wpFeaturedMedia = embeddedData['wp:featuredmedia'] as List?;
      if (wpFeaturedMedia != null && wpFeaturedMedia.isNotEmpty) {
        final media = wpFeaturedMedia[0] as Map<String, dynamic>?;
        imageUrl = media?['source_url'] as String? ?? '';
      }

      // Extract author from embedded data
      if (authorName.isEmpty) {
        final wpAuthors = embeddedData['author'] as List?;
        if (wpAuthors != null && wpAuthors.isNotEmpty) {
          final author = wpAuthors[0] as Map<String, dynamic>?;
          authorName = author?['name'] as String? ?? '';
          final avatarUrls = author?['avatar_urls'] as Map<String, dynamic>?;
          authorAvatarUrl = avatarUrls?['96'] as String? ?? '';
        }
      }

      // Extract category from embedded data
      if (categoryName.isEmpty) {
        final terms = embeddedData['wp:term'] as List?;
        if (terms != null && terms.isNotEmpty) {
          final categories = terms[0] as List?;
          if (categories != null && categories.isNotEmpty) {
            final cat = categories[0] as Map<String, dynamic>?;
            categoryName = cat?['name'] as String? ?? '';
            categoryId = cat?['id'] as int? ?? 0;
          }
        }
      }
    }

    final categories = json['categories'] as List?;
    final primaryCategoryId = (categories != null && categories.isNotEmpty)
        ? categories[0] as int
        : categoryId;

    return ArticleModel(
      id: json['id'] as int? ?? 0,
      title: HtmlParserUtils.stripHtml(
        (json['title'] as Map<String, dynamic>?)?['rendered'] as String? ?? '',
      ),
      excerpt: HtmlParserUtils.stripHtml(
        (json['excerpt'] as Map<String, dynamic>?)?['rendered'] as String? ?? '',
      ),
      content: (json['content'] as Map<String, dynamic>?)?['rendered'] as String? ?? '',
      featuredImageUrl: imageUrl,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      datePublished: json['date'] as String? ?? '',
      categoryName: categoryName,
      categoryId: primaryCategoryId,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      viewCount: 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isBreaking: false,
      isTrending: false,
      slug: json['slug'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }

  /// Parses the Almadar Mobile API post shape (almadar/v1).
  factory ArticleModel.fromAlmadarJson(
    Map<String, dynamic> json, {
    bool isTrending = false,
  }) {
    final image = json['featured_image'] as Map<String, dynamic>?;
    final author = json['author'] as Map<String, dynamic>?;
    final primaryCat = json['primary_category'] as Map<String, dynamic>?;
    final tagsList = (json['tags'] as List?)
            ?.map((t) => (t as Map<String, dynamic>)['name']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .toList() ??
        <String>[];

    return ArticleModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      featuredImageUrl: image?['url'] as String? ?? '',
      authorName: author?['name'] as String? ?? '',
      authorAvatarUrl: author?['avatar'] as String? ?? '',
      authorId: author?['id'] as int? ?? 0,
      datePublished: json['date'] as String? ?? '',
      categoryName: primaryCat?['name'] as String? ?? '',
      categoryId: primaryCat?['id'] as int? ?? 0,
      tags: tagsList,
      viewCount: json['views'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isBreaking: json['is_breaking'] as bool? ?? false,
      isTrending: isTrending,
      slug: json['slug'] as String? ?? '',
      link: json['share_url'] as String? ?? json['link'] as String? ?? '',
      video: _videoFromJson(json['video'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'excerpt': excerpt,
        'content': content,
        'featuredImageUrl': featuredImageUrl,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'authorId': authorId,
        'datePublished': datePublished,
        'categoryName': categoryName,
        'categoryId': categoryId,
        'tags': tags,
        'viewCount': viewCount,
        'commentCount': commentCount,
        'isBreaking': isBreaking,
        'isTrending': isTrending,
        'slug': slug,
        'link': link,
        'video': video == null
            ? null
            : {
                'provider': video!.provider,
                'id': video!.id,
                'url': video!.url,
                'embed': video!.embed,
              },
      };

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id'] as int,
        title: json['title'] as String,
        excerpt: json['excerpt'] as String,
        content: json['content'] as String,
        featuredImageUrl: json['featuredImageUrl'] as String,
        authorName: json['authorName'] as String,
        authorAvatarUrl: json['authorAvatarUrl'] as String,
        authorId: json['authorId'] as int? ?? 0,
        datePublished: json['datePublished'] as String,
        categoryName: json['categoryName'] as String,
        categoryId: json['categoryId'] as int,
        tags: (json['tags'] as List).map((e) => e.toString()).toList(),
        viewCount: json['viewCount'] as int,
        commentCount: json['commentCount'] as int,
        isBreaking: json['isBreaking'] as bool,
        isTrending: json['isTrending'] as bool,
        slug: json['slug'] as String,
        link: json['link'] as String,
        video: _videoFromJson(json['video'] as Map<String, dynamic>?),
      );
}
