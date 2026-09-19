package com.example.islami

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Locale
import java.util.concurrent.TimeUnit

/** Android home screen widget that shows salah times and next prayer. */
class PrayerTimesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget).apply {
                setTextViewText(
                    R.id.widget_fajr,
                    formatPrayerTime(widgetData.getString("fajr", "--")),
                )
                setTextViewText(
                    R.id.widget_dhuhr,
                    formatPrayerTime(widgetData.getString("dhuhr", "--")),
                )
                setTextViewText(
                    R.id.widget_asr,
                    formatPrayerTime(widgetData.getString("asr", "--")),
                )
                setTextViewText(
                    R.id.widget_maghrib,
                    formatPrayerTime(widgetData.getString("maghrib", "--")),
                )
                setTextViewText(
                    R.id.widget_isha,
                    formatPrayerTime(widgetData.getString("isha", "--")),
                )

                val nextName = widgetData.getString("next_prayer_name", "") ?: ""
                val nextTime = widgetData.getString("next_prayer_time", "") ?: ""
                setTextViewText(
                    R.id.widget_next_prayer_name,
                    nextName.ifEmpty { "--" },
                )
                setTextViewText(
                    R.id.widget_next_prayer_time,
                    nextTime.ifEmpty { "--" },
                )
                setTextViewText(
                    R.id.widget_remaining,
                    formatRemaining(widgetData),
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /** Puts ص/م on a second line so times stay readable in narrow columns. */
    private fun formatPrayerTime(raw: String?): String {
        val time = raw?.trim().orEmpty()
        if (time.isEmpty() || time == "--") {
            return "--"
        }
        val parts = time.split(" ")
        return if (parts.size >= 2) {
            "${parts[0]}\n${parts[1]}"
        } else {
            time
        }
    }

    /** Computes HH:MM from stored epoch, or falls back to saved remaining_hm. */
    private fun formatRemaining(widgetData: SharedPreferences): String {
        val epochRaw = widgetData.getString("next_prayer_epoch_ms", null)
        if (!epochRaw.isNullOrEmpty()) {
            val epochMs = epochRaw.toLongOrNull()
            if (epochMs != null) {
                val remainingMs = epochMs - System.currentTimeMillis()
                if (remainingMs <= 0) {
                    return "00:00"
                }
                val hours = TimeUnit.MILLISECONDS.toHours(remainingMs)
                val minutes = TimeUnit.MILLISECONDS.toMinutes(remainingMs) % 60
                return String.format(Locale.US, "%02d:%02d", hours, minutes)
            }
        }

        return widgetData.getString("remaining_hm", "--:--") ?: "--:--"
    }
}
