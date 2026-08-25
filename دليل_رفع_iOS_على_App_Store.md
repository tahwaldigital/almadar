# دليل رفع تطبيق "المدار الإخبارية" على App Store

تطبيق Flutter لقراءة الأخبار من موقع WordPress (`almadar-news.com`) عبر REST API مخصص.
**يستخدم Firebase Cloud Messaging لإشعارات الأخبار العاجلة.**
**لا يتطلب تسجيل دخول ولا إنشاء حساب** — كل المحتوى متاح فور فتح التطبيق.

هذا الدليل لمن سيرفع التطبيق من جهاز **Mac**.

---

## المتطلبات
- جهاز **Mac** + **Xcode** (أحدث إصدار).
- حساب **Apple Developer** مفعّل ($99/سنة).
- Flutter SDK مثبّت على الـ Mac.

---

## 1) التجهيز على الـ Mac
```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ios   # تجربة بناء
```
> مجلد `ios/Pods` و `Podfile.lock` يتولّدان على الـ Mac عند `pod install`.

## 2) التوقيع (Signing)
1. `open ios/Runner.xcworkspace` (مهم: `.xcworkspace` وليس `.xcodeproj`).
2. هدف **Runner** ← **Signing & Capabilities** ← فعّل **Automatically manage signing**.
3. اختر **Team** الخاص بك.
4. تأكد أن **Bundle Identifier** = `com.almadar.almadarNews`.

5. **أضف** القدرات التالية من **+ Capability** (إلزامية للإشعارات):
   - **Push Notifications**
   - **Background Modes** ← فعّل **Remote notifications**

> ⚠️ بدون هاتين القدرتين لن يصدر النظام رمز APNs، ولن تصل أي إشعارات على iOS
> مهما كان الكود سليمًا.

### إعداد APNs في Firebase (مطلوب مرة واحدة)
1. **Apple Developer ← Certificates, Identifiers & Profiles ← Keys** ← أنشئ مفتاحًا
   وفعّل **Apple Push Notifications service (APNs)** ونزّل ملف `.p8`
   (يُنزَّل مرة واحدة فقط — احفظه خارج git). سجّل **Key ID** و **Team ID**.
2. **Identifiers ← `com.almadar.almadarNews`** ← فعّل **Push Notifications** واحفظ.
3. **Firebase Console ← مشروع `almadar-b09df` ← Project Settings ← Cloud Messaging
   ← Apple app configuration** ← ارفع ملف `.p8` مع الـ Key ID و Team ID.
4. جدّد **Provisioning Profile** بعد تفعيل القدرة، ثم أعد البناء.

> `ios/Runner/Runner.entitlements` مضبوط على `aps-environment = production` وهو
> الصحيح لـ TestFlight و App Store. غيّره مؤقتًا إلى `development` فقط إن أردت
> الاختبار بنسخة debug من Xcode مباشرة.

## 3) رقم الإصدار
في `pubspec.yaml`: `1.0.0+1` — زِد رقم الـ Build (`+1`) مع كل رفع جديد.

## 4) البناء والرفع
في Xcode: اختر الجهاز **Any iOS Device (arm64)** ← **Product ▸ Archive** ←
في Organizer: **Distribute App ▸ App Store Connect ▸ Upload**.
أو: `flutter build ipa --release` ثم ارفع الـ IPA عبر Transporter/Xcode.

---

## ⚠️ نقاط قد تسبب رفض أبل — يجب معالجتها

### أ) حذف الحساب داخل التطبيق (Guideline 5.1.1(v)) — الأهم
التطبيق فيه **إنشاء حساب** (تسجيل)، وأبل **تشترط** وجود زر "حذف الحساب" داخل التطبيق.
حالياً **غير موجود**. الحلول:
- **الأفضل**: إضافة ميزة "حذف حسابي" في شاشة الملف الشخصي (تستدعي endpoint بالباك إند).
- أو: إزالة التسجيل/الدخول من التطبيق نهائياً والاكتفاء بوضع الضيف.

### ب) التعليقات = محتوى مستخدمين (Guideline 1.2)
الأخبار يمكن التعليق عليها. أبل تطلب آليات ضد المحتوى المسيء:
- مراجعة التعليقات قبل النشر (موجودة في الباك إند عبر `approved`) ✅
- يُفضّل إضافة زر **"إبلاغ عن تعليق"** + إمكانية **حظر مستخدم** داخل التطبيق.
- وجود بريد/جهة تواصل للشكاوى.

### ج) سياسة الخصوصية (Privacy Policy URL) — إلزامي
جهّز رابطاً يحتوي سياسة خصوصية (التطبيق يجمع بريد/اسم عند التسجيل). يُدخل في App Store Connect.

### د) App Privacy (بطاقة الخصوصية) في App Store Connect
صرّح بالبيانات المجمّعة: البريد والاسم (للحسابات فقط). لا يوجد تتبّع إعلاني.

---

## بيانات المتجر المطلوبة (App Store Connect)
1. إنشاء تطبيق بنفس الـ Bundle ID.
2. الاسم، الوصف بالعربية، الكلمات المفتاحية، الفئة = **News**.
3. لقطات شاشة لمقاسات iPhone 6.7" و 6.5".
4. أيقونة 1024×1024 (جاهزة داخل التطبيق، لكن المتجر يطلب رفعها أيضاً).
5. سياسة الخصوصية + بطاقة App Privacy.

---

## ✅ تم تجهيزه مسبقاً (من Windows)
- أيقونات iOS الحقيقية (وُلّدت من `assets/images/app_icon.png` بدون شفافية) — بدل الأيقونة الافتراضية المرفوضة.
- `Info.plist`: `ITSAppUsesNonExemptEncryption=false` (يلغي سؤال التشفير) + دعم اللغتين ar/en.
- `PrivacyInfo.xcprivacy` (ملف الخصوصية الإلزامي من أبل).
- Bundle ID مضبوط: `com.almadar.almadarNews`.
- كل اتصالات الـ API عبر **HTTPS** (لا مشاكل ATS).

## ملاحظات
- التطبيق لا يستخدم إشعارات؛ مكتبة `firebase_messaging` موجودة في الكود لكنها **خاملة**
  (الكود يتجاوزها بأمان). لا تسبب تعطّلاً، لكن يُفضّل إزالتها لاحقاً لتنظيف التطبيق.
- تأكد أن صور WordPress تُحمّل عبر `https` (وليس `http`) وإلا لن تظهر بسبب ATS.
