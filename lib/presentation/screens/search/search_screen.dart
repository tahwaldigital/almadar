import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/category.dart';
import '../../providers/news_providers.dart';
import '../../providers/providers.dart';
import '../../providers/search_providers.dart';
import '../../widgets/news_card_horizontal.dart';
import '../../widgets/skeleton_loader.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(searchNotifierProvider.notifier).loadMore();
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchNotifierProvider.notifier).search(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchAsync = ref.watch(searchNotifierProvider);
    final isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.9)
            : AppColors.surface.withValues(alpha: 0.9),
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'بحث',
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D1B2A) : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? AppColors.primaryContainer
                            : AppColors.outline.withValues(alpha: 0.2),
                        width: _focusNode.hasFocus ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن الأخبار، المواضيع...',
                              hintStyle: AppTypography.bodyMd.copyWith(
                                color: AppColors.secondary.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: AppTypography.bodyMd.copyWith(
                              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                            ),
                            onChanged: (v) => setState(() {}),
                            onSubmitted: _performSearch,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref.read(searchNotifierProvider.notifier).clear();
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.close_rounded, size: 18, color: AppColors.secondary),
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // If no search query — show explore view
          if (!isSearching) ...[
            // Trending tags — مشتقّة من الأخبار الرائجة فعليًا (لا محتوى ثابت).
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, _) {
                  final trendingAsync = ref.watch(trendingNewsProvider);
                  final tags = trendingAsync.maybeWhen(
                    data: (articles) {
                      final seen = <String>{};
                      for (final a in articles) {
                        for (final t in a.tags) {
                          final tag = t.trim();
                          if (tag.isNotEmpty) seen.add(tag);
                        }
                      }
                      return seen.take(8).toList();
                    },
                    orElse: () => const <String>[],
                  );
                  if (tags.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text('الأكثر تداولاً',
                                style: AppTypography.headlineMd.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags
                              .map((tag) => _TrendingTag(
                                    tag: '#$tag',
                                    onTap: () {
                                      _searchController.text = tag;
                                      _performSearch(tag);
                                      setState(() {});
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Search History
            _SearchHistorySection(
              onQuerySelected: (q) {
                _searchController.text = q;
                _performSearch(q);
                setState(() {});
              },
            ),

            // Explore Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore_outlined, size: 18, color: AppColors.onSurface),
                        const SizedBox(width: 6),
                        Text('استكشف الأقسام', style: AppTypography.headlineMd.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Consumer(
                      builder: (context, ref, _) {
                        final categoriesAsync = ref.watch(categoriesProvider);
                        return categoriesAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (categories) => GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.6,
                            ),
                            itemCount: categories.take(4).length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              return _CategoryGridItem(category: cat);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Search Results
          if (isSearching)
            searchAsync.when(
              loading: () => SliverList.separated(
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                  child: NewsCardSkeleton(),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 44, color: AppColors.secondary),
                        const SizedBox(height: 8),
                        Text(
                          'تعذّر إكمال البحث، حاول مرة أخرى',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.secondary),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج لـ "${_searchController.text}"',
                              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                    child: NewsCardHorizontal(article: articles[index]),
                  ),
                );
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _TrendingTag extends StatelessWidget {
  final String tag;
  final VoidCallback onTap;
  const _TrendingTag({required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.05)),
        ),
        child: Text(
          tag,
          style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _SearchHistorySection extends ConsumerWidget {
  final ValueChanged<String> onQuerySelected;
  const _SearchHistorySection({required this.onQuerySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (history) {
        if (history.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text('عمليات البحث الأخيرة',
                            style: AppTypography.headlineMd.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(newsLocalDataSourceProvider).clearSearchHistory();
                        ref.invalidate(searchHistoryProvider);
                      },
                      child: Text(
                        'مسح الكل',
                        style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                ...history.map(
                  (q) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline.withValues(alpha: 0.05)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded, color: AppColors.secondary),
                      title: Text(q, style: AppTypography.bodyMd),
                      trailing: IconButton(
                        onPressed: () async {
                          await ref.read(newsLocalDataSourceProvider).removeSearchQuery(q);
                          ref.invalidate(searchHistoryProvider);
                        },
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.secondary),
                      ),
                      onTap: () => onQuerySelected(q),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  final Category category;
  const _CategoryGridItem({required this.category});

  static const _colors = [
    Color(0xFF1A3A6B),
    Color(0xFF1A5B2F),
    Color(0xFF6B1A1A),
    Color(0xFF4A1A6B),
  ];

  @override
  Widget build(BuildContext context) {
    final colorIndex = category.id % _colors.length;

    return GestureDetector(
      onTap: () => context.push('/category/${category.id}', extra: category),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: _colors[colorIndex]),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              left: 12,
              child: Text(
                category.name,
                style: AppTypography.headlineMd.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
