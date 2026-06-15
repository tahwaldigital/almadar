import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/article.dart';

class NewsCardVertical extends StatelessWidget {
  final Article article;
  final double width;

  const NewsCardVertical({
    super.key,
    required this.article,
    this.width = 280,
  });

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ألف';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inverseOnSurface : AppColors.onSurface;

    return Semantics(
      button: true,
      label: 'خبر: ${article.title}',
      child: Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181E) : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/article/${article.id}', extra: article),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: article.featuredImageUrl,
                    width: width,
                    height: 158,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 158,
                      color: AppColors.surfaceContainerHigh,
                      child: const Icon(Icons.image_outlined, size: 40, color: AppColors.secondary),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 158,
                      color: AppColors.surfaceContainerHigh,
                      child: const Icon(Icons.broken_image_outlined, size: 40, color: AppColors.secondary),
                    ),
                  ),
                ),
                // Legibility scrim for the category pill.
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.30), Colors.transparent],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                ),
                if (article.hasVideo)
                  const Positioned.fill(
                    child: Center(
                      child: Icon(Icons.play_circle_fill_rounded, size: 46, color: Colors.white),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: article.isBreaking ? AppColors.breakingRed : AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      article.isBreaking ? 'عاجل' : article.categoryName,
                      style: AppTypography.labelSm.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ink,
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        AppDateUtils.timeAgo(article.datePublished),
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      if (article.viewCount > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.visibility_outlined,
                            size: 13, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(article.viewCount),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.secondary,
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
    );
  }
}
