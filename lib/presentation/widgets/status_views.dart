import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/errors/exceptions.dart';

/// حالة فارغة موحّدة: أيقونة دائرية + عنوان + وصف + زر إجراء اختياري.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.dark
        ? AppColors.inverseOnSurface
        : AppColors.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineMd.copyWith(color: ink),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.base),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.stackLg),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// حالة خطأ موحّدة: أيقونة + رسالة ودّية + زر إعادة محاولة.
/// لا تعرض أبداً رسائل تقنية خام للمستخدم.
class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData? icon;

  /// كائن الاستثناء (اختياري) — يُستخدم لتمييز انقطاع الإنترنت تلقائياً.
  final Object? error;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.icon,
    this.error,
  });

  bool get _isOffline => error is NetworkException;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.dark
        ? AppColors.inverseOnSurface
        : AppColors.onSurface;
    final effectiveIcon = icon ?? (_isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded);
    final title = _isOffline ? 'لا يوجد اتصال بالإنترنت' : 'تعذّر تحميل المحتوى';
    final desc = message ??
        (_isOffline
            ? 'تحقّق من اتصالك بالشبكة ثم أعد المحاولة.'
            : 'حدث خطأ غير متوقع، حاول مرة أخرى.');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(effectiveIcon, size: 40, color: AppColors.error.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineMd.copyWith(color: ink),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.stackLg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
