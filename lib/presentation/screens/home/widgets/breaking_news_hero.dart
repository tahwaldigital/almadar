import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/article.dart';
import '../../../providers/news_providers.dart';
import '../../../widgets/skeleton_loader.dart';

/// سلايدر علوي يتقدّم تلقائياً: يعرض الأخبار العاجلة، وإن لم توجد يعرض أحدث المقالات.
class BreakingNewsHero extends ConsumerStatefulWidget {
  const BreakingNewsHero({super.key});

  @override
  ConsumerState<BreakingNewsHero> createState() => _BreakingNewsHeroState();
}

class _BreakingNewsHeroState extends ConsumerState<BreakingNewsHero> {
  final _pageController = PageController();
  Timer? _timer;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients || _count <= 1) return;
      final cur = (_pageController.page ?? 0).round();
      final next = (cur + 1) % _count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breaking = ref.watch(breakingNewsProvider);
    final latest = ref.watch(latestNewsProvider).value ?? const <Article>[];

    final articles = breaking.maybeWhen(
      data: (b) => b.isNotEmpty ? b : latest.take(6).toList(),
      orElse: () => latest.take(6).toList(),
    );

    if (articles.isEmpty) {
      // أثناء أول تحميل نعرض هيكلاً، وإن لم يصل شيء نخفي القسم بدل أيقونة فارغة.
      return (breaking.isLoading || latest.isEmpty)
          ? const HeroSkeleton()
          : const SizedBox.shrink();
    }

    _count = articles.length;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: articles.length,
            itemBuilder: (context, index) => _HeroCard(article: articles[index]),
          ),
        ),
        if (articles.length > 1) ...[
          const SizedBox(height: 10),
          SmoothPageIndicator(
            controller: _pageController,
            count: articles.length,
            effect: const ExpandingDotsEffect(
              activeDotColor: AppColors.primaryContainer,
              dotColor: AppColors.surfaceContainerHigh,
              dotHeight: 6,
              dotWidth: 6,
              expansionFactor: 3,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Article article;
  const _HeroCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/article/${article.id}', extra: article),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: article.featuredImageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surfaceContainerHigh,
                child: const Icon(Icons.image_outlined, size: 48, color: AppColors.secondary),
              ),
            ),
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.82)],
                  stops: const [0.28, 1.0],
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 16,
              right: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شارة: «عاجل» إن كان عاجلاً، وإلا اسم القسم.
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
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: AppTypography.headlineLgMobile.copyWith(
                      color: Colors.white,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}
