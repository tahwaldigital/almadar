import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/article.dart';
import '../providers/read_providers.dart';

/// بطاقة بارزة (16:9) للخبر الأول/المميّز في القائمة — تمايز بصري عن العادي.
class NewsCardFeatured extends ConsumerWidget {
  final Article article;
  const NewsCardFeatured({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = ref.watch(readArticlesProvider).contains(article.id);
    return Semantics(
      button: true,
      label: 'خبر مميّز: ${article.title}',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/article/${article.id}', extra: article),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'hero-article-${article.id}',
                    child: CachedNetworkImage(
                      imageUrl: article.featuredImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(Icons.image_outlined, size: 48, color: AppColors.secondary),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.82)],
                        stops: const [0.32, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.gutter,
                    left: AppSpacing.gutter,
                    bottom: AppSpacing.gutter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: article.isBreaking ? AppColors.breakingRed : AppColors.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                article.isBreaking ? 'عاجل' : article.categoryName,
                                style: AppTypography.labelSm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineLgMobile.copyWith(
                            color: Colors.white,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              AppDateUtils.timeAgo(article.datePublished),
                              style: AppTypography.labelSm.copyWith(color: Colors.white70),
                            ),
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
