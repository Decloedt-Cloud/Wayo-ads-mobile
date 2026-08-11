package ma.wayo.wayoadsgo

import android.app.Activity
import android.app.Application
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import java.util.WeakHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Stripe Link / Financial Connections / PaymentSheet draw under the 3-button
 * nav bar on targetSdk 35+ (transparent nav + Compose edge-to-edge).
 *
 * [WindowCompat.setDecorFitsSystemWindows] alone is not enough — Stripe often
 * re-enables edge-to-edge after onCreate. We also pad [android.R.id.content]
 * by the navigation-bar inset so CTAs stay tappable above the system bar.
 */
internal object StripeOverlayChrome {
    private const val TAG = "StripeOverlayChrome"
    private val installed = AtomicBoolean(false)
    private val padded = WeakHashMap<Activity, Boolean>()

    fun install(application: Application) {
        if (!installed.compareAndSet(false, true)) {
            return
        }
        application.registerActivityLifecycleCallbacks(
            object : Application.ActivityLifecycleCallbacks {
                override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                    if (isStripeOverlay(activity)) {
                        applySafeChrome(activity)
                    }
                }

                override fun onActivityStarted(activity: Activity) {
                    if (isStripeOverlay(activity)) {
                        applySafeChrome(activity)
                    }
                }

                override fun onActivityResumed(activity: Activity) {
                    if (isStripeOverlay(activity)) {
                        applySafeChrome(activity)
                    }
                }

                override fun onActivityPaused(activity: Activity) = Unit
                override fun onActivityStopped(activity: Activity) = Unit
                override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
                override fun onActivityDestroyed(activity: Activity) {
                    padded.remove(activity)
                }
            },
        )
    }

    /** Also used by MainActivity while Payment Sheet / Link runs in-process. */
    fun applyTo(activity: Activity) {
        applySafeChrome(activity)
    }

    fun clearPadding(activity: Activity) {
        try {
            val content = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
            ViewCompat.setOnApplyWindowInsetsListener(content, null)
            content.setPadding(0, 0, 0, 0)
            padded.remove(activity)
        } catch (e: Exception) {
            Log.w(TAG, "clearPadding failed", e)
        }
    }

    private fun isStripeOverlay(activity: Activity): Boolean {
        val name = activity.javaClass.name
        return name.startsWith("com.stripe.android.")
    }

    private fun applySafeChrome(activity: Activity) {
        try {
            applySafeChromeNow(activity)
            installNavBarPadding(activity)
            val decor = activity.window?.decorView ?: return
            decor.post { applySafeChromeNow(activity); installNavBarPadding(activity) }
            decor.postDelayed({ applySafeChromeNow(activity); installNavBarPadding(activity) }, 50)
            decor.postDelayed({ applySafeChromeNow(activity); installNavBarPadding(activity) }, 200)
            decor.postDelayed({ applySafeChromeNow(activity); installNavBarPadding(activity) }, 500)
        } catch (e: Exception) {
            Log.w(TAG, "applySafeChrome failed for ${activity.javaClass.simpleName}", e)
        }
    }

    private fun applySafeChromeNow(activity: Activity) {
        val window = activity.window ?: return
        // Keep edge-to-edge and pad the content view — Stripe Compose re-enables
        // edge-to-edge after decorFits=true, which left CTAs under the nav bar.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        @Suppress("DEPRECATION")
        window.clearFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
        @Suppress("DEPRECATION")
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        @Suppress("DEPRECATION")
        window.navigationBarColor = Color.BLACK
        @Suppress("DEPRECATION")
        window.statusBarColor = Color.BLACK
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = true
        }
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightNavigationBars = false
            isAppearanceLightStatusBars = false
            show(WindowInsetsCompat.Type.systemBars())
        }
    }

    private fun installNavBarPadding(activity: Activity) {
        val content = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
        if (padded[activity] == true) {
            ViewCompat.requestApplyInsets(content)
            return
        }
        padded[activity] = true

        ViewCompat.setOnApplyWindowInsetsListener(content) { v, insets ->
            // Pad ONLY for the system nav bar. Never include IME — Stripe Compose
            // already resizes for the keyboard; combining both crushed the sheet.
            val nav = insets.getInsets(WindowInsetsCompat.Type.navigationBars())
            val bottom = nav.bottom
            if (v.paddingBottom != bottom) {
                v.setPadding(v.paddingLeft, v.paddingTop, v.paddingRight, bottom)
            }
            // Consume only nav-bottom (we applied it). Leave IME / status for Stripe.
            WindowInsetsCompat.Builder(insets)
                .setInsets(
                    WindowInsetsCompat.Type.navigationBars(),
                    Insets.of(nav.left, nav.top, nav.right, 0),
                )
                .build()
        }
        // Manual nav padding only — do not also let the framework resize for IME.
        content.fitsSystemWindows = false
        ViewCompat.requestApplyInsets(content)
        content.addOnAttachStateChangeListener(
            object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) {
                    ViewCompat.requestApplyInsets(v)
                }

                override fun onViewDetachedFromWindow(v: View) = Unit
            },
        )
    }
}
