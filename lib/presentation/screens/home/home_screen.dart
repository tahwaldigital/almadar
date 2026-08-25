import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/news_providers.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_logo.dart';
import 'widgets/breaking_news_hero.dart';
import 'widgets/breaking_ticker.dart';
import 'widgets/category_tabs.dart';
import 'widgets/latest_news_section.dart';
import 'widgets/trending_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedCategoryId = 0;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند العودة للتطبيق نحدّث الأخبار تلقائيًا، مع كبح 30 ثانية لتفادي
    // إعادة الجلب المتكرر عند التبديل السريع بين التطبيقات.
    if (state == AppLifecycleState.resumed &&
        DateTime.now().difference(_lastRefresh).inSeconds >= 30) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    _lastRefresh = DateTime.now();
    await ref.read(latestNewsProvider.notifier).loadInitial();
    if (!mounted) return;
    ref.invalidate(breakingNewsProvider);
    ref.invalidate(trendingNewsProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 64,
            flexibleSpace: ClipRect(
              child: Container(
                color: isDark ? AppColors.surfaceDark : AppColors.background,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          icon: const Icon(Icons.menu_rounded),
                          color: AppColors.primary,
                        ),
                        // Brand logo
                        const AppLogo(height: 34),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: AppColors.primaryContainer,
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              // شريط الأخبار العاجلة المتحرك (تحت الهيدر، عرض كامل)
              const SliverToBoxAdapter(child: BreakingTicker()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerMargin,
                    vertical: AppSpacing.base,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.base),
                      // Breaking News Hero
                      const BreakingNewsHero(),
                      const SizedBox(height: AppSpacing.stackLg),
                      // Category Tabs - sticky
                      CategoryTabs(
                        onCategorySelected: (id) {
                          setState(() => _selectedCategoryId = id);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      // Trending Section
                      const TrendingSection(),
                      const SizedBox(height: AppSpacing.sectionGap),
                      // Latest News
                      LatestNewsSection(categoryId: _selectedCategoryId),
                      const SizedBox(height: AppSpacing.sectionGap),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
