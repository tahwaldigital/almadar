import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/app_logo.dart';

/// تُعرض عندما يكون إصدار التطبيق أقدم من الحد الأدنى الذي يفرضه الخادم.
/// شاشة حاجبة بلا رجوع — المستخدم يجب أن يُحدّث للمتابعة.
class ForceUpdateScreen extends StatelessWidget {
  final String storeUrl;
  final String message;

  const ForceUpdateScreen({
    super.key,
    this.storeUrl = '',
    this.message = '',
  });

  Future<void> _openStore(BuildContext context) async {
    if (storeUrl.trim().isEmpty) return;
    try {
      final ok = await launchUrl(
        Uri.parse(storeUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح المتجر')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح المتجر')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = message.trim().isNotEmpty
        ? message.trim()
        : 'صدر إصدار جديد من التطبيق بمزايا وتحسينات مهمة.\nيرجى التحديث للمتابعة.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(height: 48),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.system_update_rounded,
                        size: 68, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    'يتوفّر تحديث جديد',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.secondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  if (storeUrl.trim().isNotEmpty)
                    SizedBox(
                      width: 220,
                      child: FilledButton.icon(
                        onPressed: () => _openStore(context),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('تحديث الآن'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
