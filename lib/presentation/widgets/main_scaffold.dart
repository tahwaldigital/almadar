import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../providers/news_providers.dart';
import '../providers/read_providers.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'الرئيسية', path: '/home'),
    _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'الأقسام', path: '/categories'),
    _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'بحث', path: '/search'),
    _NavItem(icon: Icons.bookmark_outline, activeIcon: Icons.bookmark, label: 'المحفوظات', path: '/bookmarks'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'الإعدادات', path: '/settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  Widget _icon(IconData icon, int count, Color color) {
    final ic = Icon(icon, color: color);
    if (count <= 0) return ic;
    return Badge.count(count: count, child: ic);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // عدد الأخبار غير المقروءة في آخر الأخبار (يظهر كشارة على تبويب الرئيسية).
    final latest = ref.watch(latestNewsProvider).value ?? const [];
    final read = ref.watch(readArticlesProvider);
    final unread = latest.where((a) => !read.contains(a.id)).length;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: _icon(_tabs[i].icon, i == 0 ? unread : 0, AppColors.secondary),
              selectedIcon: _icon(_tabs[i].activeIcon, i == 0 ? unread : 0, AppColors.primary),
              label: _tabs[i].label,
              tooltip: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
