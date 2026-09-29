package com.example.islami

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes hardware sensor availability checks to Flutter.
 * Used by the Qibla screen before starting the location flow.
 */
object DeviceSensorChannel {
    const val CHANNEL_NAME = "com.example.islami/device_sensors"

    /** Attaches sensor checks to [flutterEngine] using [context]. */
    fun register(flutterEngine: FlutterEngine, context: Context) {
        val appContext = context.applicationContext
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasMagnetometer" -> {
                    val sensorManager =
                        appContext.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
                    val magnetometer = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
                    result.success(magnetometer != null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
