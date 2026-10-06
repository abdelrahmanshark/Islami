package com.example.islami

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import java.util.Locale
import java.util.concurrent.TimeUnit

/** Android home screen widget that shows salah times and next prayer. */
class PrayerTimesWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_REFRESH,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            -> {
                refreshAllWidgets(context)
            }
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        refreshAllWidgets(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelRefreshAlarm(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val next = ensureNextPrayer(widgetData)
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

                setTextViewText(
                    R.id.widget_next_prayer_name,
                    next?.name?.ifEmpty { "--" } ?: "--",
                )
                setTextViewText(
                    R.id.widget_next_prayer_time,
                    next?.time?.ifEmpty { "--" } ?: "--",
                )
                bindCountdown(this, next?.epochMs)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        if (next != null && next.epochMs > System.currentTimeMillis()) {
            // Always refresh when the next prayer starts; on older APIs also tick each minute.
            val triggerAt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                next.epochMs + 1_000L
            } else {
                minOf(next.epochMs + 1_000L, System.currentTimeMillis() + 60_000L)
            }
            scheduleRefreshAlarm(context, triggerAt)
        } else {
            cancelRefreshAlarm(context)
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

    /** Binds a native Chronometer so countdown keeps running without Flutter. */
    private fun bindCountdown(views: RemoteViews, epochMs: Long?) {
        if (epochMs == null) {
            views.setChronometer(R.id.widget_remaining, SystemClock.elapsedRealtime(), null, false)
            views.setTextViewText(R.id.widget_remaining, "--:--")
            return
        }

        val remainingMs = epochMs - System.currentTimeMillis()
        if (remainingMs <= 0) {
            views.setChronometer(R.id.widget_remaining, SystemClock.elapsedRealtime(), null, false)
            views.setTextViewText(R.id.widget_remaining, "00:00")
            return
        }

        // Count-down Chronometer needs API 24+; older APIs show a static HH:MM:SS.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val base = SystemClock.elapsedRealtime() + remainingMs
            views.setChronometer(R.id.widget_remaining, base, null, true)
            views.setChronometerCountDown(R.id.widget_remaining, true)
        } else {
            views.setChronometer(R.id.widget_remaining, SystemClock.elapsedRealtime(), null, false)
            views.setTextViewText(R.id.widget_remaining, formatRemainingHms(remainingMs))
        }
    }

    /** Formats remaining millis as HH:MM:SS for pre-Nougat devices. */
    private fun formatRemainingHms(remainingMs: Long): String {
        val hours = TimeUnit.MILLISECONDS.toHours(remainingMs)
        val minutes = TimeUnit.MILLISECONDS.toMinutes(remainingMs) % 60
        val seconds = TimeUnit.MILLISECONDS.toSeconds(remainingMs) % 60
        return String.format(Locale.US, "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /**
     * Uses the stored next-prayer DateTime when still ahead; otherwise
     * recalculates from cached salah times (mirrors NextPrayerCalculator).
     */
    private fun ensureNextPrayer(widgetData: SharedPreferences): NextPrayerInfo? {
        val epochRaw = widgetData.getString("next_prayer_epoch_ms", null)
        val epochMs = epochRaw?.toLongOrNull()
        val nowMs = System.currentTimeMillis()

        if (epochMs != null && epochMs > nowMs) {
            return NextPrayerInfo(
                name = widgetData.getString("next_prayer_name", "") ?: "",
                time = widgetData.getString("next_prayer_time", "") ?: "",
                epochMs = epochMs,
            )
        }

        val recalculated = findNextPrayer(widgetData, nowMs) ?: return null
        widgetData.edit()
            .putString("next_prayer_name", recalculated.name)
            .putString("next_prayer_time", recalculated.time)
            .putString("next_prayer_epoch_ms", recalculated.epochMs.toString())
            .apply()
        return recalculated
    }

    /** Finds the next salah from cached widget times, or Fajr tomorrow after Isha. */
    private fun findNextPrayer(widgetData: SharedPreferences, nowMs: Long): NextPrayerInfo? {
        val calendar = Calendar.getInstance().apply { timeInMillis = nowMs }
        val prayers = listOf(
            "الفجر" to (widgetData.getString("fajr", "") ?: ""),
            "الظهر" to (widgetData.getString("dhuhr", "") ?: ""),
            "العصر" to (widgetData.getString("asr", "") ?: ""),
            "المغرب" to (widgetData.getString("maghrib", "") ?: ""),
            "العشاء" to (widgetData.getString("isha", "") ?: ""),
        )

        for ((name, timeText) in prayers) {
            val todayMs = toTodayEpochMs(timeText, calendar) ?: continue
            if (todayMs > nowMs) {
                return NextPrayerInfo(name = name, time = timeText, epochMs = todayMs)
            }
        }

        val fajrTime = prayers.firstOrNull()?.second.orEmpty()
        val fajrTodayMs = toTodayEpochMs(fajrTime, calendar) ?: return null
        return NextPrayerInfo(
            name = "الفجر",
            time = fajrTime,
            epochMs = fajrTodayMs + TimeUnit.DAYS.toMillis(1),
        )
    }

    /** Parses "h:mm ص/م" (or AM/PM) into today's epoch millis. */
    private fun toTodayEpochMs(time: String, now: Calendar): Long? {
        val parts = time.trim().split(" ")
        if (parts.isEmpty()) {
            return null
        }

        val timeParts = parts[0].split(":")
        if (timeParts.size < 2) {
            return null
        }

        var hour = timeParts[0].toIntOrNull() ?: return null
        val minute = timeParts[1].toIntOrNull() ?: return null

        if (parts.size >= 2) {
            val period = parts[1].uppercase(Locale.US)
            val isAm = period == "AM" || period == "ص"
            val isPm = period == "PM" || period == "م"
            if (isAm && hour == 12) {
                hour = 0
            } else if (isPm && hour != 12) {
                hour += 12
            }
        }

        return (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private fun refreshAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, PrayerTimesWidgetProvider::class.java),
        )
        if (ids.isEmpty()) {
            return
        }
        onUpdate(context, manager, ids, HomeWidgetPlugin.getData(context))
    }

    /** Schedules a one-shot native refresh (no Flutter process required). */
    private fun scheduleRefreshAlarm(context: Context, triggerAtMs: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = refreshPendingIntent(context)

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMs,
                    pendingIntent,
                )
            }
            else -> {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMs,
                    pendingIntent,
                )
            }
        }
    }

    private fun cancelRefreshAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(refreshPendingIntent(context))
    }

    private fun refreshPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, PrayerTimesWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, REQUEST_CODE_REFRESH, intent, flags)
    }

    private data class NextPrayerInfo(
        val name: String,
        val time: String,
        val epochMs: Long,
    )

    companion object {
        const val ACTION_REFRESH = "com.example.islami.PRAYER_WIDGET_REFRESH"
        private const val REQUEST_CODE_REFRESH = 4101
    }
}
