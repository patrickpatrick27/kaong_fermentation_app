plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kaong_fermentation_app"
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
        applicationId = "com.example.kaong_fermentation_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // KOTLIN SYNTAX: Uses parenthesis and quotes
        resValue("string", "app_name", "Kaong Monitor")
    }

    signingConfigs {
        create("release") {
            // Check for GitHub Environment Variables
            if (System.getenv("PLAY_STORE_UPLOAD_KEY") != null) {
                storeFile = file("upload-keystore.jks")
                storePassword = System.getenv("STORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            } else {
                // Local Fallback
                try {
                    storeFile = file("upload-keystore.jks")
                } catch (e: Exception) {
                    // Fallback to debug signing if release keystore is missing locally
                    val debugConfig = getByName("debug")
                    storeFile = debugConfig.storeFile
                    storePassword = debugConfig.storePassword
                    keyAlias = debugConfig.keyAlias
                    keyPassword = debugConfig.keyPassword
                }
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("debug") {
            // KOTLIN SYNTAX: explicit assignment
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Kaong Monitor (Dev)")
        }
    }
}

flutter {
    source = "../.."
}