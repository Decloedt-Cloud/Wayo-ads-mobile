
import java.util.Properties
        import java.io.FileInputStream

        plugins {
            id("com.android.application")
            id("kotlin-android")
            id("dev.flutter.flutter-gradle-plugin")
            id("com.google.gms.google-services")
        }

// =====================================================
// Load key.properties
// =====================================================

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

android {

    namespace = "ma.wayo.wayoadsgo"

    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // =====================================================
    // Java / Kotlin
    // =====================================================

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // =====================================================
    // Default config
    // =====================================================

    defaultConfig {

        applicationId = "ma.wayo.wayoadsgo"

        minSdk = maxOf(
            flutter.minSdkVersion,
            21
        )

        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // =====================================================
    // Signing
    // =====================================================

    signingConfigs {

        create("release") {

            if (keystorePropertiesFile.exists()) {

                keyAlias =
                    keystoreProperties["keyAlias"] as String

                keyPassword =
                    keystoreProperties["keyPassword"] as String

                storeFile = file(
                    keystoreProperties["storeFile"] as String
                )

                storePassword =
                    keystoreProperties["storePassword"] as String
            }
        }
    }

    // =====================================================
    // Build types
    // =====================================================

    buildTypes {

        release {
            // Use upload keystore when key.properties exists; otherwise fall back to the
            // debug keystore so local `flutter build apk --release` / CI smoke tests work.
            // Play Console uploads must always use a real release keystore + key.properties.
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile(
                    "proguard-android-optimize.txt"
                ),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// =====================================================
// Dependencies
// =====================================================

dependencies {

    implementation(
        "androidx.appcompat:appcompat:1.7.0"
    )

    implementation(
        "androidx.core:core-splashscreen:1.0.1"
    )

    implementation(
        "com.google.android.material:material:1.12.0"
    )

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
