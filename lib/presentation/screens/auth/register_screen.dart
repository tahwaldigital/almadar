import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();
    final res = await ref.read(authProvider.notifier).register(
          _nameController.text.trim(),
          email,
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'فشل إنشاء الحساب')),
      );
      return;
    }
    // الحساب أُنشئ؛ لو البريد غير مؤكَّد وجّه لشاشة إدخال الكود.
    if (!res.verified) {
      context.push('/verify-email', extra: email);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          color: AppColors.primary,
        ),
        title: Text(
          'إنشاء حساب',
          style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sectionGap),
                Center(
                  child: Text(
                    'مرحباً بك في المدار',
                    style: AppTypography.headlineLgMobile.copyWith(
                      color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'أنشئ حساباً للاستمتاع بجميع المميزات',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Text('الاسم الكامل', style: AppTypography.labelMd),
                const SizedBox(height: AppSpacing.stackSm),
                TextFormField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'أدخل اسمك الكامل',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Text('البريد الإلكتروني', style: AppTypography.labelMd),
                const SizedBox(height: AppSpacing.stackSm),
                TextFormField(
                  controller: _emailController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    final email = v.trim();
                    final valid = RegExp(
                      r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$',
                    ).hasMatch(email);
                    if (!valid) return 'بريد إلكتروني غير صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Text('كلمة المرور', style: AppTypography.labelMd),
                const SizedBox(height: AppSpacing.stackSm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'على الأقل 8 أحرف',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 8 ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل' : null,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    // معطّل أثناء الإرسال لمنع الضغط المزدوج وإنشاء حسابات مكرّرة.
                    onPressed: _isSubmitting ? null : _register,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'إنشاء الحساب',
                            style: AppTypography.labelMd.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('لديك حساب بالفعل؟ ', style: AppTypography.bodyMd),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'تسجيل الدخول',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
