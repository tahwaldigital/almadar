import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/article.dart';
import '../../providers/news_providers.dart';
import '../../providers/providers.dart';
import '../../providers/read_providers.dart';
import '../../providers/theme_providers.dart';
import '../../widgets/article_video_player.dart';
import '../../widgets/news_card_horizontal.dart';
import '../../widgets/skeleton_loader.dart';

class NewsDetailScreen extends ConsumerStatefulWidget {
  final Article? article;
  final int articleId;

  const NewsDetailScreen({
    super.key,
    this.article,
    required this.articleId,
  });

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  bool _isSaved = false;
  double _fontSize = 17.0;

  // Reading progress (0..1) shown as a thin bar pinned to the top.
  final ScrollController _scroll = ScrollController();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _checkSaved();
    _registerView();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.004) setState(() => _progress = p);
  }

  void _registerView() {
    // Best-effort view counting; errors are swallowed inside the datasource.
    ref.read(newsRemoteDataSourceProvider).incrementView(widget.articleId);
    // علّم المقال كمقروء (لإخفاء مؤشّر «غير مقروء»).
    ref.read(readArticlesProvider.notifier).markRead(widget.articleId);
  }

  /// Keeps in-article links native: an internal post link (?p=ID) opens the
  /// article inside the app; anything else is ignored (no browser, no webview).
  void _handleInContentLink(String? url) {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final pid = uri.queryParameters['p'];
    if (pid != null && int.tryParse(pid) != null) {
      context.push('/article/$pid');
    }
  }

  Future<void> _checkSaved() async {
    if (widget.article != null) {
      final repo = ref.read(newsRepositoryProvider);
      final result = await repo.isArticleSaved(widget.article!.id);
      result.fold((_) {}, (saved) {
        if (mounted) setState(() => _isSaved = saved);
      });
    }
  }

  /// Rough Arabic reading time from the article HTML (~180 wpm).
  int _readingTimeMinutes(String html) {
    final text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final mins = (words / 180).ceil();
    return mins < 1 ? 1 : mins;
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ألف';
    return '$n';
  }

  void _openReadingSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void apply(double v) {
              final nv = v.clamp(14.0, 24.0);
              setSheet(() {});
              setState(() => _fontSize = nv);
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('حجم الخط', style: AppTypography.headlineMd),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _SizeButton(
                          label: 'أ−',
                          onTap: () => apply(_fontSize - 2),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'مقاس ${_fontSize.toInt()}',
                              style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        _SizeButton(
                          label: 'أ+',
                          onTap: () => apply(_fontSize + 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        'تظهر نصوص الأخبار بهذا الحجم. اضبطه حتى تصل لأنسب راحة للقراءة.',
                        style: TextStyle(
                          fontFamily: AppTypography.workSans,
                          fontSize: _fontSize,
                          height: 1.9,
                          color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The list passes a lightweight article (no body). Always fetch the full
    // article by id so we get content, video and gallery; use the passed
    // article as an instant placeholder while it loads.
    final fullAsync = ref.watch(articleByIdProvider(widget.articleId));
    final article = fullAsync.value ?? widget.article;

    if (article == null) {
      if (fullAsync.hasError) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_forward_ios_rounded),
            ),
          ),
          body: const Center(child: Text('تعذّر تحميل المقال')),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final relatedAsync = ref.watch(
      relatedPostsProvider((articleId: article.id, categoryId: article.categoryId)),
    );
    final bodyInk = isDark ? AppColors.inverseOnSurface : AppColors.onSurface;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              // Hero Image with AppBar
              SliverAppBar(
                expandedHeight: 320,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                leading: _CircleIconButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  label: 'رجوع',
                  onTap: () => context.pop(),
                ),
                actions: [
                  _CircleIconButton(
                    icon: Icons.ios_share_rounded,
                    label: 'مشاركة',
                    onTap: () => Share.share(article.link, subject: article.title),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'hero-article-${article.id}',
                        child: CachedNetworkImage(
                          imageUrl: article.featuredImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceContainerHigh,
                            child: const Icon(Icons.image_outlined, size: 64, color: AppColors.secondary),
                          ),
                        ),
                      ),
                      // Scrim for legibility (top + bottom).
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              (isDark ? AppColors.surfaceDark : AppColors.background),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                      // Category + breaking + time
                      Positioned(
                        bottom: 22,
                        right: AppSpacing.gutter,
                        left: AppSpacing.gutter,
                        child: Row(
                          children: [
                            if (article.isBreaking) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.breakingRed,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                                    const SizedBox(width: 3),
                                    Text('عاجل',
                                        style: AppTypography.labelSm.copyWith(
                                            color: Colors.white, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                article.categoryName,
                                style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onPrimary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Article Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ((MediaQuery.of(context).size.width - 700) / 2)
                        .clamp(AppSpacing.containerMargin, double.infinity),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.stackLg),
                      // Native video player (no webview) for video articles
                      if (article.hasVideo) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: ArticleVideoPlayer(
                            video: article.video!,
                            posterUrl: article.featuredImageUrl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                      ],
                      // Title
                      Text(
                        article.title,
                        style: AppTypography.headlineLgMobile.copyWith(
                          color: bodyInk,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      // Meta strip: reading time • views • comments
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetaItem(
                            icon: Icons.schedule_rounded,
                            label: AppDateUtils.timeAgo(article.datePublished),
                          ),
                          _MetaItem(
                            icon: Icons.menu_book_rounded,
                            label: 'قراءة ${_readingTimeMinutes(article.content)} د',
                          ),
                          if (article.viewCount > 0)
                            _MetaItem(
                              icon: Icons.visibility_outlined,
                              label: _formatCount(article.viewCount),
                            ),
                          if (article.commentCount > 0)
                            _MetaItem(
                              icon: Icons.forum_outlined,
                              label: _formatCount(article.commentCount),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.gutter),
                      // Author row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: AppColors.outlineVariant.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: article.authorId > 0
                                  ? () => context.push('/author/${article.authorId}',
                                      extra: article.authorName)
                                  : null,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: article.authorAvatarUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_outline, color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: article.authorId > 0
                                    ? () => context.push('/author/${article.authorId}',
                                        extra: article.authorName)
                                    : null,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.authorName.isNotEmpty ? article.authorName : 'محرر المدار',
                                      style: AppTypography.labelMd.copyWith(
                                        color: bodyInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'فريق تحرير المدار',
                                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Aa reading settings
                            _PillButton(
                              icon: Icons.text_fields_rounded,
                              label: 'الخط',
                              onTap: _openReadingSettings,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      // HTML Article Content (rendered as native Flutter widgets)
                      if (article.content.trim().isEmpty && fullAsync.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (article.content.trim().isEmpty && fullAsync.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('تعذّر تحميل محتوى الخبر'),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => ref.invalidate(
                                      articleByIdProvider(widget.articleId)),
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        HtmlWidget(
                          article.content,
                          textStyle: TextStyle(
                            fontFamily: AppTypography.workSans,
                            fontSize: _fontSize,
                            height: 1.95,
                            color: bodyInk,
                          ),
                          onTapUrl: (url) {
                            _handleInContentLink(url);
                            return true;
                          },
                          customStylesBuilder: (element) {
                            switch (element.localName) {
                              case 'p':
                                return {'text-align': 'start', 'margin': '0 0 18px'};
                              case 'h2':
                                return {
                                  'font-weight': '700',
                                  'font-size': '${_fontSize + 5}px',
                                  'margin': '24px 0 12px',
                                };
                              case 'h3':
                                return {
                                  'font-weight': '700',
                                  'font-size': '${_fontSize + 2}px',
                                  'margin': '20px 0 10px',
                                };
                              case 'a':
                                return {
                                  'color': '#F0640C',
                                  'text-decoration': 'none',
                                  'font-weight': '600',
                                };
                              case 'blockquote':
                                return {
                                  'font-style': 'italic',
                                  'padding': '4px 16px',
                                  'margin': '18px 0',
                                  'border-right': '4px solid #F0640C',
                                };
                              case 'img':
                                return {'margin': '8px 0'};
                              case 'figcaption':
                                return {
                                  'font-size': '13px',
                                  'text-align': 'center',
                                  'color': '#7A828C',
                                  'margin': '4px 0 12px',
                                };
                              default:
                                return null;
                            }
                          },
                        ),
                      const SizedBox(height: AppSpacing.stackLg),
                      // Tags
                      if (article.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: article.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                      ],
                      // Inline comments CTA
                      _CommentsCta(
                        count: article.commentCount,
                        onTap: () => context.push('/comments/${article.id}', extra: article.title),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      // Related Posts
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('أخبار ذات صلة', style: AppTypography.headlineMd.copyWith(color: bodyInk)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      relatedAsync.when(
                        loading: () => const NewsCardSkeleton(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (related) {
                          if (related.isEmpty) return const SizedBox.shrink();
                          return Column(
                            children: related
                                .take(4)
                                .map((a) => Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                                      child: NewsCardHorizontal(article: a),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Reading progress bar pinned just below the status bar.
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryContainer),
              ),
            ),
          ),
        ],
      ),
      // Bottom Action Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A1422) : AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.12)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomAction(
                  icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  label: 'حفظ',
                  color: _isSaved ? AppColors.primaryContainer : null,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final saved = await ref
                        .read(savedArticlesProvider.notifier)
                        .toggle(article);
                    setState(() => _isSaved = saved);
                  },
                ),
                _BottomAction(
                  icon: Icons.text_fields_rounded,
                  label: 'الخط',
                  onTap: _openReadingSettings,
                ),
                _BottomAction(
                  icon: Icons.forum_outlined,
                  label: 'تعليق',
                  badge: article.commentCount > 0 ? _formatCount(article.commentCount) : null,
                  onTap: () => context.push('/comments/${article.id}', extra: article.title),
                ),
                _BottomAction(
                  icon: Icons.ios_share_rounded,
                  label: 'مشاركة',
                  onTap: () => Share.share(article.link, subject: article.title),
                ),
                _BottomAction(
                  icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: 'المظهر',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(isDarkModeProvider.notifier).toggle();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted circular button used over the hero image.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const _CircleIconButton({required this.icon, required this.onTap, this.label = ''});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSm.copyWith(color: c)),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SizeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(label,
            style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
      ),
    );
  }
}

class _CommentsCta extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CommentsCta({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.forum_outlined, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count > 0 ? 'التعليقات ($count)' : 'كن أول من يعلّق',
                style: AppTypography.labelMd.copyWith(
                  color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badge;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.secondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 23, color: c),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(color: c),
            ),
          ],
        ),
      ),
    );
  }
}
