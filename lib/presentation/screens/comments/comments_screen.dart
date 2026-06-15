import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/html_parser_utils.dart';
import '../../providers/auth_providers.dart';
import '../../providers/content_providers.dart';
import '../../providers/providers.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  final int postId;
  final String postTitle;

  const CommentsScreen({super.key, required this.postId, this.postTitle = ''});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _contentController = TextEditingController();
  final _nameController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _contentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    final isLoggedIn = ref.read(authProvider).status == AuthStatus.authenticated;
    final name = _nameController.text.trim();

    if (content.length < 2) {
      _toast('اكتب تعليقاً صحيحاً');
      return;
    }
    if (!isLoggedIn && name.isEmpty) {
      _toast('اكتب اسمك');
      return;
    }

    setState(() => _sending = true);
    try {
      final res = await ref.read(contentRemoteDataSourceProvider).postComment(
            postId: widget.postId,
            content: content,
            authorName: name,
          );
      _contentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
      ref.invalidate(commentsProvider(widget.postId));
      _toast(res.message.isNotEmpty
          ? res.message
          : (res.approved ? 'تم نشر التعليق' : 'تم استلام تعليقك وبانتظار المراجعة'));
    } catch (e) {
      _toast('تعذّر إرسال التعليق');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final isLoggedIn = ref.watch(authProvider).status == AuthStatus.authenticated;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: const Text('التعليقات'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _Empty(
                icon: Icons.wifi_off_rounded,
                message: 'تعذّر تحميل التعليقات',
                onRetry: () => ref.invalidate(commentsProvider(widget.postId)),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return const _Empty(
                    icon: Icons.forum_outlined,
                    message: 'لا توجد تعليقات بعد. كن أول من يعلّق!',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(commentsProvider(widget.postId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: c.authorAvatar,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 40,
                                height: 40,
                                color: AppColors.surfaceContainerHigh,
                                child: const Icon(Icons.person_outline, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c.authorName,
                                      style: AppTypography.labelMd.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.dateHuman,
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.secondary.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  HtmlParserUtils.stripHtml(c.content),
                                  style: AppTypography.bodyMd.copyWith(
                                    color: isDark
                                        ? AppColors.inverseOnSurface
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Composer
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'اسمك',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'أضف تعليقاً...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _submit,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  const _Empty({required this.icon, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.secondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(message, style: AppTypography.bodyMd.copyWith(color: AppColors.secondary)),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ],
      ),
    );
  }
}
