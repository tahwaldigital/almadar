import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/providers/theme_providers.dart';
import 'presentation/router/app_router.dart';
import 'presentation/widgets/app_availability_gate.dart';

class AlmadarApp extends ConsumerWidget {
  const AlmadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'المدار الإخبارية',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final scale = ref.watch(fontScaleProvider);
        // Status-bar icons adapt to the active theme (visible in both modes).
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: AppAvailabilityGate(child: child!),
            ),
          ),
        );
      },
    );
  }
}
