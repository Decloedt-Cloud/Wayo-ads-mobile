package ma.wayo.wayoadsgo

import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ma.wayo.wayoadsgo/window_insets",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setDecorFitsSystemWindows" -> {
                    val fits = call.arguments as? Boolean ?: true
                    runOnUiThread {
                        try {
                            applyDecorFitsSystemWindows(fits)
                            result.success(null)
                        } catch (e: Exception) {
                            Log.w(TAG, "setDecorFitsSystemWindows failed", e)
                            result.error("window_insets", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Stripe Payment Sheet / Link attach to this activity. While
     * [WindowCompat.setDecorFitsSystemWindows] is false (edge-to-edge), their
     * bottom CTAs draw under the 3-button nav bar. Temporarily set [fits]=true
     * around Stripe present/dismiss.
     *
     * Must never throw — uncaught UI-thread errors here kill the process
     * ("Wayo Ads keeps stopping") right as ACH/card sheets open.
     */
    private fun applyDecorFitsSystemWindows(fits: Boolean) {
        WindowCompat.setDecorFitsSystemWindows(window, fits)
        if (fits) {
            @Suppress("DEPRECATION")
            window.clearFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
            @Suppress("DEPRECATION")
            window.navigationBarColor = Color.BLACK
            @Suppress("DEPRECATION")
            window.statusBarColor = Color.TRANSPARENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                window.isNavigationBarContrastEnforced = true
            }
            WindowInsetsControllerCompat(window, window.decorView).apply {
                isAppearanceLightNavigationBars = false
            }
        } else {
            @Suppress("DEPRECATION")
            window.navigationBarColor = Color.TRANSPARENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                window.isNavigationBarContrastEnforced = false
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
        try {
            applyDecorFitsSystemWindows(false)
        } catch (e: Exception) {
            Log.w(TAG, "edge-to-edge init failed", e)
        }
    }

    /// Required for home-widget taps while the activity is already alive (singleTop):
    /// without [setIntent], Flutter/home_widget keep reading the old launch Intent.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    companion object {
        private const val TAG = "WayoMainActivity"
    }
}
