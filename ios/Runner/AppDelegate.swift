import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // تهيئة صريحة لـ Firebase قبل تسجيل الإضافات، بدل الاعتماد كليًا على
    // method swizzling. ملاحظة: لا نضبط UNUserNotificationCenter.delegate هنا
    // لأن flutter_local_notifications يملكه، وتغييره يكسر فتح المقال عند النقر
    // على الإشعار.
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
