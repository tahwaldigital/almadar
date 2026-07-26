import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _verifying = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown(); // الكود أُرسل بالفعل عند التسجيل
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        if (mounted) setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 4) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    final err =
        await ref.read(authProvider.notifier).verifyEmailCode(widget.email, code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد بريدك بنجاح')),
      );
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    final err = await ref.read(authProvider.notifier).resendCode(widget.email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'تم إرسال رمز جديد إلى بريدك')),
    );
    if (err == null) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('تأكيد البريد',
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sectionGap),
              Icon(Icons.mark_email_read_outlined,
                  size: 72, color: AppColors.primaryContainer),
              const SizedBox(height: AppSpacing.stackLg),
              Text('أدخل رمز التأكيد',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLgMobile.copyWith(
                    color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                  )),
              const SizedBox(height: 8),
              Text(
                'أرسلنا رمزًا مكوّنًا من 6 أرقام إلى\n${widget.email}',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                    fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '––––––',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : const Color(0xFFF6F7F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  child: _verifying
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('تأكيد',
                          style: AppTypography.labelMd
                              .copyWith(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextButton(
                onPressed: _cooldown > 0 ? null : _resend,
                child: Text(
                  _cooldown > 0
                      ? 'إعادة إرسال الرمز خلال $_cooldown ثانية'
                      : 'إعادة إرسال الرمز',
                  style: AppTypography.bodyMd.copyWith(
                    color: _cooldown > 0 ? AppColors.secondary : AppColors.primaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text('تخطٍّ الآن',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
