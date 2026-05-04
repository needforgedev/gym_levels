plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gym_levels"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Base application ID. Each flavor below adds a suffix so dev
        // and prod builds install side-by-side on the same device.
        applicationId = "com.example.gym_levels"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ─── Flavors ─────────────────────────────────────────────────
    // Two environments separated by suffix so they coexist on the
    // same device:
    //
    //   dev   → com.example.gym_levels.dev   | "Level Up Dev"
    //   prod  → com.example.gym_levels        | "Level Up IRL"
    //
    // The `--dart-define` values (PROJECT_URL etc., wired through the
    // Makefile) drive which Supabase project each flavor talks to.
    // Flavors only control the Android-side bundle ID + app label.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Level Up Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Level Up IRL")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
