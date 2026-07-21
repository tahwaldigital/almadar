import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/article.dart';
import '../../../domain/entities/category.dart';
import '../../providers/news_providers.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_views.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final Category? category;
  final int categoryId;

  const CategoryScreen({
    super.key,
    this.category,
    required this.categoryId,
  });

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _scrollController = ScrollController();
  bool _sortByViews = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(categoryNewsProvider(widget.categoryId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final articlesAsync = ref.watch(categoryNewsProvider(widget.categoryId));
    final notifier = ref.read(categoryNewsProvider(widget.categoryId).notifier);
    final categoryName = widget.category?.name ?? 'الأخبار';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.9)
            : AppColors.surface.withValues(alpha: 0.9),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          color: AppColors.primary,
        ),
        title: Text(
          categoryName,
          style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search_outlined),
            color: AppColors.primary,
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryContainer,
        onRefresh: () async =>
            ref.read(categoryNewsProvider(widget.categoryId).notifier).loadInitial(),
        child: articlesAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
            itemBuilder: (_, __) => const NewsCardSkeleton(),
          ),
          error: (e, _) => ErrorState(
            error: e,
            onRetry: () => notifier.loadInitial(),
          ),
          data: (articles) {
            if (articles.isEmpty) {
              return const EmptyState(
                icon: Icons.article_outlined,
                title: 'لا توجد أخبار',
                message: 'لا توجد أخبار في هذا القسم حالياً.',
              );
            }

            final items = _sortByViews
                ? ([...articles]..sort((a, b) => b.viewCount.compareTo(a.viewCount)))
                : articles;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Featured Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.containerMargin),
                    child: _FeaturedCard(article: items.first),
                  ),
                ),
                // Sub-categories chips
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.containerMargin),
                      children: [
                        _SubCategoryChip(label: 'الكل', isSelected: true),
                        const SizedBox(width: 8),
                        _SubCategoryChip(label: 'أخبار محلية'),
                        const SizedBox(width: 8),
                        _SubCategoryChip(label: 'شؤون دولية'),
                        const SizedBox(width: 8),
                        _SubCategoryChip(label: 'تقارير خاصة'),
                        const SizedBox(width: 8),
                        _SubCategoryChip(label: 'مقابلات'),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.stackMd)),
                // Sort header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerMargin),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('آخر الأخبار',
                            style: AppTypography.headlineMd.copyWith(fontWeight: FontWeight.w700)),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _sortByViews = !_sortByViews),
                          icon: const Icon(Icons.tune_rounded, size: 16),
                          label: Text(_sortByViews ? 'الأكثر مشاهدة' : 'الأحدث'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: BorderSide(
                              color: AppColors.outlineVariant.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: AppTypography.labelMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.stackMd)),
                // News list (skipping first which is featured)
                SliverList.separated(
                  itemCount: items.length + (notifier.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                          ),
                        ),
                      );
                    }
                    return _CategoryNewsItem(article: items[index]);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Article article;
  const _FeaturedCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/article/${article.id}', extra: article),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: article.featuredImageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
                errorWidget: (_, __, ___) => Container(color: AppColors.surfaceContainerHigh),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.onBackground.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'خبر عاجل',
                        style: AppTypography.labelMd.copyWith(color: AppColors.onPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: AppTypography.headlineLgMobile.copyWith(
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined, size: 14, color: Colors.white70),
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
    );
  }
}

class _SubCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _SubCategoryChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)]
            : null,
      ),
      child: Text(
        label,
        style: AppTypography.labelMd.copyWith(
          color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CategoryNewsItem extends ConsumerWidget {
  final Article article;
  const _CategoryNewsItem({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/article/${article.id}', extra: article),
      child: Container(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerMargin,
          vertical: AppSpacing.stackLg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: article.featuredImageUrl,
                width: 112,
                height: 112,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(width: 112, height: 112, color: AppColors.surfaceContainerHigh),
                errorWidget: (_, __, ___) => Container(
                  width: 112,
                  height: 112,
                  color: AppColors.surfaceContainerHigh,
                  child: const Icon(Icons.image_outlined, color: AppColors.secondary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppTypography.headlineMd.copyWith(
                      color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.excerpt,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history_outlined, size: 14, color: AppColors.secondary.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.timeAgo(article.datePublished),
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.secondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final saved = await ref
                                  .read(savedArticlesProvider.notifier)
                                  .toggle(article);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(saved ? 'تم الحفظ' : 'تمت الإزالة من المحفوظات'),
                                  duration: const Duration(seconds: 1),
                                ));
                              }
                            },
                            child: Icon(Icons.bookmark_outline_rounded, size: 18, color: AppColors.secondary),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Share.share(article.link),
                            child: Icon(Icons.share_outlined, size: 18, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
