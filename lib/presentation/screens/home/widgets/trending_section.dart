import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../providers/news_providers.dart';
import '../../../widgets/news_card_vertical.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/skeleton_loader.dart';

class TrendingSection extends ConsumerWidget {
  const TrendingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingNewsProvider);

    return Column(
      children: [
        SectionHeader(
          title: 'تريند الآن',
          icon: Icons.trending_up_rounded,
          onSeeAll: () => context.push('/most-viewed'),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        SizedBox(
          height: 260,
          child: trendingAsync.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.gutter),
              itemBuilder: (_, __) => const TrendingCardSkeleton(),
            ),
            error: (e, _) => Center(
              child: Text(e.toString(), style: AppTypography.bodyMd.copyWith(color: AppColors.secondary)),
            ),
            data: (articles) {
              if (articles.isEmpty) {
                return Center(
                  child: Text('لا توجد أخبار رائجة', style: AppTypography.bodyMd),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 4),
                itemCount: articles.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.gutter),
                itemBuilder: (context, index) =>
                    NewsCardVertical(article: articles[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
