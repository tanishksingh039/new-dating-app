import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("../android/key.properties")
val keystoreProperties = Properties()
var hasValidKeystore = false

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    val storeFile = keystoreProperties.getProperty("storeFile", "")
    val keyAlias = keystoreProperties.getProperty("keyAlias", "")
    val keyPassword = keystoreProperties.getProperty("keyPassword", "")
    val storePassword = keystoreProperties.getProperty("storePassword", "")

    // Check if keystore file exists
    val keystoreFile = rootProject.file(storeFile)
    val keystoreExists = keystoreFile.exists()

    hasValidKeystore = storeFile.isNotEmpty() && keyAlias.isNotEmpty() && 
                       keyPassword.isNotEmpty() && storePassword.isNotEmpty() && keystoreExists
}

android {
    namespace = "com.campusbound.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        if (hasValidKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.campusbound.app"
        minSdk = 26  // Required for tflite_flutter (face detection)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (hasValidKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
            // Optional: enable minification
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Firebase Crashlytics and Analytics
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics")
}