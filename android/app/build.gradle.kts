plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    // NOTE: kotlin-android plugin intentionally omitted — AGP 9 has built-in Kotlin support.
}

android {
    namespace = "com.example.operator_os"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.operator_os"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
