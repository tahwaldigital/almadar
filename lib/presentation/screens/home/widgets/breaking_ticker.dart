import 'dart:async';

import 'package:flutter/material.dart';
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

class _BreakingTickerState extends ConsumerState<BreakingTicker> {
  final _ctrl = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_ctrl.hasClients) return;
      final max = _ctrl.position.maxScrollExtent;
      if (max <= 0) return;
      var next = _ctrl.offset + 0.7;
      if (next >= max) next = 0;
      _ctrl.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          // الشريط المتحرك
          Expanded(
            child: ListView.separated(
              controller: _ctrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: items.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              itemBuilder: (context, i) {
                final a = items[i];
                return Center(
                  child: GestureDetector(
                    onTap: () => context.push('/article/${a.id}', extra: a),
                    child: Text(
                      a.title,
                      style: AppTypography.labelMd.copyWith(
                        color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
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
