import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/content_providers.dart';
import '../../widgets/news_card_horizontal.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_views.dart';

class AuthorScreen extends ConsumerWidget {
  final int authorId;
  final String authorName;

  const AuthorScreen({super.key, required this.authorId, this.authorName = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authorAsync = ref.watch(authorProvider(authorId));
    final postsAsync = ref.watch(authorPostsProvider(authorId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: Text(authorName.isNotEmpty ? authorName : 'الكاتب'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authorProvider(authorId));
          ref.invalidate(authorPostsProvider(authorId));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            authorAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (author) => Column(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: author.avatar,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(Icons.person, size: 44),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(author.name, style: AppTypography.headlineLgMobile),
                  if (author.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      author.bio,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${author.postsCount} مقال',
                    style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                  ),
                  const Divider(height: 32),
                ],
              ),
            ),
            Text('أحدث مقالاته', style: AppTypography.headlineMd),
            const SizedBox(height: AppSpacing.stackMd),
            postsAsync.when(
              loading: () => const Column(
                children: [NewsCardSkeleton(), NewsCardSkeleton(), NewsCardSkeleton()],
              ),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(authorPostsProvider(authorId)),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.article_outlined,
                    title: 'لا توجد مقالات',
                    message: 'لم ينشر هذا الكاتب مقالات بعد.',
                  );
                }
                return Column(
                  children: posts
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                            child: NewsCardHorizontal(article: a),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
