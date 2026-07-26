import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/legal_content.dart';

/// يعرض صفحة تعريفية/قانونية مضمّنة داخل التطبيق (من نحن، الخصوصية، الشروط،
/// السياسة التحريرية، سياسة التصحيح) اعتمادًا على [LegalContent].
///
/// المحتوى محلّي بالكامل فلا يظهر أي "صفحة فارغة" حتى بدون اتصال بالإنترنت.
class InfoPageScreen extends StatelessWidget {
  final String pageKey;

  const InfoPageScreen({super.key, required this.pageKey});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = LegalContent.byKey(pageKey);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: Text(page?.title ?? 'صفحة'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: page == null
          ? const Center(child: Text('المحتوى غير متوفر'))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.gutter,
                horizontal: ((MediaQuery.of(context).size.width - 700) / 2)
                    .clamp(AppSpacing.gutter, double.infinity),
              ),
              child: HtmlWidget(
                page.html,
                textStyle: TextStyle(
                  fontFamily: AppTypography.workSans,
                  fontSize: 17,
                  height: 1.9,
                  color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                ),
              ),
            ),
    );
  }
}
