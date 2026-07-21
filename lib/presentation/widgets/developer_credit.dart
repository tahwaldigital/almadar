import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// حقوق البرمجة والتطوير — يفتح موقع الشركة المطوّرة عند النقر.
class DeveloperCredit extends StatelessWidget {
  const DeveloperCredit({super.key});

  static const String developerName = 'تحول ديجيتال للابتكار الرقمي';
  static const String developerUrl = 'https://tahwal.com';

  Future<void> _open(BuildContext context) async {
    try {
      final ok = await launchUrl(
        Uri.parse(developerUrl),
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'تصميم وتطوير $developerName — فتح الموقع',
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // Text.rich بدل Row حتى يلتف الاسم الطويل على الشاشات الضيقة.
          child: Text.rich(
            TextSpan(
              children: [
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.code_rounded,
                        size: 14, color: AppColors.secondary),
                  ),
                ),
                TextSpan(
                  text: 'تصميم وتطوير ',
                  style:
                      AppTypography.labelSm.copyWith(color: AppColors.secondary),
                ),
                TextSpan(
                  text: developerName,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
