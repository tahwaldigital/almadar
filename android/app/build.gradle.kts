import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // يجب أن يأتي بعد إضافة أندرويد/فلاتر؛ يقرأ android/app/google-services.json.
    id("com.google.gms.google-services")
}

// ── Load signing credentials from key.properties (never committed to VCS) ──────
val keyProps = Properties()
val keyPropsFile = rootProject.file("key.properties")
if (keyPropsFile.exists()) {
    keyProps.load(FileInputStream(keyPropsFile))
}

android {
    namespace = "com.almadar.almadar_news"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias     = keyProps["keyAlias"]     as String?
            keyPassword  = keyProps["keyPassword"]  as String?
            storeFile    = keyProps["storeFile"]?.let { file(it as String) }
            storePassword = keyProps["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "almadar.news"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig   = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // ضمّن رموز تصحيح الأخطاء للكود الأصلي (native) في الـ AAB
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
