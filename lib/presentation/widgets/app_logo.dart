import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_branding.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Brand logo used across the app (splash, header, etc.).
///
/// Loads the network wordmark (cached) and falls back to an initials badge
/// if the image is unavailable, so the brand never disappears.
class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({super.key, this.height = 36});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: AppBranding.logoUrl,
      height: height,
      fit: BoxFit.contain,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => SizedBox(
        height: height,
        width: height * AppBranding.logoAspect,
      ),
      errorWidget: (_, __, ___) => _Fallback(height: height),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double height;
  const _Fallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: height,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(height * 0.25),
          ),
          child: Center(
            child: Text(
              'م',
              style: TextStyle(
                fontFamily: AppTypography.rubik,
                fontSize: height * 0.55,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'المدار',
          style: AppTypography.headlineLgMobile.copyWith(
            color: AppColors.primary,
            fontSize: height * 0.5,
          ),
        ),
      ],
    );
  }
}
