package com.example.islami

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the shared Quran MediaStore MethodChannel on any FlutterEngine.
 * Used by MainActivity and the download foreground-service isolate.
 */
object QuranStorageChannel {
    const val CHANNEL_NAME = "com.example.islami/quran_storage"

    /** Attaches storage helpers to [flutterEngine] using [context]. */
    fun register(flutterEngine: FlutterEngine, context: Context) {
        val appContext = context.applicationContext
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
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
                    result.success(QuranStorageHelper.mediaExists(appContext, uri))
                }

                "deleteMedia" -> {
                    val uri = call.argument<String>("uri")
                    if (uri.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "uri is required", null)
                        return@setMethodCallHandler
                    }
                    result.success(QuranStorageHelper.deleteMedia(appContext, uri))
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
                            appContext,
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

                "listQuranAudio" -> {
                    try {
                        result.success(QuranStorageHelper.listQuranAudioFiles(appContext))
                    } catch (e: Exception) {
                        result.error("LIST_ERROR", e.message, null)
                    }
                }

                "findQuranAudio" -> {
                    val displayName = call.argument<String>("displayName")
                    val relativePath = call.argument<String>("relativePath")
                    if (displayName.isNullOrBlank() || relativePath.isNullOrBlank()) {
                        result.error(
                            "INVALID_ARGS",
                            "displayName and relativePath are required",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(
                            QuranStorageHelper.findQuranAudio(
                                appContext,
                                displayName,
                                relativePath,
                            ),
                        )
                    } catch (e: Exception) {
                        result.error("FIND_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
