import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/color_utils.dart';
import '../../../domain/entities/category.dart';
import '../../providers/news_providers.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_views.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.9)
            : AppColors.surface.withValues(alpha: 0.9),
        toolbarHeight: 64,
        titleSpacing: 16,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.asset(
                'assets/images/logo.webp',
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const _CategoriesLoadingSkeleton(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.grid_view_rounded,
              title: 'لا توجد أقسام',
              message: 'لم نعثر على أقسام لعرضها حالياً.',
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryContainer,
            onRefresh: () async => ref.invalidate(categoriesProvider),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerMargin,
                      AppSpacing.stackLg,
                      AppSpacing.containerMargin,
                      2,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'الأقسام',
                          style: AppTypography.headlineMd.copyWith(
                            color: isDark
                                ? AppColors.inverseOnSurface
                                : AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${categories.length} قسم',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subtitle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerMargin, 4, AppSpacing.containerMargin, 12),
                    child: Text(
                      'اختر القسم الذي يهمك لمتابعة آخر الأخبار',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                    ),
                  ),
                ),

                // List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerMargin),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _CategoryTile(
                        category: categories[i],
                        index: i,
                        isDark: isDark,
                      ),
                      childCount: categories.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// fallback palette — loops if more categories than colors
const _kPalette = [
  Color(0xFF1A3A6B),
  Color(0xFF9D4300),
  Color(0xFF1A5B2F),
  Color(0xFF6B1A1A),
  Color(0xFF4A1A6B),
  Color(0xFF0B4D6B),
  Color(0xFF6B5B1A),
  Color(0xFF1A6B5B),
];

IconData _iconFor(String name) {
  if (name.contains('رياض')) return Icons.sports_soccer_rounded;
  if (name.contains('تقني')) return Icons.memory_rounded;
  if (name.contains('مجتمع')) return Icons.groups_rounded;
  if (name.contains('محلي')) return Icons.location_city_rounded;
  if (name.contains('ديرت')) return Icons.place_rounded;
  if (name.contains('وفيات')) return Icons.brightness_3_rounded;
  if (name.contains('أفراح') || name.contains('تهاني')) {
    return Icons.celebration_rounded;
  }
  if (name.contains('شعر') || name.contains('بيات')) return Icons.menu_book_rounded;
  if (name.contains('إعلان') || name.contains('اعلان')) {
    return Icons.campaign_rounded;
  }
  if (name.contains('فيديو')) return Icons.smart_display_rounded;
  if (name.contains('راسل')) return Icons.mail_outline_rounded;
  if (name.contains('مقالات')) return Icons.article_rounded;
  if (name.contains('هنا')) return Icons.explore_rounded;
  if (name.contains('أهم') || name.contains('اهم') || name.contains('عاجل')) {
    return Icons.feed_rounded;
  }
  return Icons.label_important_rounded;
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final int index;
  final bool isDark;
  const _CategoryTile({
    required this.category,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = category.color.isNotEmpty
        ? ColorUtils.fromHex(category.color)
        : _kPalette[index % _kPalette.length];
    final tileColor = isDark ? const Color(0xFF15223C) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Colored accent bar (right edge in RTL)
                Container(width: 5, color: baseColor),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/category/${category.id}',
                          extra: category),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_left_rounded,
                                color: AppColors.secondary, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    category.name,
                                    style: AppTypography.labelMd.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.inverseOnSurface
                                          : AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${category.count} خبر',
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Icon circle
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: baseColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_iconFor(category.name),
                                  color: baseColor, size: 22),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _CategoriesLoadingSkeleton extends StatelessWidget {
  const _CategoriesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin, 24, AppSpacing.containerMargin, 0),
      child: ListView.separated(
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 74,
          radius: 14,
        ),
      ),
    );
  }
}
