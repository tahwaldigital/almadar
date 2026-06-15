import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Consistent section header used across the app:
/// an accent bar, a title, and an optional "see all" action.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onSeeAll,
    this.seeAllLabel = 'عرض الكل',
  });

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.dark
        ? AppColors.inverseOnSurface
        : AppColors.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(width: 10),
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary, size: 19),
              const SizedBox(width: 6),
            ],
            Text(title, style: AppTypography.headlineMd.copyWith(color: ink)),
          ],
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(seeAllLabel,
                    style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_back_ios_rounded, size: 12, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}
