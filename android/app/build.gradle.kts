plugins {
    id "com.android.application"
    // START: FlutterFire Configuration
    id "com.google.gms.google-services"
    // END: FlutterFire Configuration
    id "kotlin-android"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id "dev.flutter.flutter-gradle-plugin"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.kaong_fermentation_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 1. Set the Default Name (Used for Release builds)
        // Ensure your AndroidManifest.xml uses android:label="@string/app_name"
        resValue "string", "app_name", "Kaong Monitor"
    }

    // 2. Define the Signing Config (Reads from GitHub Secrets or falls back safely)
    signingConfigs {
        release {
            // Check if environment variables exist (GitHub Actions)
            if (System.getenv("PLAY_STORE_UPLOAD_KEY") != null) {
                storeFile = file("upload-keystore.jks")
                storePassword = System.getenv("STORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            } else {
                // FALLBACK: For local release builds on your Mac without secrets
                // We use the debug key so 'flutter run --release' doesn't crash.
                // It won't be signed for Play Store, but it runs on your phone.
                try {
                    // Try to use local keystore if it exists, otherwise use debug
                    storeFile = file("upload-keystore.jks")
                    // Note: If this file exists locally but no env vars are set, 
                    // the build might fail unless you hardcode passwords here for local use.
                    // For now, we catch the error to be safe.
                } catch (ignored) {
                    signingConfig signingConfigs.debug
                }
            }
        }
    }

    buildTypes {
        release {
            // 3. Use the Release Signing Config defined above
            signingConfig signingConfigs.release
            minifyEnabled false
            shrinkResources false
        }

        debug {
            // 4. Add '.dev' suffix so it installs as a SEPARATE app
            // Result ID: com.example.kaong_fermentation_app.dev
            applicationIdSuffix ".dev"
            
            // 5. Change the Name so you can distinguish it from the live version
            resValue "string", "app_name", "Kaong Monitor (Dev)"
        }
    }
}

flutter {
    source = "../.."
}