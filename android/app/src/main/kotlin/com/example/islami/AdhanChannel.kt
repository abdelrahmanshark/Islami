package com.example.islami

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Lets Flutter ask Android to (re)schedule or cancel Adhan alarms after it
 * saves the Adhan schedule in SharedPreferences.
 */
object AdhanChannel {
    private const val CHANNEL_NAME = "com.example.islami/adhan"

    /** Attaches the Adhan scheduling methods to [flutterEngine]. */
    fun register(flutterEngine: FlutterEngine, context: Context) {
        val appContext = context.applicationContext
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "reschedule" -> {
                    AdhanScheduler.reschedule(appContext)
                    result.success(null)
                }

                "cancelAll" -> {
                    AdhanScheduler.cancelAll(appContext)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
