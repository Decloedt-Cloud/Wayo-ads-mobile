package ma.wayo.wayoadsgo.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import ma.wayo.wayoadsgo.MainActivity
import ma.wayo.wayoadsgo.R

/**
 * Plain [AppWidgetProvider] (not HomeWidgetProvider) — more reliable on Samsung One UI
 * when binding the first time.
 */
class PerformanceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = safePrefs(context)
        for (id in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_performance)
                val auth = prefs.str("auth_state", "logged_out")
                val primary = prefs.str("primary_metric_value", "—")
                val label = prefs.str("primary_metric_label", context.getString(R.string.widget_performance_metric_fallback))
                val left = prefs.str("secondary_left_value")
                val right = prefs.str("secondary_right_value")
                val leftL = prefs.str("secondary_left_label")
                val rightL = prefs.str("secondary_right_label")
                val tertiaryL = prefs.str("tertiary_label")
                val tertiaryV = prefs.str("tertiary_value")
                val emptyHeadline = prefs.str("empty_headline")
                val emptyCta = prefs.str("empty_cta")
                val status = prefs.str("status_message")
                val stale = prefs.str("stale_hint")

                views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_brand_name))
                views.setTextViewText(R.id.widget_primary_value, primary.ifBlank { "—" })
                views.setTextViewText(R.id.widget_primary_label, label)

                val showSecondary = left.isNotBlank() || right.isNotBlank()
                views.setViewVisibility(
                    R.id.widget_secondary_row,
                    if (showSecondary) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.widget_secondary_left_value, left)
                views.setTextViewText(R.id.widget_secondary_left_label, leftL)
                views.setTextViewText(R.id.widget_secondary_right_value, right)
                views.setTextViewText(R.id.widget_secondary_right_label, rightL)

                val tertiary = when {
                    tertiaryL.isNotBlank() && tertiaryV.isNotBlank() -> "$tertiaryL $tertiaryV"
                    tertiaryV.isNotBlank() -> tertiaryV
                    else -> ""
                }
                views.setViewVisibility(
                    R.id.widget_tertiary,
                    if (tertiary.isNotBlank()) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.widget_tertiary, tertiary)

                val showEmpty = emptyHeadline.isNotBlank() || emptyCta.isNotBlank()
                views.setViewVisibility(
                    R.id.widget_empty_headline,
                    if (emptyHeadline.isNotBlank()) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.widget_empty_headline, emptyHeadline)
                views.setViewVisibility(
                    R.id.widget_empty_cta,
                    if (emptyCta.isNotBlank()) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.widget_empty_cta, emptyCta)

                views.setTextViewText(
                    R.id.widget_status,
                    when {
                        auth != "logged_in" ->
                            status.ifBlank { context.getString(R.string.widget_sign_in) }
                        showEmpty -> ""
                        status.isNotBlank() -> status
                        else -> stale
                    },
                )

                val tapUri = when {
                    auth != "logged_in" -> "wayoads://dashboard"
                    emptyCta.contains("campaign", ignoreCase = true) ||
                        emptyCta.contains("campagne", ignoreCase = true) ->
                        "wayoads://campaigns/create"
                    emptyCta.contains("opportunit", ignoreCase = true) ->
                        "wayoads://campaigns"
                    else -> "wayoads://dashboard"
                }
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    clickIntent(context, tapUri, 100 + id),
                )
                appWidgetManager.updateAppWidget(id, views)
            } catch (t: Throwable) {
                Log.e(TAG, "PerformanceWidget update failed id=$id", t)
                try {
                    val views = RemoteViews(context.packageName, R.layout.widget_performance)
                    views.setTextViewText(R.id.widget_primary_value, "Wayo")
                    views.setTextViewText(
                        R.id.widget_status,
                        context.getString(R.string.widget_sign_in),
                    )
                    appWidgetManager.updateAppWidget(id, views)
                } catch (t2: Throwable) {
                    Log.e(TAG, "PerformanceWidget fallback failed", t2)
                }
            }
        }
    }

    companion object {
        private const val TAG = "WayoAdsWidget"
    }
}

class WalletWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = safePrefs(context)
        for (id in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_wallet)
                val role = prefs.str("role", "advertiser")
                val auth = prefs.str("auth_state", "logged_out")
                val status = prefs.str("status_message")
                val stale = prefs.str("stale_hint")
                val title = prefs.str("wallet_title").ifBlank {
                    context.getString(R.string.widget_wallet_label)
                }
                val balanceFmt = prefs.str("balance_formatted")
                val balanceRaw = prefs.str("balance")
                val pendingFmt = prefs.str("pending_formatted")
                val pendingRaw = prefs.str("pending_balance")
                val availableLabel = prefs.str("available_label").ifBlank {
                    context.getString(R.string.widget_available)
                }
                val pendingLabel = prefs.str("pending_label").ifBlank {
                    context.getString(R.string.widget_pending)
                }
                val emptyHeadline = prefs.str("empty_headline")
                val emptyCta = prefs.str("empty_cta")
                val currency = prefs.str("currency", "USD")
                val symbol = if (currency.equals("EUR", true)) "€" else "$"

                views.setTextViewText(R.id.widget_wallet_title, title)
                val balanceText = when {
                    balanceFmt.isNotBlank() -> balanceFmt
                    balanceRaw.isNotBlank() -> "$symbol$balanceRaw"
                    else -> "—"
                }
                views.setTextViewText(R.id.widget_wallet_balance, balanceText)
                views.setTextViewText(R.id.widget_wallet_available_label, availableLabel)

                val pendingText = when {
                    pendingFmt.isNotBlank() -> pendingFmt
                    pendingRaw.isNotBlank() && pendingRaw != "0.00" && pendingRaw != "0" ->
                        "$symbol$pendingRaw"
                    else -> ""
                }
                val showPending = pendingText.isNotBlank()
                views.setViewVisibility(
                    R.id.widget_wallet_pending_row,
                    if (showPending) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.widget_wallet_pending_label, pendingLabel)
                views.setTextViewText(R.id.widget_wallet_pending, pendingText)

                // Wallet-specific empty: only when zero balance messaging is present
                // and there's no pending row (avoid clutter on normal wallets).
                val zeroish = balanceRaw == "0.00" || balanceRaw == "0" || balanceRaw.isBlank()
                val showEmpty = auth == "logged_in" &&
                    zeroish &&
                    !showPending &&
                    (emptyHeadline.isNotBlank() || emptyCta.isNotBlank())
                views.setViewVisibility(
                    R.id.widget_empty_headline,
                    if (showEmpty && emptyHeadline.isNotBlank()) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.widget_empty_headline, emptyHeadline)
                views.setViewVisibility(
                    R.id.widget_empty_cta,
                    if (showEmpty && emptyCta.isNotBlank()) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.widget_empty_cta, emptyCta)

                views.setTextViewText(
                    R.id.widget_status,
                    when {
                        auth != "logged_in" ->
                            status.ifBlank { context.getString(R.string.widget_sign_in) }
                        showEmpty -> ""
                        else -> stale
                    },
                )

                val tap = when {
                    auth != "logged_in" -> "wayoads://dashboard"
                    showEmpty &&
                        (emptyCta.contains("fund", ignoreCase = true) ||
                            emptyCta.contains("fonds", ignoreCase = true)) ->
                        "wayoads://wallet"
                    showEmpty && role == "creator" -> "wayoads://campaigns"
                    else -> "wayoads://wallet"
                }
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    clickIntent(context, tap, 500 + id),
                )
                appWidgetManager.updateAppWidget(id, views)
            } catch (t: Throwable) {
                Log.e("WayoAdsWidget", "WalletWidget update failed id=$id", t)
            }
        }
    }
}

class QuickActionsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = safePrefs(context)
        for (id in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_quick_actions)
                val role = prefs.str("role", "advertiser")
                val isCreator = role == "creator"
                val auth = prefs.str("auth_state", "logged_out")
                val status = prefs.str("status_message")

                views.setTextViewText(
                    R.id.widget_qa_title,
                    context.getString(R.string.widget_quick_actions_title),
                )

                if (isCreator) {
                    views.setTextViewText(
                        R.id.widget_qa_a_label,
                        context.getString(R.string.widget_qa_opportunities),
                    )
                    views.setTextViewText(
                        R.id.widget_qa_b_label,
                        context.getString(R.string.widget_qa_collabs),
                    )
                    views.setTextViewText(
                        R.id.widget_qa_c_label,
                        context.getString(R.string.widget_qa_earnings),
                    )
                    views.setTextViewText(
                        R.id.widget_qa_d_label,
                        context.getString(R.string.widget_qa_analytics),
                    )
                    views.setImageViewResource(R.id.widget_qa_a_icon, R.drawable.ic_widget_action_list)
                    views.setImageViewResource(R.id.widget_qa_b_icon, R.drawable.ic_widget_action_info)
                    views.setImageViewResource(R.id.widget_qa_c_icon, R.drawable.ic_widget_action_wallet)
                    views.setImageViewResource(R.id.widget_qa_d_icon, R.drawable.ic_widget_action_chart)
                } else {
                    views.setTextViewText(
                        R.id.widget_qa_a_label,
                        context.getString(R.string.widget_qa_create),
                    )
                    views.setTextViewText(
                        R.id.widget_qa_b_label,
                        context.getString(R.string.widget_qa_campaigns),
                    )
                    views.setTextViewText(
                        R.id.widget_qa_c_label,
                        context.getString(R.string.widget_qa_analytics),
                    )
                    views.setTextViewText(
                        R.id.widget_qa_d_label,
                        context.getString(R.string.widget_qa_wallet),
                    )
                    views.setImageViewResource(R.id.widget_qa_a_icon, R.drawable.ic_widget_action_add)
                    views.setImageViewResource(R.id.widget_qa_b_icon, R.drawable.ic_widget_action_list)
                    views.setImageViewResource(R.id.widget_qa_c_icon, R.drawable.ic_widget_action_chart)
                    views.setImageViewResource(R.id.widget_qa_d_icon, R.drawable.ic_widget_action_wallet)
                }

                views.setTextViewText(
                    R.id.widget_status,
                    when {
                        auth != "logged_in" ->
                            status.ifBlank { context.getString(R.string.widget_sign_in) }
                        else -> ""
                    },
                )

                val a = if (isCreator) "wayoads://campaigns" else "wayoads://campaigns/create"
                val b = "wayoads://campaigns"
                val c = if (isCreator) "wayoads://wallet" else "wayoads://analytics"
                val d = if (isCreator) "wayoads://analytics" else "wayoads://wallet"

                views.setOnClickPendingIntent(R.id.widget_qa_a, clickIntent(context, a, 600 + id))
                views.setOnClickPendingIntent(R.id.widget_qa_b, clickIntent(context, b, 700 + id))
                views.setOnClickPendingIntent(R.id.widget_qa_c, clickIntent(context, c, 800 + id))
                views.setOnClickPendingIntent(R.id.widget_qa_d, clickIntent(context, d, 900 + id))
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    clickIntent(context, "wayoads://dashboard", 1000 + id),
                )
                appWidgetManager.updateAppWidget(id, views)
            } catch (t: Throwable) {
                Log.e("WayoAdsWidget", "QuickActions update failed id=$id", t)
            }
        }
    }
}

private fun SharedPreferences.str(key: String, fallback: String = ""): String =
    getString(key, fallback) ?: fallback

private fun safePrefs(context: Context): SharedPreferences {
    return try {
        HomeWidgetPlugin.getData(context)
    } catch (_: Throwable) {
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }
}

private fun clickIntent(context: Context, uri: String, requestCode: Int): PendingIntent {
    val intent = Intent(context, MainActivity::class.java).apply {
        data = Uri.parse(uri)
        // home_widget plugin listens for this action to emit widgetClicked.
        action = "es.antonborri.home_widget.action.LAUNCH"
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or
            Intent.FLAG_ACTIVITY_SINGLE_TOP
    }
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    return PendingIntent.getActivity(context, requestCode, intent, flags)
}
