import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/entities/article.dart';
import '../../../providers/news_providers.dart';

/// شريط أخبار متحرك أفقياً (تيكر) تحت الهيدر — عاجل إن وُجد، وإلا آخر الأخبار.
class BreakingTicker extends ConsumerStatefulWidget {
  const BreakingTicker({super.key});

  @override
  ConsumerState<BreakingTicker> createState() => _BreakingTickerState();
}

class _BreakingTickerState extends ConsumerState<BreakingTicker>
    with SingleTickerProviderStateMixin {
  final _ctrl = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool _reduceMotion = false;

  // ── سرعة الشريط ────────────────────────────────────────────────────────
  // السرعة بالبكسل/الثانية، **مستقلة عن معدّل الإطارات** (تُحسب من الزمن
  // الفعلي المنقضي) فتظهر بنفس السرعة على شاشات 60/90/120Hz.
  // 20 بكسل/ثانية = إيقاع هادئ مريح للقراءة (أبطأ من 23 السابقة).
  // زوّدها لتسريع، قلّلها لتبطيء.
  static const double _pxPerSecond = 20;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // احترام «تقليل الحركة» في إعدادات الوصول: يتوقّف الشريط عن التمرير.
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  void _onTick(Duration elapsed) {
    final dtSec = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_reduceMotion || !_ctrl.hasClients) return;
    final pos = _ctrl.position;
    final max = pos.maxScrollExtent;
    if (max <= 0) return;
    // تجاهُل الفجوات الكبيرة (رجوع من الخلفية) حتى لا يقفز الشريط دفعة واحدة.
    if (dtSec <= 0 || dtSec > 0.25) return;
    // القائمة معروضة نسختين متطابقتين، فنلتفّ عند نهاية النسخة الأولى
    // (عرض مجموعة واحدة = (المدى + عرض النافذة) ÷ 2). لحظتها تكون النسخة
    // الثانية تحت المؤشر، فيبدو التمرير لا نهائيًا بلا أي قفزة بصرية.
    final oneSet = (max + pos.viewportDimension) / 2;
    final wrapAt = oneSet <= max ? oneSet : max;
    var next = _ctrl.offset + _pxPerSecond * dtSec;
    if (next >= wrapAt) next -= wrapAt;
    _ctrl.jumpTo(next.clamp(0.0, max));
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breaking = ref.watch(breakingNewsProvider);
    final latest = ref.watch(latestNewsProvider).value ?? const <Article>[];

    final isBreaking = breaking.maybeWhen(data: (b) => b.isNotEmpty, orElse: () => false);
    final items = breaking
        .maybeWhen(
          data: (b) => b.isNotEmpty ? b : latest,
          orElse: () => latest,
        )
        .take(12)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181E) : AppColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          // لصيقة ثابتة
          Container(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: isBreaking ? AppColors.breakingRed : AppColors.primary,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  isBreaking ? 'عاجل' : 'الأخبار',
                  style: AppTypography.labelSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // الشريط المتحرك — نعرض العناصر **مرّتين** لالتفاف سلس بلا قفزة.
          // الفاصل النقطي جزء من كل عنصر (لاحقًا له) حتى تكون النسختان
          // متطابقتين دوريًا تمامًا فيصحّ حساب نقطة الالتفاف.
          Expanded(
            child: ListView.builder(
              controller: _ctrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: items.length * 2,
              itemBuilder: (context, i) {
                final a = items[i % items.length];
                return Center(
                  child: GestureDetector(
                    onTap: () => context.push('/article/${a.id}', extra: a),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.title,
                          style: AppTypography.labelMd.copyWith(
                            color: isDark
                                ? AppColors.inverseOnSurface
                                : AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
