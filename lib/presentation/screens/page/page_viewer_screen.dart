import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/content_providers.dart';
import '../../widgets/status_views.dart';

class PageViewerScreen extends ConsumerWidget {
  final int pageId;
  final String title;

  const PageViewerScreen({super.key, required this.pageId, this.title = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageAsync = ref.watch(pageProvider(pageId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: Text(title.isNotEmpty ? title : 'صفحة'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: pageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(pageProvider(pageId)),
        ),
        data: (page) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.gutter,
            horizontal: ((MediaQuery.of(context).size.width - 700) / 2)
                .clamp(AppSpacing.gutter, double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(page.title, style: AppTypography.headlineLgMobile),
              const SizedBox(height: AppSpacing.stackLg),
              HtmlWidget(
                page.content,
                textStyle: TextStyle(
                  fontFamily: AppTypography.workSans,
                  fontSize: 17,
                  height: 1.9,
                  color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
