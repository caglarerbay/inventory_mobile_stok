plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin'ini Android ve Kotlin Gradle plugin'lerinden sonra ekleyin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.inventory_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Core library desugaring etkinleştiriliyor:
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.inventory_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug anahtarları ile imzalanıyor (üretim için uygun bir imzalama yapılandırması ekleyin)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Güncel desugar JDK kitaplığı sürümü: 2.1.4 veya daha yeni
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

apply(plugin = "com.google.gms.google-services")
