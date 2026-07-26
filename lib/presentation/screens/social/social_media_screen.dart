import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/contact_info.dart';
import '../../../core/utils/share_utils.dart';
import '../../providers/config_providers.dart';

/// شاشة "وسائل التواصل": تعرض حسابات الصحيفة الرسمية بأيقونات كل منصة ولونها،
/// مع زر لمشاركة التطبيق. الروابط تُقرأ من لوحة تحكم الموقع (قسم Social links)
/// فتتغيّر مباشرة دون تحديث التطبيق. القنوات غير المُعرّفة تُخفى.
class SocialMediaScreen extends ConsumerWidget {
  const SocialMediaScreen({super.key});

  Future<void> _launch(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر إتمام العملية')),
        );
      }
    }
  }

  /// يبني قائمة القنوات المتاحة من روابط لوحة التحكم (مع تطبيع الروابط).
  List<_SocialChannel> _channels(Map<String, String> s) {
    String url(String key) {
      final v = (s[key] ?? '').trim();
      if (v.isEmpty) return '';
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
      return 'https://$v';
    }

    String whatsapp() {
      final raw = (s['whatsapp'] ?? '').trim();
      if (raw.isEmpty) return '';
      if (raw.startsWith('http')) return raw;
      final digits =
          raw.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
      return digits.length < 6 ? '' : 'https://wa.me/$digits';
    }

    return <_SocialChannel>[
      _SocialChannel('إنستغرام', FontAwesomeIcons.instagram,
          const Color(0xFFE4405F), url('instagram')),
      _SocialChannel('إكس (تويتر)', FontAwesomeIcons.xTwitter,
          const Color(0xFF000000), url('twitter')),
      _SocialChannel('سناب شات', FontAwesomeIcons.snapchat,
          const Color(0xFFFFC800), url('snapchat'), dark: true),
      _SocialChannel('تليجرام', FontAwesomeIcons.telegram,
          const Color(0xFF229ED9), url('telegram')),
      _SocialChannel('واتساب', FontAwesomeIcons.whatsapp,
          const Color(0xFF25D366), whatsapp()),
      _SocialChannel('فيسبوك', FontAwesomeIcons.facebookF,
          const Color(0xFF1877F2), url('facebook')),
      _SocialChannel('يوتيوب', FontAwesomeIcons.youtube,
          const Color(0xFFFF0000), url('youtube')),
      _SocialChannel('تيك توك', FontAwesomeIcons.tiktok,
          const Color(0xFF000000), url('tiktok')),
    ].where((c) => c.url.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final socialAsync = ref.watch(socialLinksProvider);
    final isLoading = socialAsync.isLoading && !socialAsync.hasValue;
    final channels = _channels(socialAsync.valueOrNull ?? const {});

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: const Text('وسائل التواصل'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(socialLinksProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.gutter,
          ),
          children: [
            Text(
              ContactInfo.publisher,
              style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            const Text(
              'تابعنا على منصاتنا الرسمية لتصلك آخر الأخبار والتغطيات الحصرية:',
              style: TextStyle(color: AppColors.secondary, height: 1.6),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (channels.isEmpty)
              _EmptyChannels(isDark: isDark)
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
                children: [
                  for (final c in channels)
                    _SocialCard(
                      channel: c,
                      isDark: isDark,
                      onTap: () => _launch(context, c.url),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.sectionGap),
            const Divider(),
            const SizedBox(height: AppSpacing.gutter),
            FilledButton.icon(
              onPressed: () => ShareUtils.shareApp(),
              icon: const Icon(Icons.share_rounded, size: 20),
              label: const Text('مشاركة التطبيق'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SocialChannel {
  final String name;
  final IconData icon;
  final Color color;
  final String url;

  /// عندما تكون خلفية العلامة فاتحة (مثل سناب شات) نستخدم أيقونة داكنة.
  final bool dark;

  const _SocialChannel(this.name, this.icon, this.color, this.url,
      {this.dark = false});
}

class _SocialCard extends StatelessWidget {
  final _SocialChannel channel;
  final bool isDark;
  final VoidCallback onTap;

  const _SocialCard({
    required this.channel,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.surface.withValues(alpha: 0.06) : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: channel.color,
                  shape: BoxShape.circle,
                  // العلامات السوداء (إكس/تيك توك) تكاد تختفي على الخلفية
                  // الداكنة، فنضيف حدًّا فاتحًا يفصلها عن الخلفية.
                  border: isDark && channel.color.computeLuminance() < 0.06
                      ? Border.all(color: Colors.white24, width: 1)
                      : null,
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  channel.icon,
                  size: 20,
                  color: channel.dark ? Colors.black87 : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  channel.name,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.inverseOnSurface
                        : AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChannels extends StatelessWidget {
  final bool isDark;
  const _EmptyChannels({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface.withValues(alpha: 0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.public_off_rounded, size: 40, color: AppColors.secondary),
          SizedBox(height: 12),
          Text(
            'حساباتنا على مواقع التواصل قريبًا',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'تابعنا حاليًا عبر الموقع، ويمكنك مشاركة التطبيق مع أصدقائك من الزر أدناه.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
