import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/auth_providers.dart';
import '../../providers/content_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/theme_providers.dart';
import '../../widgets/app_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.status == AuthStatus.authenticated;
    final notifPrefs = ref.watch(notificationPrefsProvider);

    Future<void> openConfigPage(String key, String title) async {
      try {
        final config = await ref.read(appConfigProvider.future);
        final pages = config['pages'] as Map<String, dynamic>?;
        final page = pages?[key] as Map<String, dynamic>?;
        final pageId = page?['page_id'] as int? ?? 0;
        if (!context.mounted) return;
        if (pageId > 0) {
          context.push('/page/$pageId', extra: title);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('الصفحة غير متوفرة حالياً')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('تعذّر فتح الصفحة')));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: AppTypography.headlineLgMobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Profile Section
          _SectionHeader(title: isLoggedIn ? 'حسابي' : 'تسجيل الدخول'),
          if (isLoggedIn) ...[
            InkWell(
              onTap: () => context.push('/profile'),
              child: _ProfileTile(
                name: authState.user?.name ?? '',
                email: authState.user?.email ?? '',
              ),
            ),
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'تسجيل الخروج',
              color: AppColors.error,
              onTap: () async {
                final confirmed = await _showLogoutDialog(context);
                if (confirmed == true) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
            ),
          ] else ...[
            _SettingsTile(
              icon: Icons.login_rounded,
              label: 'تسجيل الدخول',
              onTap: () => context.push('/login'),
            ),
            _SettingsTile(
              icon: Icons.person_add_outlined,
              label: 'إنشاء حساب',
              onTap: () => context.push('/register'),
            ),
          ],

          const _SectionHeader(title: 'المظهر'),
          _SwitchTile(
            icon: Icons.dark_mode_outlined,
            label: 'الوضع الليلي',
            value: isDark,
            onChanged: (v) => ref.read(isDarkModeProvider.notifier).setDark(v),
          ),

          const _SectionHeader(title: 'الإشعارات'),
          _SwitchTile(
            icon: Icons.notifications_outlined,
            label: 'إشعارات الأخبار العاجلة',
            value: notifPrefs.breaking,
            onChanged: (v) => ref.read(notificationPrefsProvider.notifier).setBreaking(v),
          ),
          _SwitchTile(
            icon: Icons.campaign_outlined,
            label: 'إشعارات الأخبار العامة',
            value: notifPrefs.daily,
            onChanged: (v) => ref.read(notificationPrefsProvider.notifier).setDaily(v),
          ),

          const _SectionHeader(title: 'عام'),
          _SettingsTile(
            icon: Icons.language_outlined,
            label: 'اللغة',
            trailing: Text('العربية', style: AppTypography.labelMd.copyWith(color: AppColors.secondary)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('التطبيق متاح بالعربية حالياً')),
            ),
          ),
          _SettingsTile(
            icon: Icons.text_fields_rounded,
            label: 'حجم الخط',
            onTap: () => _showFontSizeSheet(context, ref),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'عن التطبيق',
            onTap: () => openConfigPage('about', 'عن التطبيق'),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'سياسة الخصوصية',
            onTap: () => openConfigPage('privacy_policy', 'سياسة الخصوصية'),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Center(
            child: Column(
              children: [
                const AppLogo(height: 28),
                const SizedBox(height: 8),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) {
                    final v = snap.hasData ? snap.data!.version : '';
                    return Text(
                      v.isEmpty ? '' : 'الإصدار $v',
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showFontSizeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, r, _) {
          final scale = r.watch(fontScaleProvider);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('حجم الخط', style: AppTypography.headlineMd),
                const SizedBox(height: 8),
                Text(
                  'نموذج لحجم النص',
                  style: AppTypography.bodyMd.copyWith(fontSize: 16 * scale),
                ),
                Slider(
                  value: scale,
                  min: 0.85,
                  max: 1.4,
                  divisions: 11,
                  label: '${(scale * 100).round()}%',
                  activeColor: AppColors.primaryContainer,
                  onChanged: (v) => r.read(fontScaleProvider.notifier).set(v),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تسجيل الخروج', style: AppTypography.headlineMd),
          content: Text(
            'هل تريد تسجيل الخروج من حسابك؟',
            style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('خروج'),
            ),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackLg,
        AppSpacing.containerMargin,
        AppSpacing.stackSm,
      ),
      child: Text(
        title,
        style: AppTypography.labelMd.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.secondary, size: 22),
      title: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: color ?? (isDark ? AppColors.inverseOnSurface : AppColors.onSurface),
        ),
      ),
      trailing: trailing ?? Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.secondary.withValues(alpha: 0.5)),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(label, style: AppTypography.bodyMd),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryContainer,
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileTile({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'م',
                style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primaryContainer),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
              Text(email, style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}
