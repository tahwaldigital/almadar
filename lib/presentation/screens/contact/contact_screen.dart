import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/contact_info.dart';

/// شاشة "اتصل بنا": تعرض وسائل التواصل الرسمية (بريد، هاتف، واتساب، موقع،
/// وسائل تواصل اجتماعي) بشكل قابل للنقر. الصفوف ذات القيم الفارغة تُخفى.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر فتح التطبيق المناسب')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر إتمام العملية')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rows = <Widget>[
      if (ContactInfo.email.isNotEmpty)
        _ContactTile(
          icon: Icons.email_outlined,
          label: 'البريد الإلكتروني',
          value: ContactInfo.email,
          onTap: () => _launch(context, Uri(scheme: 'mailto', path: ContactInfo.email)),
        ),
      if (ContactInfo.phone.isNotEmpty)
        _ContactTile(
          icon: Icons.phone_outlined,
          label: 'الهاتف',
          value: ContactInfo.phone,
          onTap: () => _launch(context, Uri(scheme: 'tel', path: ContactInfo.phone)),
        ),
      if (ContactInfo.whatsapp.isNotEmpty)
        _ContactTile(
          icon: Icons.chat_outlined,
          label: 'واتساب',
          value: ContactInfo.whatsapp,
          onTap: () => _launch(context, Uri.parse('https://wa.me/${ContactInfo.whatsapp}')),
        ),
      if (ContactInfo.website.isNotEmpty)
        _ContactTile(
          icon: Icons.language_outlined,
          label: 'الموقع الإلكتروني',
          value: ContactInfo.website,
          onTap: () => _launch(context, Uri.parse(ContactInfo.website)),
        ),
      if (ContactInfo.address.isNotEmpty)
        _ContactTile(
          icon: Icons.location_on_outlined,
          label: 'العنوان',
          value: ContactInfo.address,
          onTap: null,
        ),
    ];

    final socials = <Widget>[
      if (ContactInfo.facebook.isNotEmpty)
        _SocialButton(icon: Icons.facebook, onTap: () => _launch(context, Uri.parse(ContactInfo.facebook))),
      if (ContactInfo.x.isNotEmpty)
        _SocialButton(icon: Icons.alternate_email, onTap: () => _launch(context, Uri.parse(ContactInfo.x))),
      if (ContactInfo.instagram.isNotEmpty)
        _SocialButton(icon: Icons.camera_alt_outlined, onTap: () => _launch(context, Uri.parse(ContactInfo.instagram))),
      if (ContactInfo.youtube.isNotEmpty)
        _SocialButton(icon: Icons.smart_display_outlined, onTap: () => _launch(context, Uri.parse(ContactInfo.youtube))),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: const Text('اتصل بنا'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin, 8, AppSpacing.containerMargin, 8),
            child: Text(
              ContactInfo.publisher,
              style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.containerMargin, 0, AppSpacing.containerMargin, 12),
            child: Text(
              'يسعدنا تواصلك معنا عبر أي من الوسائل التالية:',
              style: TextStyle(color: AppColors.secondary, height: 1.6),
            ),
          ),
          ...rows,
          if (socials.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            Center(
              child: Wrap(spacing: 12, children: socials),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.secondary)),
      subtitle: Text(
        value,
        style: AppTypography.bodyMd,
        textDirection: TextDirection.ltr,
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.secondary),
      onTap: onTap,
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.primary),
    );
  }
}
