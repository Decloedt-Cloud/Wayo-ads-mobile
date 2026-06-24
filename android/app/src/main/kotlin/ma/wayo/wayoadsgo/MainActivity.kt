package ma.wayo.wayoadsgo

import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterFragmentActivity

/// [FlutterFragmentActivity] improves Google Sign-In / Play Services flows vs [FlutterActivity].
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)

        // SECURITY: FLAG_SECURE blocks screenshots / screen recording, blanks the
        // app preview in the recent-apps switcher, and prevents mirroring to
        // non-secure external displays. We keep it OFF in debug so developers can
        // still capture screenshots, and ON for every release build.
        if (!BuildConfig.DEBUG) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }

        // Edge-to-edge: Flutter draws behind system gesture/nav insets ([SystemUiMode.edgeToEdge]),
        // so our bottom bar [ColoredBox] can cover the inset without an OS scrim stripe.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
