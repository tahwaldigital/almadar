import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_status_provider.dart';
import '../screens/maintenance/force_update_screen.dart';
import '../screens/maintenance/maintenance_screen.dart';
import 'app_logo.dart';

/// يحرس واجهة التطبيق: يعرض المحتوى فقط عند الوصول للموقع، وإلا يعرض
/// شاشة "التطبيق جاري تحديثه" (أو انقطاع الإنترنت) مع زر إعادة المحاولة.
class AppAvailabilityGate extends ConsumerWidget {
  final Widget child;
  const AppAvailabilityGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStatusProvider);

    switch (status) {
      case AppStatus.available:
        return child;
      case AppStatus.checking:
        return const _SplashView();

      // انقطاع الشبكة أو تعذّر الوصول لا يمنع التطبيق: هناك أخبار مخزّنة
      // محليًا (Hive) يجب أن تظل قابلة للقراءة دون اتصال.
      case AppStatus.unreachable:
      case AppStatus.offline:
        return child;

      // تحديث إجباري: شاشة حاجبة توجّه المستخدم إلى المتجر.
      case AppStatus.updateRequired:
        return ForceUpdateScreen(
          storeUrl: AppStatusNotifier.forceUpdate.storeUrl,
          message: AppStatusNotifier.forceUpdate.message,
        );

      // الحجب الكامل فقط عندما يعلن الخادم وضع الصيانة صراحةً.
      case AppStatus.maintenance:
        return MaintenanceScreen(
          status: status,
          message: AppStatusNotifier.maintenanceMessage,
          isRechecking: false,
          onRetry: () => ref.read(appStatusProvider.notifier).recheck(),
        );
    }
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(height: 52),
            SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
