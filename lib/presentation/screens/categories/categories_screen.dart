import 'package:cached_network_image/cached_network_image.dart';
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
        loading: () => _CategoriesLoadingSkeleton(),
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
                      AppSpacing.stackMd,
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
                          'جميع الأقسام',
                          style: AppTypography.headlineMd.copyWith(
                            color: isDark
                                ? AppColors.inverseOnSurface
                                : AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

                // Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerMargin,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _CategoryCard(
                        category: categories[i],
                        index: i,
                      ),
                      childCount: categories.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
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

class _CategoryCard extends StatelessWidget {
  final Category category;
  final int index;
  const _CategoryCard({required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    final baseColor = category.color.isNotEmpty
        ? ColorUtils.fromHex(category.color)
        : _kPalette[index % _kPalette.length];

    return GestureDetector(
      onTap: () => context.push('/category/${category.id}', extra: category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: image or solid color
              if (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: category.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: baseColor),
                )
              else
                Container(color: baseColor),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      baseColor.withValues(alpha: 0.15),
                      baseColor.withValues(alpha: 0.90),
                    ],
                  ),
                ),
              ),

              // Orange accent line at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryContainer,
                        AppColors.primaryContainer.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.headlineMd.copyWith(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${category.count} خبر',
                          style: AppTypography.labelSm.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
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
    );
  }
}

class _CategoriesLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: double.infinity,
          radius: 16,
        ),
      ),
    );
  }
}
