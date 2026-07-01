package ma.wayo.wayoadsgo

import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterFragmentActivity

/// [FlutterFragmentActivity] improves Google Sign-In / Play Services flows vs [FlutterActivity].
class MainActivity : FlutterFragmentActivity() {
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
