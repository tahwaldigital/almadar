# ─────────────────────────────────────────────────────────────────────────────
# قواعد R8/ProGuard لتطبيق المدار نيوز (وضع release)
# ─────────────────────────────────────────────────────────────────────────────

# Flutter engine & plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (Flutter deferred components / split install) — يمنع خطأ "Missing class"
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# flutter_local_notifications — يستخدم Gson + reflection
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Gson
-dontwarn com.google.gson.**
-keep class com.google.gson.** { *; }
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Firebase / Cloud Messaging
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# الحفاظ على الأنواع العامة (للمكتبات التي تعتمد على Generics في وقت التشغيل)
-keepattributes Signature
