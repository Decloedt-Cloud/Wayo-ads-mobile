package ma.wayo.wayoadsgo

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.core.view.WindowCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// [FlutterFragmentActivity] improves Google Sign-In / Play Services flows vs [FlutterActivity].
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ma.wayo.wayoadsgo/network_settings",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openWirelessSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS))
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)

        // Screenshots / screen recording are allowed in all builds.
        // (FLAG_SECURE was previously set on release builds to block them.)

        // Edge-to-edge: Flutter draws behind system gesture/nav insets ([SystemUiMode.edgeToEdge]),
        // so our bottom bar [ColoredBox] can cover the inset without an OS scrim stripe.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
