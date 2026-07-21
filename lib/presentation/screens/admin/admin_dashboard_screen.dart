import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/admin_providers.dart';
import '../../providers/auth_providers.dart';

/// لوحة التحرير: نقطة دخول المشرف لكتابة الأخبار ونشرها. متاحة فقط
/// للمستخدمين الذين يملكون صلاحية النشر (administrator / editor / author).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = ref.watch(isAdminProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة التحرير'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: isAdmin
          ? _AdminBody(userName: user?.name ?? '')
          : const _NotAuthorized(),
    );
  }
}

class _AdminBody extends StatelessWidget {
  final String userName;
  const _AdminBody({required this.userName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      children: [
        Text(
          userName.isEmpty ? 'مرحبًا بك' : 'مرحبًا $userName',
          style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        const Text(
          'اكتب الأخبار وانشرها مباشرة إلى الموقع، وأرسل التنبيهات العاجلة للمشتركين.',
          style: TextStyle(color: AppColors.secondary, height: 1.6),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        _ActionCard(
          icon: Icons.edit_note_rounded,
          title: 'كتابة خبر جديد',
          subtitle: 'أنشئ خبرًا وانشره إلى الموقع فورًا',
          color: AppColors.primary,
          onTap: () => context.push('/admin/compose'),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.priority_high_rounded,
          title: 'خبر عاجل',
          subtitle: 'اكتب خبرًا وفعّل خيار "عاجل" لإرسال إشعار لكل المشتركين',
          color: const Color(0xFFD32F2F),
          onTap: () => context.push('/admin/compose'),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surface.withValues(alpha: 0.06) : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.secondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_rounded,
                  size: 14, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotAuthorized extends StatelessWidget {
  const _NotAuthorized();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.secondary),
            SizedBox(height: 16),
            Text(
              'غير مصرّح لك بالدخول',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'لوحة التحرير متاحة لمحرري الصحيفة فقط. سجّل الدخول بحساب لديه صلاحية النشر.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
