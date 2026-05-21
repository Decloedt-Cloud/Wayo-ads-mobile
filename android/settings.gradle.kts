import java.io.File
import java.util.Properties

/**
 * Flutter may rewrite [local.properties] with a stale sdk.dir from another machine.
 * If that path does not exist, pick the first valid SDK on this host.
 */
fun ensureAndroidSdkDir() {
    val localPropsFile = file("local.properties")
    val props = Properties()
    if (localPropsFile.exists()) {
        localPropsFile.inputStream().use { props.load(it) }
    }

    fun dirExists(path: String?): Boolean {
        if (path.isNullOrBlank()) return false
        return File(path.replace("\\\\", "\\")).isDirectory
    }

    if (dirExists(props.getProperty("sdk.dir"))) return

    val candidates = listOfNotNull(
        System.getenv("ANDROID_HOME"),
        System.getenv("ANDROID_SDK_ROOT"),
        "${System.getenv("LOCALAPPDATA")}${File.separator}Android${File.separator}Sdk",
        "${System.getenv("LOCALAPPDATA")}${File.separator}Android${File.separator}sdk",
    )

    val resolved = candidates.firstOrNull { dirExists(it) } ?: return
    props.setProperty("sdk.dir", resolved.replace("\\", "\\\\"))
    localPropsFile.outputStream().use { out ->
        props.store(out, "sdk.dir auto-fixed (previous path missing on this machine)")
    }
}

ensureAndroidSdkDir()

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Reads android/app/google-services.json and exposes config to Firebase Android SDKs.
    id("com.google.gms.google-services") version "4.4.4" apply false
}

include(":app")
