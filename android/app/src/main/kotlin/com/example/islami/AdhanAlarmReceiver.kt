package com.example.islami

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager

/**
 * Starts Adhan playback when an alarm fires, and restores alarms after
 * reboot, app update, or an exact-alarm permission change.
 */
class AdhanAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == AdhanScheduler.ACTION_ADHAN) {
            // Keeps the CPU awake until the playback service takes its own wake lock.
            val powerManager = context.getSystemService(PowerManager::class.java)
            powerManager
                ?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "islami:adhanStart")
                ?.acquire(START_WAKE_LOCK_MILLIS)

            if (AdhanScheduler.isAdhanEnabled(context)) {
                val prayerName = intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME) ?: ""
                AdhanPlaybackService.start(context, prayerName)
            }
        }

        // Re-read the schedule: Flutter may have refreshed it from a background isolate.
        AdhanScheduler.reschedule(context)
    }

    companion object {
        private const val START_WAKE_LOCK_MILLIS = 30_000L
    }
}
