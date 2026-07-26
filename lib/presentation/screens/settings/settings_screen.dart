import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/legal_content.dart';
import '../../../core/utils/share_utils.dart';
import '../../providers/settings_providers.dart';
import '../../providers/theme_providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/developer_credit.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

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
          const _SectionHeader(title: 'المظهر'),
          _SwitchTile(
            icon: Icons.dark_mode_outlined,
            label: 'الوضع الليلي',
            value: isDark,
            onChanged: (v) => ref.read(isDarkModeProvider.notifier).setDark(v),
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

          const _SectionHeader(title: 'المعلومات'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'من نحن',
            onTap: () => context.push('/info/${LegalContent.keyAbout}'),
          ),
          _SettingsTile(
            icon: Icons.mail_outline_rounded,
            label: 'اتصل بنا',
            onTap: () => context.push('/contact'),
          ),

          const _SectionHeader(title: 'تواصل ومشاركة'),
          _SettingsTile(
            icon: Icons.share_outlined,
            label: 'وسائل التواصل',
            onTap: () => context.push('/social'),
          ),
          _SettingsTile(
            icon: Icons.ios_share_rounded,
            label: 'مشاركة التطبيق',
            onTap: () => ShareUtils.shareApp(),
          ),

          const _SectionHeader(title: 'السياسات القانونية'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'سياسة الخصوصية',
            onTap: () => context.push('/info/${LegalContent.keyPrivacy}'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'الشروط والأحكام',
            onTap: () => context.push('/info/${LegalContent.keyTerms}'),
          ),
          _SettingsTile(
            icon: Icons.gavel_rounded,
            label: 'السياسة التحريرية',
            onTap: () => context.push('/info/${LegalContent.keyEditorial}'),
          ),
          _SettingsTile(
            icon: Icons.fact_check_outlined,
            label: 'سياسة التصحيح',
            onTap: () => context.push('/info/${LegalContent.keyCorrection}'),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Center(
            child: Column(
              children: [
                // ضغطة مطوّلة على الشعار = دخول المحرّرين (مخفي عن القرّاء،
                // فتسجيل الدخول غير معروض لكن لوحة التحرير تظل متاحة للإدارة).
                GestureDetector(
                  onLongPress: () => context.push('/login'),
                  child: const AppLogo(height: 28),
                ),
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
                const SizedBox(height: 14),
                const DeveloperCredit(),
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
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
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

