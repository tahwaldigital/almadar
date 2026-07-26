import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../providers/news_providers.dart';
import '../../../widgets/app_error_widget.dart';
import '../../../widgets/news_card_featured.dart';
import '../../../widgets/news_card_horizontal.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/skeleton_loader.dart';

class LatestNewsSection extends ConsumerStatefulWidget {
  final int categoryId;
  const LatestNewsSection({super.key, this.categoryId = 0});

  @override
  ConsumerState<LatestNewsSection> createState() => _LatestNewsSectionState();
}

class _LatestNewsSectionState extends ConsumerState<LatestNewsSection> {
  /// القائمة هنا غير قابلة للتمرير بذاتها (shrinkWrap + NeverScrollable)، لذا
  /// نستمع لتمرير الـScrollable الأب لتشغيل التحميل التدريجي.
  ScrollPosition? _parentPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _parentPosition)) {
      _parentPosition?.removeListener(_onScroll);
      _parentPosition = position;
      _parentPosition?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _parentPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final position = _parentPosition;
    if (position == null || !position.hasPixels) return;
    // محتوى أقصر من الشاشة (لا يوجد تمرير فعلي) — لا نُطلق تحميلًا تلقائيًا.
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent - 300) {
      // حمّل من المزوّد الصحيح حسب القسم المعروض.
      if (widget.categoryId == 0) {
        ref.read(latestNewsProvider.notifier).loadMore();
      } else {
        ref.read(categoryNewsProvider(widget.categoryId).notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = widget.categoryId == 0
        ? ref.watch(latestNewsProvider)
        : ref.watch(categoryNewsProvider(widget.categoryId));
    final bool hasMore = widget.categoryId == 0
        ? ref.read(latestNewsProvider.notifier).hasMore
        : ref.read(categoryNewsProvider(widget.categoryId).notifier).hasMore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'آخر الأخبار',
          icon: Icons.fiber_new_rounded,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        newsAsync.when(
          loading: () => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
            itemBuilder: (_, __) => const NewsCardSkeleton(),
          ),
          error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => widget.categoryId == 0
                ? ref.read(latestNewsProvider.notifier).loadInitial()
                : ref.read(categoryNewsProvider(widget.categoryId).notifier).loadInitial(),
          ),
          data: (articles) {
            if (articles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'لا توجد أخبار في هذا القسم',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: articles.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
              itemBuilder: (context, index) {
                if (index == articles.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                // العنصر الأول يُعرض كبطاقة مميّزة بارزة.
                if (index == 0) {
                  return NewsCardFeatured(article: articles[index]);
                }
                return NewsCardHorizontal(article: articles[index]);
              },
            );
          },
        ),
      ],
    );
  }
}
