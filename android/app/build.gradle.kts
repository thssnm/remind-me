plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream


val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val useKeystoreSigning = keystorePropertiesFile.exists()
if (useKeystoreSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.theissenmatthias.remind_me"
    compileSdk = 35 // flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    

    signingConfigs {
        if (useKeystoreSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    // For Kotlin projects
    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.theissenmatthias.remind_me"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = 2
        versionName = "1.0.1"
    }

    buildTypes {
        release {
            if (useKeystoreSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }

    compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
    isCoreLibraryDesugaringEnabled = true  
}
}

dependencies {
    // For AGP 7.4+
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    // For AGP 7.3
    // coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.3")
    // For AGP 4.0 to 7.2
    // coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.1.9")
}

flutter {
    source = "../.."
}
