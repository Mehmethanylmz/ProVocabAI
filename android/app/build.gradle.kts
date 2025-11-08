plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pratikapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 1. DESUGARING AYARI EKLENDİ
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.pratikapp"
        // 2. MINSDK AYARI EKLENDİ
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
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

dependencies {
    // Bu satır 'flutter create .' komutuyla otomatik gelmeli
    implementation(kotlin("stdlib-jdk7"))
    
    // 3. DESUGARING KÜTÜPHANESİ EKLENDİ
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
