
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

    // BuildConfig generation is off by default on AGP 8; MainActivity reads
    // BuildConfig.DEBUG to gate FLAG_SECURE (release-only screenshot blocking).
    buildFeatures {
        buildConfig = true
    }

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
            // SECURITY (fail-closed): a release build MUST be signed with the real
            // upload keystore (key.properties). We never silently fall back to the
            // debug keystore for release — that risks shipping a debug-signed,
            // debuggable artifact. For local/CI smoke builds that intentionally
            // accept debug signing, pass `-PallowDebugSigning=true`.
            val allowDebugSigning =
                (project.findProperty("allowDebugSigning") as String?)?.toBoolean() == true
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else if (allowDebugSigning) {
                    logger.warn(
                        "WARNING: signing :release with the DEBUG keystore " +
                        "(allowDebugSigning=true). Do NOT upload this artifact to Play."
                    )
                    signingConfigs.getByName("debug")
                } else {
                    throw GradleException(
                        "Release build requires android/key.properties (upload keystore). " +
                        "It is missing. For an intentional local/CI debug-signed smoke build, " +
                        "re-run with -PallowDebugSigning=true."
                    )
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
