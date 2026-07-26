import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/app_status_provider.dart';
import '../../widgets/app_logo.dart';

/// شاشة تُعرض عندما يكون التطبيق غير متصل بالموقع أو في وضع التحديث.
class MaintenanceScreen extends StatelessWidget {
  final AppStatus status;
  final bool isRechecking;
  final Future<void> Function() onRetry;

  /// رسالة مخصّصة من لوحة تحكم الموقع (اختيارية).
  final String message;

  const MaintenanceScreen({
    super.key,
    required this.status,
    required this.isRechecking,
    required this.onRetry,
    this.message = '',
  });

  bool get _isOffline => status == AppStatus.offline;

  String get _title =>
      _isOffline ? 'لا يوجد اتصال بالإنترنت' : 'التطبيق جاري تحديثه';

  String get _message {
    // رسالة المشرف من الخادم تسبق النص الافتراضي.
    if (message.trim().isNotEmpty) return message.trim();
    return _isOffline
        ? 'تحقّق من اتصالك بالإنترنت ثم أعد المحاولة.'
        : 'نعمل حاليًا على تحديث التطبيق لتقديم تجربة أفضل.\nيرجى المحاولة بعد قليل.';
  }

  IconData get _icon =>
      _isOffline ? Icons.wifi_off_rounded : Icons.build_circle_outlined;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                  child: Icon(_icon, size: 68, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.secondary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                SizedBox(
                  width: 200,
                  child: FilledButton.icon(
                    onPressed: isRechecking ? null : onRetry,
                    icon: isRechecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(isRechecking ? 'جارٍ المحاولة...' : 'إعادة المحاولة'),
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
    );
  }
}
