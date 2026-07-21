import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/category.dart';
import '../../providers/admin_providers.dart';
import '../../providers/news_providers.dart';

/// شاشة كتابة خبر جديد ونشره إلى ووردبريس مباشرة. عند تفعيل "خبر عاجل"
/// يتولّى الخادم إرسال إشعار الدفع لكل المشتركين.
class ComposeArticleScreen extends ConsumerStatefulWidget {
  const ComposeArticleScreen({super.key});

  @override
  ConsumerState<ComposeArticleScreen> createState() =>
      _ComposeArticleScreenState();
}

class _ComposeArticleScreenState extends ConsumerState<ComposeArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _excerptCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  int? _categoryId;
  bool _isBreaking = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _excerptCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  bool _submitting = false;

  Future<void> _submit() async {
    // يحمي من الضغط المزدوج خلال فتح حوار تأكيد "عاجل" قبل بدء النشر.
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _submitting = true;
    try {
      await _doSubmit();
    } finally {
      _submitting = false;
    }
  }

  Future<void> _doSubmit() async {
    if (_isBreaking) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد النشر كخبر عاجل'),
          content: const Text(
            'سيصل إشعار فوري لكل المشتركين في التطبيق. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نشر عاجل'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final result = await ref.read(publishControllerProvider.notifier).publish(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          categoryId: _categoryId,
          excerpt: _excerptCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
          isBreaking: _isBreaking,
        );

    if (!mounted) return;

    if (result != null) {
      // لا نؤكّد إرسال الإشعار إلا إذا أكّده الخادم فعلًا.
      final message = result.breakingSent
          ? 'تم النشر وإرسال إشعار عاجل للمشتركين'
          : (_isBreaking
              ? 'تم نشر الخبر، لكن لم يُرسل إشعار عاجل'
              : 'تم نشر الخبر بنجاح');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              result.breakingSent || !_isBreaking ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final publishState = ref.watch(publishControllerProvider);
    final isSubmitting = publishState.isLoading;

    // أظهر رسالة الخطأ القادمة من الخادم (إن وُجدت).
    ref.listen(publishControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorText(next.error)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        title: const Text('كتابة خبر جديد'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: AbsorbPointer(
        absorbing: isSubmitting,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            children: [
              _label('عنوان الخبر'),
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: _dec('اكتب عنوانًا واضحًا وجذابًا'),
                validator: (v) =>
                    (v == null || v.trim().length < 5) ? 'العنوان قصير جدًا' : null,
              ),
              const SizedBox(height: AppSpacing.gutter),

              _label('القسم'),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('تعذّر تحميل الأقسام'),
                data: (cats) => DropdownButtonFormField<int>(
                  value: _categoryId,
                  isExpanded: true,
                  decoration: _dec('اختر القسم'),
                  items: [
                    for (final Category c in cats)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),

              _label('مقتطف (اختياري)'),
              TextFormField(
                controller: _excerptCtrl,
                maxLines: 2,
                decoration: _dec('ملخص قصير يظهر في قائمة الأخبار'),
              ),
              const SizedBox(height: AppSpacing.gutter),

              _label('رابط صورة الخبر (اختياري)'),
              TextFormField(
                controller: _imageCtrl,
                keyboardType: TextInputType.url,
                decoration: _dec('https://...'),
              ),
              const SizedBox(height: AppSpacing.gutter),

              _label('نص الخبر'),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 10,
                minLines: 6,
                decoration: _dec('اكتب تفاصيل الخبر هنا...'),
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'النص قصير جدًا'
                    : null,
              ),
              const SizedBox(height: AppSpacing.gutter),

              Container(
                decoration: BoxDecoration(
                  color: _isBreaking
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : (isDark
                          ? AppColors.surface.withValues(alpha: 0.06)
                          : AppColors.surface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isBreaking
                        ? AppColors.primary
                        : AppColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: SwitchListTile(
                  value: _isBreaking,
                  onChanged: (v) => setState(() => _isBreaking = v),
                  activeColor: AppColors.primary,
                  secondary: Icon(
                    Icons.priority_high_rounded,
                    color: _isBreaking ? AppColors.primary : AppColors.secondary,
                  ),
                  title: const Text('خبر عاجل',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                    'يُرسل إشعارًا فوريًا لكل المشتركين',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              FilledButton.icon(
                onPressed: isSubmitting ? null : _submit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(isSubmitting ? 'جارٍ النشر...' : 'نشر الخبر'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  String _errorText(Object? error) {
    if (error is ServerException) return error.message;
    if (error is NetworkException) return error.message;
    if (error is AuthException) return error.message;
    return 'تعذّر نشر الخبر، حاول مجددًا';
  }
}
