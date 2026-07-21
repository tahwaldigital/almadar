import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/article.dart';
import '../providers/news_providers.dart';
import '../providers/read_providers.dart';

class NewsCardHorizontal extends ConsumerWidget {
  final Article article;
  final bool showBookmark;

  const NewsCardHorizontal({
    super.key,
    required this.article,
    this.showBookmark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRead = ref.watch(readArticlesProvider).contains(article.id);

    return Semantics(
      button: true,
      label: 'خبر: ${article.title}',
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181E) : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/article/${article.id}', extra: article),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: article.featuredImageUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 96,
                    height: 96,
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.image_outlined, color: AppColors.secondary),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 96,
                    height: 96,
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.broken_image_outlined, color: AppColors.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!isRead) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            article.categoryName,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_outlined, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          AppDateUtils.timeAgo(article.datePublished),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        if (showBookmark) ...[
                          const Spacer(),
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'حفظ',
                              onPressed: () async {
                                await ref.read(savedArticlesProvider.notifier).toggle(article);
                              },
                              icon: const Icon(
                                Icons.bookmark_outline,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
