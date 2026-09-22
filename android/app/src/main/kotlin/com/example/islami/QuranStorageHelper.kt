package com.example.islami

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream

/**
 * Native helpers for shared-storage audio via MediaStore and free-space checks.
 * Does not use MANAGE_EXTERNAL_STORAGE.
 */
object QuranStorageHelper {

    /** Relative folder under Music for Quran MP3 files. */
    const val QURAN_AUDIO_RELATIVE_PATH = "Music/Islami/Quran"

    /** Returns free bytes on shared external storage. */
    fun getAvailableBytes(): Long {
        val path = Environment.getExternalStorageDirectory()
        val stat = StatFs(path.path)
        return stat.availableBlocksLong * stat.blockSizeLong
    }

    /** True when the MediaStore content URI still resolves to a readable file. */
    fun mediaExists(context: Context, uriString: String): Boolean {
        val uri = Uri.parse(uriString)
        return try {
            context.contentResolver.openAssetFileDescriptor(uri, "r")?.use {
                true
            } ?: false
        } catch (_: Exception) {
            false
        }
    }

    /** Deletes a MediaStore entry owned by this app. Returns true when deleted. */
    fun deleteMedia(context: Context, uriString: String): Boolean {
        val uri = Uri.parse(uriString)
        return try {
            val deleted = context.contentResolver.delete(uri, null, null)
            deleted > 0
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Copies [sourcePath] into shared Music storage under [relativePath].
     * Returns the MediaStore content URI string, or null on failure.
     */
    fun saveAudioFromPath(
        context: Context,
        sourcePath: String,
        displayName: String,
        relativePath: String,
    ): String? {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists() || !sourceFile.isFile) {
            return null
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveAudioViaMediaStoreQ(context, sourceFile, displayName, relativePath)
        } else {
            saveAudioViaLegacyFile(context, sourceFile, displayName, relativePath)
        }
    }

    /** MediaStore insert for Android 10+ (survives app uninstall). */
    private fun saveAudioViaMediaStoreQ(
        context: Context,
        sourceFile: File,
        displayName: String,
        relativePath: String,
    ): String? {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/mpeg")
            put(MediaStore.Audio.Media.RELATIVE_PATH, relativePath)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }

        val collection = MediaStore.Audio.Media.getContentUri(
            MediaStore.VOLUME_EXTERNAL_PRIMARY,
        )
        val itemUri = resolver.insert(collection, values) ?: return null

        return try {
            resolver.openOutputStream(itemUri)?.use { output ->
                FileInputStream(sourceFile).use { input ->
                    input.copyTo(output)
                }
            } ?: run {
                resolver.delete(itemUri, null, null)
                return null
            }

            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(itemUri, values, null, null)
            itemUri.toString()
        } catch (_: Exception) {
            try {
                resolver.delete(itemUri, null, null)
            } catch (_: Exception) {
                // Ignore cleanup failure.
            }
            null
        }
    }

    /** Legacy write under public Music for API 28 and below. */
    private fun saveAudioViaLegacyFile(
        context: Context,
        sourceFile: File,
        displayName: String,
        relativePath: String,
    ): String? {
        return try {
            // relativePath looks like Music/Islami/Quran/ReciterName
            val pathWithoutMusic = relativePath
                .removePrefix("Music/")
                .removePrefix("Music")
            val musicRoot =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
            val targetDir = File(musicRoot, pathWithoutMusic)
            if (!targetDir.exists() && !targetDir.mkdirs()) {
                return null
            }

            val targetFile = File(targetDir, displayName)
            sourceFile.copyTo(targetFile, overwrite = true)

            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
                put(MediaStore.Audio.Media.MIME_TYPE, "audio/mpeg")
                put(MediaStore.Audio.Media.DATA, targetFile.absolutePath)
                put(MediaStore.Audio.Media.TITLE, displayName.removeSuffix(".mp3"))
            }

            val itemUri = context.contentResolver.insert(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                values,
            )
            itemUri?.toString() ?: targetFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    /** MediaStore collection used for shared Quran audio files. */
    fun audioCollectionUri(): Uri {
        return MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
    }
}
