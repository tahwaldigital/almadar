import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../providers/config_providers.dart';

/// قسم "تابعنا على مواقع التواصل الاجتماعي" — يظهر في صفحة المقال بأيقونات
/// المنصات التي ضبط المشرف روابطها من لوحة التحكم. يختفي كليًا إن لم تُضبط أي.
class SocialFollowSection extends ConsumerWidget {
  const SocialFollowSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(socialLinksProvider);
    return async.maybeWhen(
      data: (social) {
        final channels = _channels(social);
        if (channels.isEmpty) return const SizedBox.shrink();
        return _Section(channels: channels);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  /// يبني قائمة القنوات المتاحة (ذات الروابط غير الفارغة) من إعدادات الموقع.
  List<_Channel> _channels(Map<String, String> s) {
    // يضمن وجود سكيم — رابط مثل "facebook.com/x" بدون https لن يُفتح.
    String url(String key) {
      final v = (s[key] ?? '').trim();
      if (v.isEmpty) return '';
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
      return 'https://$v';
    }

    // واتساب قد يُضبط كرقم أو كرابط wa.me — نطبّعه إلى رابط قابل للفتح.
    String whatsapp() {
      final raw = (s['whatsapp'] ?? '').trim();
      if (raw.isEmpty) return '';
      if (raw.startsWith('http')) return raw;
      // أرقام فقط، مع إزالة بادئة 00 أو الأصفار (wa.me يريد الصيغة الدولية بلا + أو 00).
      final digits =
          raw.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
      return digits.length < 6 ? '' : 'https://wa.me/$digits';
    }

    final list = <_Channel>[
      _Channel('فيسبوك', FontAwesomeIcons.facebookF, const Color(0xFF1877F2), url('facebook')),
      _Channel('إكس', FontAwesomeIcons.xTwitter, const Color(0xFF000000), url('twitter'), dark: true),
      _Channel('إنستغرام', FontAwesomeIcons.instagram, const Color(0xFFE4405F), url('instagram')),
      _Channel('سناب شات', FontAwesomeIcons.snapchat, const Color(0xFFFFC800), url('snapchat'), lightBg: true),
      _Channel('واتساب', FontAwesomeIcons.whatsapp, const Color(0xFF25D366), whatsapp()),
      _Channel('تليجرام', FontAwesomeIcons.telegram, const Color(0xFF229ED9), url('telegram')),
      _Channel('يوتيوب', FontAwesomeIcons.youtube, const Color(0xFFFF0000), url('youtube')),
      _Channel('تيك توك', FontAwesomeIcons.tiktok, const Color(0xFF000000), url('tiktok'), dark: true),
    ];
    return list.where((c) => c.url.isNotEmpty).toList();
  }
}

class _Channel {
  final String name;
  final IconData icon;
  final Color color;
  final String url;

  /// علامة داكنة (إكس/تيك توك) — تحتاج حدًّا في الوضع الليلي.
  final bool dark;

  /// خلفية فاتحة (سناب شات) — نستخدم أيقونة داكنة.
  final bool lightBg;

  const _Channel(this.name, this.icon, this.color, this.url,
      {this.dark = false, this.lightBg = false});
}

class _Section extends StatelessWidget {
  final List<_Channel> channels;
  const _Section({required this.channels});

  Future<void> _launch(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر فتح الرابط')));
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.06)
            : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'تابعنا على مواقع التواصل الاجتماعي',
            textAlign: TextAlign.center,
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final c in channels)
                _IconButton(
                  channel: c,
                  isDark: isDark,
                  onTap: () => _launch(context, c.url),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final _Channel channel;
  final bool isDark;
  final VoidCallback onTap;

  const _IconButton({
    required this.channel,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: channel.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: channel.color,
            shape: BoxShape.circle,
            border: isDark && channel.dark
                ? Border.all(color: Colors.white24, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: FaIcon(
            channel.icon,
            size: 21,
            color: channel.lightBg ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}
