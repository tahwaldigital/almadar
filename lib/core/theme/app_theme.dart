import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.onTertiary,
          tertiaryContainer: AppColors.tertiaryContainer,
          onTertiaryContainer: AppColors.onTertiaryContainer,
          error: AppColors.error,
          onError: AppColors.onError,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          inverseSurface: AppColors.inverseSurface,
          onInverseSurface: AppColors.inverseOnSurface,
          inversePrimary: AppColors.inversePrimary,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          surfaceTint: AppColors.surfaceTint,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: AppTypography.rubik,
        textTheme: _buildTextTheme(AppColors.onSurface),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.rubik,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          iconTheme: IconThemeData(color: AppColors.primary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface.withValues(alpha: 0.9),
          indicatorColor: AppColors.primaryContainer.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            AppTypography.labelSm.copyWith(color: AppColors.secondary),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceContainerLowest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceContainerHigh,
          labelStyle: AppTypography.labelMd.copyWith(color: AppColors.secondary),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: AppTypography.labelMd,
          ),
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
          thickness: 1,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.inversePrimary,
          onPrimary: AppColors.onPrimaryContainer,
          primaryContainer: AppColors.primary,
          onPrimaryContainer: AppColors.inversePrimary,
          secondary: AppColors.secondaryContainer,
          onSecondary: AppColors.onSecondaryContainer,
          secondaryContainer: AppColors.secondary,
          onSecondaryContainer: AppColors.secondaryContainer,
          tertiary: AppColors.tertiaryContainer,
          onTertiary: AppColors.onTertiaryContainer,
          tertiaryContainer: AppColors.tertiary,
          onTertiaryContainer: AppColors.tertiaryContainer,
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: AppColors.surfaceDark,
          onSurface: AppColors.inverseOnSurface,
          onSurfaceVariant: AppColors.surfaceVariant,
          inverseSurface: AppColors.surface,
          onInverseSurface: AppColors.onSurface,
          inversePrimary: AppColors.primary,
          outline: AppColors.secondary,
          outlineVariant: AppColors.inverseSurface,
          surfaceTint: AppColors.inversePrimary,
        ),
        scaffoldBackgroundColor: AppColors.surfaceDark,
        fontFamily: AppTypography.rubik,
        textTheme: _buildTextTheme(AppColors.inverseOnSurface),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.rubik,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.inversePrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.inversePrimary),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0D1B2A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x1AFFFFFF)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
          indicatorColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1B2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x33FFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x33FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x1AFFFFFF),
          thickness: 1,
        ),
      );

  static TextTheme _buildTextTheme(Color baseColor) => TextTheme(
        displayLarge: AppTypography.displayLg.copyWith(color: baseColor),
        headlineLarge: AppTypography.headlineLg.copyWith(color: baseColor),
        headlineMedium: AppTypography.headlineLgMobile.copyWith(color: baseColor),
        headlineSmall: AppTypography.headlineMd.copyWith(color: baseColor),
        bodyLarge: AppTypography.bodyLg.copyWith(color: baseColor),
        bodyMedium: AppTypography.bodyMd.copyWith(color: baseColor),
        labelLarge: AppTypography.labelMd.copyWith(color: baseColor),
        labelMedium: AppTypography.labelMd.copyWith(color: baseColor),
        labelSmall: AppTypography.labelSm.copyWith(color: baseColor),
      );
}
