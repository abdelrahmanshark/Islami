package com.example.islami

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONArray

/**
 * Schedules Adhan alarms from the list Flutter saves in SharedPreferences.
 * Flutter decides the prayer times; Android only fires them on time.
 */
object AdhanScheduler {
    const val ACTION_ADHAN = "com.example.islami.ADHAN_ALARM"
    const val EXTRA_PRAYER_NAME = "prayerName"

    private const val TAG = "AdhanScheduler"

    // Keys written by the Dart shared_preferences plugin (it adds the "flutter." prefix).
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val KEY_SCHEDULE = "flutter.adhanSchedule"
    private const val KEY_AZAN_ENABLED = "flutter.azanEnabled"

    private const val BASE_REQUEST_CODE = 1000
    private const val MAX_ALARMS = 60

    /** True when the user has Adhan sound turned on (defaults to on). */
    fun isAdhanEnabled(context: Context): Boolean {
        return context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_AZAN_ENABLED, true)
    }

    /** Cancels old alarms, then schedules every future entry in the saved list. */
    fun reschedule(context: Context) {
        cancelAll(context)
        if (!isAdhanEnabled(context)) return

        val raw = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .getString(KEY_SCHEDULE, null) ?: return

        val entries = try {
            JSONArray(raw)
        } catch (e: Exception) {
            Log.w(TAG, "Invalid adhan schedule: ${e.message}")
            return
        }

        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val now = System.currentTimeMillis()
        var scheduledCount = 0

        for (i in 0 until entries.length()) {
            if (scheduledCount >= MAX_ALARMS) break

            val entry = entries.optJSONObject(i) ?: continue
            val timeMillis = entry.optLong("time", 0L)
            val prayerName = entry.optString("name", "")
            if (timeMillis <= now) continue

            scheduleOne(
                context,
                alarmManager,
                BASE_REQUEST_CODE + scheduledCount,
                timeMillis,
                prayerName,
            )
            scheduledCount++
        }

        Log.d(TAG, "Scheduled $scheduledCount adhan alarms")
    }

    /** Cancels every Adhan alarm scheduled by [reschedule]. */
    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return

        for (index in 0 until MAX_ALARMS) {
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                BASE_REQUEST_CODE + index,
                alarmIntent(context, null),
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        }
    }

    /** Schedules one alarm; uses an exact alarm clock when the user allows it. */
    private fun scheduleOne(
        context: Context,
        alarmManager: AlarmManager,
        requestCode: Int,
        timeMillis: Long,
        prayerName: String,
    ) {
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            alarmIntent(context, prayerName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        try {
            if (canScheduleExactAlarms(alarmManager)) {
                val alarmInfo = AlarmManager.AlarmClockInfo(timeMillis, launchAppIntent(context))
                alarmManager.setAlarmClock(alarmInfo, pendingIntent)
            } else {
                // Without exact-alarm access Android may delay this by a few minutes.
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Exact alarm refused, using inexact alarm: ${e.message}")
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
        }
    }

    /** True when exact alarms are allowed (always true before Android 12). */
    private fun canScheduleExactAlarms(alarmManager: AlarmManager): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager.canScheduleExactAlarms()
    }

    /** Broadcast intent delivered to [AdhanAlarmReceiver] when an alarm fires. */
    private fun alarmIntent(context: Context, prayerName: String?): Intent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java)
        intent.action = ACTION_ADHAN
        if (prayerName != null) {
            intent.putExtra(EXTRA_PRAYER_NAME, prayerName)
        }
        return intent
    }

    /** Opens the app when the user taps the alarm shown by the system clock UI. */
    fun launchAppIntent(context: Context): PendingIntent? {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return null
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
