import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'app_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
