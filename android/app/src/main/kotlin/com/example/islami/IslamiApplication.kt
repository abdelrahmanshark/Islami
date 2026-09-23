package com.example.islami

import android.app.Application
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.engine.FlutterEngine

/**
 * Registers Quran storage MethodChannel on the download foreground-service engine.
 */
class IslamiApplication : Application() {
    private val downloadEngineListener = object : FlutterForegroundTaskLifecycleListener {
        override fun onEngineCreate(flutterEngine: FlutterEngine?) {
            if (flutterEngine == null) return
            QuranStorageChannel.register(flutterEngine, this@IslamiApplication)
        }

        override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}

        override fun onTaskRepeatEvent() {}

        override fun onTaskDestroy() {}

        override fun onEngineWillDestroy() {}
    }

    override fun onCreate() {
        super.onCreate()
        FlutterForegroundTaskPlugin.addTaskLifecycleListener(downloadEngineListener)
    }
}
