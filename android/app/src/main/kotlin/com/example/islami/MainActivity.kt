package com.example.islami

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val STORAGE_CHANNEL = "com.example.islami/quran_storage"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableBytes" -> {
                    try {
                        result.success(QuranStorageHelper.getAvailableBytes())
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", e.message, null)
                    }
                }

                "mediaExists" -> {
                    val uri = call.argument<String>("uri")
                    if (uri.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "uri is required", null)
                        return@setMethodCallHandler
                    }
                    result.success(QuranStorageHelper.mediaExists(this, uri))
                }

                "deleteMedia" -> {
                    val uri = call.argument<String>("uri")
                    if (uri.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "uri is required", null)
                        return@setMethodCallHandler
                    }
                    result.success(QuranStorageHelper.deleteMedia(this, uri))
                }

                "saveAudioFromPath" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val displayName = call.argument<String>("displayName")
                    val relativePath = call.argument<String>("relativePath")
                    if (sourcePath.isNullOrBlank() ||
                        displayName.isNullOrBlank() ||
                        relativePath.isNullOrBlank()
                    ) {
                        result.error(
                            "INVALID_ARGS",
                            "sourcePath, displayName, and relativePath are required",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = QuranStorageHelper.saveAudioFromPath(
                            this,
                            sourcePath,
                            displayName,
                            relativePath,
                        )
                        if (uri == null) {
                            result.error(
                                "SAVE_FAILED",
                                "Could not save audio to shared storage",
                                null,
                            )
                        } else {
                            result.success(uri)
                        }
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
