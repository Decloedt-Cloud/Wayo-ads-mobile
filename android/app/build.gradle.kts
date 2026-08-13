import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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

    // BuildConfig generation is off by default on AGP 8;
    // MainActivity reads BuildConfig.DEBUG to gate FLAG_SECURE
    // (release-only screenshot blocking).
    buildFeatures {
        buildConfig = true
    }

    // =====================================================
    // Java
    // =====================================================

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
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
            // SECURITY (fail-closed):
            // A release build MUST be signed with the real upload keystore
            // defined in key.properties.
            //
            // Never silently fall back to the debug keystore for a normal
            // production release.
            //
            // For intentional local/CI smoke builds only:
            // -PallowDebugSigning=true
            //
            // Only throw when a Release task is actually requested so that
            // debug builds remain usable without key.properties.

            val allowDebugSigning =
                (project.findProperty("allowDebugSigning") as String?)
                    ?.toBoolean() == true

            val requestingRelease =
                gradle.startParameter.taskNames.any {
                    it.contains(
                        "Release",
                        ignoreCase = true
                    )
                }

            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else if (allowDebugSigning) {
                    logger.warn(
                        "WARNING: signing :release with the DEBUG keystore " +
                            "(allowDebugSigning=true). " +
                            "Do NOT upload this artifact to Play."
                    )

                    signingConfigs.getByName("debug")
                } else if (requestingRelease) {
                    throw GradleException(
                        "Release build requires android/key.properties " +
                            "(upload keystore). It is missing. " +
                            "For an intentional local/CI debug-signed " +
                            "smoke build, re-run with " +
                            "-PallowDebugSigning=true."
                    )
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

// =====================================================
// Kotlin
// =====================================================
//
// Modern Kotlin compiler configuration.
// Replaces deprecated:
//
// kotlinOptions {
//     jvmTarget = "17"
// }
// =====================================================

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

// =====================================================
// Flutter
// =====================================================

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

    // Passkeys / WebAuthn via Credential Manager (Android 9+)
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")

    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}

// =====================================================
// Stripe compatibility
// =====================================================
//
// Do NOT force stripe-android past flutter_stripe's pin (21.6.+).
//
// Forcing 21.29.0 caused native process crashes when presenting
// ACH / Financial Connections PaymentSheet due to a binary mismatch
// with stripe_android 11.5.