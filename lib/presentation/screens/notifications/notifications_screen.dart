import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/notification_store.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/content_providers.dart';
import '../../widgets/status_views.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifsAsync = ref.watch(receivedNotificationsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'مسح الكل',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('مسح كل الإشعارات؟'),
                  content: const Text('لا يمكن التراجع عن هذا الإجراء.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await NotificationStore.clear();
                ref.invalidate(receivedNotificationsProvider);
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(receivedNotificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'لا توجد إشعارات بعد',
              message: 'ستصلك هنا آخر الأخبار العاجلة فور نشرها.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(receivedNotificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = items[i];
                final postId = n['post_id']?.toString();
                final time = n['time'] as String?;
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.notifications, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    (n['title'] ?? '').toString(),
                    style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((n['body'] ?? '').toString().isNotEmpty)
                        Text((n['body']).toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (time != null)
                        Text(
                          AppDateUtils.timeAgo(time),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.secondary.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                  onTap: (postId != null && int.tryParse(postId) != null)
                      ? () => context.push('/article/$postId')
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
