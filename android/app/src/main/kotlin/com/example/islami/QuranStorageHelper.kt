package com.example.islami

import android.content.ContentUris
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

    private val suraFileNameRegex = Regex("^sura_\\d{3}\\.mp3$", RegexOption.IGNORE_CASE)

    /** Returns free bytes on shared external storage. */
    fun getAvailableBytes(): Long {
        val path = Environment.getExternalStorageDirectory()
        val stat = StatFs(path.path)
        return stat.availableBlocksLong * stat.blockSizeLong
    }

    /** True when the MediaStore content URI still resolves to a readable file. */
    fun mediaExists(context: Context, uriString: String): Boolean {
        if (uriString.isBlank()) return false

        // Restored downloads may use a plain file path after reinstall.
        if (!uriString.startsWith("content://")) {
            return try {
                File(uriString.removePrefix("file://")).exists()
            } catch (_: Exception) {
                false
            }
        }

        val uri = Uri.parse(uriString)
        return try {
            context.contentResolver.openAssetFileDescriptor(uri, "r")?.use {
                true
            } ?: false
        } catch (_: Exception) {
            false
        }
    }

    /** Deletes a MediaStore entry or local file. Returns true when deleted. */
    fun deleteMedia(context: Context, uriString: String): Boolean {
        if (uriString.isBlank()) return false

        if (!uriString.startsWith("content://")) {
            return try {
                val file = File(uriString.removePrefix("file://"))
                file.exists() && file.delete()
            } catch (_: Exception) {
                false
            }
        }

        val uri = Uri.parse(uriString)
        return try {
            val deleted = context.contentResolver.delete(uri, null, null)
            deleted > 0
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Lists existing Quran MP3s under Music/Islami/Quran.
     * Used after reinstall when SharedPreferences metadata is empty.
     */
    fun listQuranAudioFiles(context: Context): List<Map<String, Any?>> {
        val byKey = linkedMapOf<String, Map<String, Any?>>()

        // Prefer MediaStore rows when readable.
        for (item in queryMediaStoreQuranAudio(context)) {
            val key = itemKey(item)
            if (key != null) {
                byKey[key] = item
            }
        }

        // Fallback: walk the public Music folder (same path user still has).
        for (item in listQuranAudioFromFileSystem()) {
            val key = itemKey(item) ?: continue
            if (!byKey.containsKey(key)) {
                byKey[key] = item
            }
        }

        return byKey.values.toList()
    }

    /** Finds one Quran MP3 by display name + relative folder path. */
    fun findQuranAudio(
        context: Context,
        displayName: String,
        relativePath: String,
    ): Map<String, Any?>? {
        val normalizedPath = relativePath.trimEnd('/')
        val fromStore = queryMediaStoreQuranAudio(context).firstOrNull { item ->
            item["displayName"] == displayName &&
                (item["relativePath"] as? String)?.trimEnd('/') == normalizedPath
        }
        if (fromStore != null) return fromStore

        return listQuranAudioFromFileSystem().firstOrNull { item ->
            item["displayName"] == displayName &&
                (item["relativePath"] as? String)?.trimEnd('/') == normalizedPath
        }
    }

    /** Queries MediaStore for audio under Music/Islami/Quran. */
    private fun queryMediaStoreQuranAudio(context: Context): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        val collection = audioCollectionUri()
        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            projection.add(MediaStore.Audio.Media.RELATIVE_PATH)
        } else {
            @Suppress("DEPRECATION")
            projection.add(MediaStore.Audio.Media.DATA)
        }

        val selection: String
        val selectionArgs: Array<String>
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            selection = "${MediaStore.Audio.Media.RELATIVE_PATH} LIKE ?"
            selectionArgs = arrayOf("$QURAN_AUDIO_RELATIVE_PATH/%")
        } else {
            @Suppress("DEPRECATION")
            selection = "${MediaStore.Audio.Media.DATA} LIKE ?"
            selectionArgs = arrayOf("%/$QURAN_AUDIO_RELATIVE_PATH/%")
        }

        try {
            context.contentResolver.query(
                collection,
                projection.toTypedArray(),
                selection,
                selectionArgs,
                null,
            )?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
                val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
                val dateCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
                val relativeCol = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    cursor.getColumnIndex(MediaStore.Audio.Media.RELATIVE_PATH)
                } else {
                    -1
                }
                @Suppress("DEPRECATION")
                val dataCol = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
                } else {
                    -1
                }

                while (cursor.moveToNext()) {
                    val displayName = cursor.getString(nameCol) ?: continue
                    if (!suraFileNameRegex.matches(displayName)) continue

                    val relativePath = if (relativeCol >= 0) {
                        cursor.getString(relativeCol)?.trimEnd('/') ?: continue
                    } else if (dataCol >= 0) {
                        relativePathFromAbsolute(cursor.getString(dataCol)) ?: continue
                    } else {
                        continue
                    }

                    if (!relativePath.startsWith(QURAN_AUDIO_RELATIVE_PATH)) continue

                    val id = cursor.getLong(idCol)
                    val contentUri = ContentUris.withAppendedId(collection, id)
                    results.add(
                        mapOf(
                            "uri" to contentUri.toString(),
                            "displayName" to displayName,
                            "relativePath" to relativePath,
                            "size" to cursor.getLong(sizeCol),
                            "dateAdded" to cursor.getLong(dateCol) * 1000L,
                        ),
                    )
                }
            }
        } catch (_: Exception) {
            // Permission or provider issues — filesystem fallback may still work.
        }

        return results
    }

    /** Walks Music/Islami/Quran on disk when MediaStore is empty or inaccessible. */
    private fun listQuranAudioFromFileSystem(): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        return try {
            val musicRoot =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
            val quranRoot = File(musicRoot, "Islami/Quran")
            if (!quranRoot.exists() || !quranRoot.isDirectory) {
                return results
            }

            val reciterDirs = quranRoot.listFiles() ?: return results
            for (reciterDir in reciterDirs) {
                if (!reciterDir.isDirectory) continue
                val files = reciterDir.listFiles() ?: continue
                for (file in files) {
                    if (!file.isFile || !suraFileNameRegex.matches(file.name)) continue
                    results.add(
                        mapOf(
                            "uri" to file.absolutePath,
                            "displayName" to file.name,
                            "relativePath" to "$QURAN_AUDIO_RELATIVE_PATH/${reciterDir.name}",
                            "size" to file.length(),
                            "dateAdded" to file.lastModified(),
                        ),
                    )
                }
            }
            results
        } catch (_: Exception) {
            results
        }
    }

    /** Builds Music/Islami/Quran/{reciter} from a legacy absolute DATA path. */
    private fun relativePathFromAbsolute(absolutePath: String?): String? {
        if (absolutePath.isNullOrBlank()) return null
        val marker = "/$QURAN_AUDIO_RELATIVE_PATH/"
        val index = absolutePath.indexOf(marker)
        if (index < 0) return null
        val after = absolutePath.substring(index + 1)
        val parent = File(after).parent ?: return null
        return parent.replace('\\', '/')
    }

    /** Unique key for de-duplicating MediaStore + filesystem results. */
    private fun itemKey(item: Map<String, Any?>): String? {
        val displayName = item["displayName"] as? String ?: return null
        val relativePath = (item["relativePath"] as? String)?.trimEnd('/') ?: return null
        return "$relativePath/$displayName"
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
