package com.example.islami

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log

/**
 * Foreground service that plays the Adhan asset while the app is closed.
 *
 * Call behavior matches the old Dart AdhanPlayer:
 * - During a call: no Adhan, only a "حان وقت صلاة ..." notification.
 * - A call (or any app taking audio focus) stops the Adhan and it never resumes.
 */
class AdhanPlaybackService : Service(), AudioManager.OnAudioFocusChangeListener {

    private var mediaPlayer: MediaPlayer? = null
    private var focusRequest: AudioFocusRequest? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private val stopRunnable = Runnable { stopAdhan() }

    private val audioAttributes: AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopAdhan()
            return START_NOT_STICKY
        }

        val prayerName = intent?.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME) ?: ""
        startInForeground(prayerName)

        // A new Adhan replaces anything still playing.
        releasePlayer()
        acquireWakeLock()

        if (isPhoneCallActive() || !requestAudioFocus() || !startPlayer()) {
            showPrayerTimeNotification(this, prayerName)
            stopAdhan()
            return START_NOT_STICKY
        }

        handler.removeCallbacks(stopRunnable)
        handler.postDelayed(stopRunnable, MAX_PLAY_MILLIS)
        return START_NOT_STICKY
    }

    override fun onAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> stopAdhan()

            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK ->
                mediaPlayer?.setVolume(DUCK_VOLUME, DUCK_VOLUME)

            AudioManager.AUDIOFOCUS_GAIN -> mediaPlayer?.setVolume(1f, 1f)
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(stopRunnable)
        releasePlayer()
        releaseWakeLock()
        super.onDestroy()
    }

    /** Shows the ongoing Adhan notification with a stop button. */
    private fun startInForeground(prayerName: String) {
        createNotificationChannels(this)

        val stopIntent = PendingIntent.getService(
            this,
            0,
            Intent(this, AdhanPlaybackService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stopAction = Notification.Action.Builder(
            Icon.createWithResource(this, R.mipmap.launcher_icon),
            "إيقاف الأذان",
            stopIntent,
        ).build()

        val notification = notificationBuilder(this, PLAYBACK_CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("إسلامي")
            .setContentText("حان وقت صلاة $prayerName")
            .setContentIntent(AdhanScheduler.launchAppIntent(this))
            .setDeleteIntent(stopIntent)
            .setOngoing(true)
            .addAction(stopAction)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                PLAYBACK_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(PLAYBACK_NOTIFICATION_ID, notification)
        }
    }

    /** True when the device is ringing or in a phone / VoIP call. */
    private fun isPhoneCallActive(): Boolean {
        val audioManager = getSystemService(AudioManager::class.java) ?: return false
        val mode = audioManager.mode
        return mode == AudioManager.MODE_IN_CALL ||
            mode == AudioManager.MODE_IN_COMMUNICATION ||
            mode == AudioManager.MODE_RINGTONE
    }

    /** Requests temporary audio focus so other audio pauses during the Adhan. */
    private fun requestAudioFocus(): Boolean {
        val audioManager = getSystemService(AudioManager::class.java) ?: return false

        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(audioAttributes)
                .setOnAudioFocusChangeListener(this, handler)
                .build()
            focusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                this,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
        return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    /** Gives audio focus back to other apps. */
    private fun abandonAudioFocus() {
        val audioManager = getSystemService(AudioManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(this)
        }
    }

    /** Starts playing the bundled Flutter Adhan asset. Returns false on failure. */
    private fun startPlayer(): Boolean {
        return try {
            val player = MediaPlayer()
            player.setAudioAttributes(audioAttributes)
            assets.openFd(ADHAN_ASSET_PATH).use { file ->
                player.setDataSource(file.fileDescriptor, file.startOffset, file.length)
            }
            player.setOnPreparedListener { it.start() }
            player.setOnCompletionListener { stopAdhan() }
            player.setOnErrorListener { _, what, extra ->
                Log.e(TAG, "MediaPlayer error what=$what extra=$extra")
                stopAdhan()
                true
            }
            mediaPlayer = player
            player.prepareAsync()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not start Adhan: ${e.message}")
            releasePlayer()
            false
        }
    }

    /** Stops playback, removes the notification, and ends the service. */
    private fun stopAdhan() {
        handler.removeCallbacks(stopRunnable)
        releasePlayer()
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    /** Releases the player and its audio focus. */
    private fun releasePlayer() {
        mediaPlayer?.release()
        mediaPlayer = null
        abandonAudioFocus()
    }

    /** Keeps the CPU awake for the whole Adhan (auto-released after the max time). */
    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val powerManager = getSystemService(PowerManager::class.java) ?: return
        val lock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "islami:adhan")
        lock.acquire(MAX_PLAY_MILLIS)
        wakeLock = lock
    }

    /** Releases the playback wake lock. */
    private fun releaseWakeLock() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        wakeLock = null
    }

    companion object {
        private const val TAG = "AdhanPlaybackService"
        private const val ACTION_STOP = "com.example.islami.ADHAN_STOP"

        // Must match AppAssets.azan in Dart ("flutter_assets/" is where Flutter packs assets).
        private const val ADHAN_ASSET_PATH = "flutter_assets/assets/audio/azan.mp3"

        private const val MAX_PLAY_MILLIS = 10 * 60 * 1000L
        private const val DUCK_VOLUME = 0.3f

        private const val PLAYBACK_CHANNEL_ID = "adhan_playback_v1"
        private const val PLAYBACK_NOTIFICATION_ID = 311

        // Same channel / id the old Dart PrayerTimeNotificationService used.
        private const val PRAYER_ALERT_CHANNEL_ID = "prayer_time_alerts_v1"
        private const val PRAYER_ALERT_NOTIFICATION_ID = 310

        /** Starts the service; falls back to a notification if Android refuses. */
        fun start(context: Context, prayerName: String) {
            val intent = Intent(context, AdhanPlaybackService::class.java)
            intent.putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, prayerName)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Could not start Adhan service: ${e.message}")
                showPrayerTimeNotification(context, prayerName)
            }
        }

        /** Shows: حان وقت صلاة [prayerName] (used when the Adhan cannot play). */
        fun showPrayerTimeNotification(context: Context, prayerName: String) {
            createNotificationChannels(context)
            val notification = notificationBuilder(context, PRAYER_ALERT_CHANNEL_ID)
                .setSmallIcon(R.mipmap.launcher_icon)
                .setContentTitle("إسلامي")
                .setContentText("حان وقت صلاة $prayerName")
                .setContentIntent(AdhanScheduler.launchAppIntent(context))
                .setAutoCancel(true)
                .build()
            context.getSystemService(NotificationManager::class.java)
                ?.notify(PRAYER_ALERT_NOTIFICATION_ID, notification)
        }

        /** Creates the Adhan notification channels (no-op when they exist). */
        private fun createNotificationChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java) ?: return

            val playbackChannel = NotificationChannel(
                PLAYBACK_CHANNEL_ID,
                "الأذان",
                NotificationManager.IMPORTANCE_DEFAULT,
            )
            playbackChannel.description = "إشعار أثناء تشغيل الأذان"
            playbackChannel.setSound(null, null)
            playbackChannel.enableVibration(false)
            manager.createNotificationChannel(playbackChannel)

            val alertChannel = NotificationChannel(
                PRAYER_ALERT_CHANNEL_ID,
                "تنبيهات الصلاة",
                NotificationManager.IMPORTANCE_HIGH,
            )
            alertChannel.description = "إشعار عند حلول وقت الصلاة أثناء المكالمة"
            manager.createNotificationChannel(alertChannel)
        }

        /** Notification.Builder that works before and after Android 8 channels. */
        private fun notificationBuilder(context: Context, channelId: String): Notification.Builder {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, channelId)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
        }
    }
}
