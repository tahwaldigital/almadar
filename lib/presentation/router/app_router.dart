import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/category.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/author/author_screen.dart';
import '../screens/bookmarks/bookmarks_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/category/category_screen.dart';
import '../screens/comments/comments_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/most_viewed/most_viewed_screen.dart';
import '../screens/news_detail/news_detail_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/page/page_viewer_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/videos/videos_screen.dart';
import '../widgets/main_scaffold.dart';

/// Global navigator key so push notifications can deep-link into the app.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// انتقال صفحة موحّد: تلاشٍ + انزلاق رأسي خفيف (محايد الاتجاه — آمن لـ RTL).
CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _page(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _page(state, const RegisterScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/bookmarks',
            name: 'bookmarks',
            builder: (context, state) => const BookmarksScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/article/:id',
        name: 'article',
        pageBuilder: (context, state) {
          final article = state.extra as Article?;
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return _page(state, NewsDetailScreen(article: article, articleId: id));
        },
      ),
      GoRoute(
        path: '/category/:id',
        name: 'category',
        pageBuilder: (context, state) {
          final category = state.extra as Category?;
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return _page(state, CategoryScreen(category: category, categoryId: id));
        },
      ),
      GoRoute(
        path: '/comments/:id',
        name: 'comments',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final title = state.extra as String? ?? '';
          return _page(state, CommentsScreen(postId: id, postTitle: title));
        },
      ),
      GoRoute(
        path: '/author/:id',
        name: 'author',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final name = state.extra as String? ?? '';
          return _page(state, AuthorScreen(authorId: id, authorName: name));
        },
      ),
      GoRoute(
        path: '/page/:id',
        name: 'page',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final title = state.extra as String? ?? '';
          return _page(state, PageViewerScreen(pageId: id, title: title));
        },
      ),
      GoRoute(
        path: '/videos',
        name: 'videos',
        pageBuilder: (context, state) => _page(state, const VideosScreen()),
      ),
      GoRoute(
        path: '/most-viewed',
        name: 'most-viewed',
        pageBuilder: (context, state) => _page(state, const MostViewedScreen()),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => _page(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _page(state, const ProfileScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('الصفحة غير موجودة: ${state.error}'),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});
