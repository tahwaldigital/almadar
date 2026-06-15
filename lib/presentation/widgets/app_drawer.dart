import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../providers/auth_providers.dart';
import 'app_logo.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isLoggedIn = auth.status == AuthStatus.authenticated && auth.user != null;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(height: 40),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isLoggedIn ? auth.user!.name : 'تسجيل الدخول',
                            style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_left, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _item(context, Icons.home_outlined, 'الرئيسية', '/home', go: true),
                  _item(context, Icons.grid_view_outlined, 'الأقسام', '/categories', go: true),
                  _item(context, Icons.smart_display_outlined, 'فيديوهات', '/videos'),
                  _item(context, Icons.local_fire_department_outlined, 'الأكثر مشاهدة', '/most-viewed'),
                  _item(context, Icons.bookmark_outline, 'المحفوظات', '/bookmarks', go: true),
                  _item(context, Icons.notifications_outlined, 'الإشعارات', '/notifications'),
                  _item(context, Icons.person_outline, 'حسابي', '/profile'),
                  const Divider(),
                  _item(context, Icons.settings_outlined, 'الإعدادات', '/settings', go: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String route,
      {bool go = false}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTypography.bodyMd),
      onTap: () {
        Navigator.pop(context);
        if (go) {
          context.go(route);
        } else {
          context.push(route);
        }
      },
    );
  }
}
