import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/news_providers.dart';
import '../../widgets/news_card_horizontal.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_views.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedArticlesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.9)
            : AppColors.surface.withValues(alpha: 0.9),
        title: Text(
          'المحفوظات',
          style: AppTypography.headlineLgMobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (savedAsync.value?.isNotEmpty == true)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('مسح الكل'),
                    content: const Text('هل تريد حذف كل المقالات المحفوظة؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('حذف', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(savedArticlesProvider.notifier).clearAll();
                }
              },
              child: Text(
                'مسح الكل',
                style: AppTypography.labelMd.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: savedAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
          itemBuilder: (_, __) => const NewsCardSkeleton(),
        ),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.read(savedArticlesProvider.notifier).load(),
        ),
        data: (articles) {
          if (articles.isEmpty) {
            return EmptyState(
              icon: Icons.bookmark_outline_rounded,
              title: 'لا توجد مقالات محفوظة',
              message: 'احفظ المقالات التي تريد قراءتها لاحقاً لتجدها هنا.',
              actionLabel: 'تصفّح الأخبار',
              onAction: () => context.go('/home'),
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryContainer,
            onRefresh: () async =>
                ref.read(savedArticlesProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              itemCount: articles.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
              itemBuilder: (context, index) =>
                  NewsCardHorizontal(article: articles[index]),
            ),
          );
        },
      ),
    );
  }
}
