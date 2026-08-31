import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final isLoggedIn = auth.status == AuthStatus.authenticated && auth.user != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: const Text('حسابي'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: isLoggedIn ? const _LoggedIn() : const _GuestView(),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text('لم تسجّل الدخول بعد', style: AppTypography.headlineMd),
            const SizedBox(height: 8),
            Text(
              'سجّل دخولك للوصول إلى حسابك وحفظ مقالاتك',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/login'),
              child: const Text('تسجيل الدخول'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('إنشاء حساب جديد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedIn extends ConsumerWidget {
  const _LoggedIn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        Center(
          child: Column(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: user.avatarUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 96,
                    height: 96,
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.person, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(user.name, style: AppTypography.headlineLgMobile),
              const SizedBox(height: 4),
              Text(user.email, style: AppTypography.bodyMd.copyWith(color: AppColors.secondary)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _Tile(
          icon: Icons.edit_outlined,
          label: 'تعديل الملف الشخصي',
          onTap: () => _showEditSheet(context, ref),
        ),
        _Tile(
          icon: Icons.bookmark_outline,
          label: 'مقالاتي المحفوظة',
          onTap: () => context.go('/bookmarks'),
        ),
        _Tile(
          icon: Icons.logout_rounded,
          label: 'تسجيل الخروج',
          color: AppColors.error,
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/home');
          },
        ),
      ],
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user!;
    final nameController = TextEditingController(text: user.name);
    final bioController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعديل الملف الشخصي', style: AppTypography.headlineMd),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'نبذة', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة مرور جديدة (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final ok = await ref.read(authProvider.notifier).updateProfile(
                        name: nameController.text.trim(),
                        bio: bioController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'تم تحديث الملف الشخصي' : 'تعذّر التحديث')),
                    );
                  }
                },
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Tile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(label, style: AppTypography.bodyMd.copyWith(color: color)),
      trailing: const Icon(Icons.chevron_left, size: 20),
      onTap: onTap,
    );
  }
}
