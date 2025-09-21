import java.util.Properties
import java.io.FileInputStream

// key.properties dosyasını okuyarak keystore bilgilerini yüklüyoruz.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

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

    // İmzalama konfigürasyonunu Kotlin DSL sözdizimine uygun olarak ayarlıyoruz.
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        // Release build için imzalamayı, oluşturduğumuz release signingConfig ile yapıyoruz.
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Örneğin ProGuard veya diğer optimizasyon ayarları buraya eklenebilir.
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

// Aşağıdaki Groovy tarzı kodlar kaldırıldı:
// def keystoreProperties = new Properties()
// def keystorePropertiesFile = rootProject.file("key.properties")
// if (keystorePropertiesFile.exists()) {
//     keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
// }

// Google Services plugin'i uyguluyoruz.
apply(plugin = "com.google.gms.google-services")
