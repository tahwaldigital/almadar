import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/content_providers.dart';
import '../../widgets/news_card_horizontal.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_views.dart';

class MostViewedScreen extends ConsumerWidget {
  const MostViewedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mostViewedAsync = ref.watch(mostViewedProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: const Text('الأكثر مشاهدة'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: mostViewedAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: Column(children: [NewsCardSkeleton(), NewsCardSkeleton(), NewsCardSkeleton()]),
        ),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(mostViewedProvider),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyState(
              icon: Icons.local_fire_department_outlined,
              title: 'لا توجد أخبار بعد',
              message: 'ستظهر هنا الأخبار الأكثر مشاهدة قريباً.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(mostViewedProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
              itemBuilder: (_, i) => NewsCardHorizontal(article: posts[i]),
            ),
          );
        },
      ),
    );
  }
}
