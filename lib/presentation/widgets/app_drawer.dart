import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/legal_content.dart';
import '../../core/utils/share_utils.dart';
import '../providers/admin_providers.dart';
import 'app_logo.dart';
import 'developer_credit.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
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
                  if (isAdmin) ...[
                    const Divider(),
                    _item(context, Icons.dashboard_customize_outlined,
                        'لوحة التحرير', '/admin'),
                  ],
                  const Divider(),
                  _item(context, Icons.share_outlined, 'وسائل التواصل', '/social'),
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
                    title: Text('مشاركة التطبيق', style: AppTypography.bodyMd),
                    onTap: () {
                      Navigator.pop(context);
                      ShareUtils.shareApp();
                    },
                  ),
                  const Divider(),
                  _item(context, Icons.info_outline_rounded, 'من نحن', '/info/${LegalContent.keyAbout}'),
                  _item(context, Icons.mail_outline_rounded, 'اتصل بنا', '/contact'),
                  _item(context, Icons.privacy_tip_outlined, 'سياسة الخصوصية', '/info/${LegalContent.keyPrivacy}'),
                  _item(context, Icons.description_outlined, 'الشروط والأحكام', '/info/${LegalContent.keyTerms}'),
                  _item(context, Icons.gavel_rounded, 'السياسة التحريرية', '/info/${LegalContent.keyEditorial}'),
                  _item(context, Icons.fact_check_outlined, 'سياسة التصحيح', '/info/${LegalContent.keyCorrection}'),
                ],
              ),
            ),
            // حقوق البرمجة في تذييل القائمة.
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: DeveloperCredit()),
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
