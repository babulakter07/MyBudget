package com.mybudget.my_budget

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.security.KeyStore
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Backs `ChannelBackupFolderGateway` in Dart: lasting access to a user-chosen
 * folder (Storage Access Framework) and the backup password, encrypted with a
 * key that never leaves the Android Keystore.
 */
class BackupFolderChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private var pendingPick: MethodChannel.Result? = null

    // File providers can be slow, so all I/O runs off the UI thread.
    private val io = Executors.newSingleThreadExecutor()

    init {
        MethodChannel(messenger, "mybudget/backup_folder")
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "listFiles" -> background(result) { children(folder(call)).keys.toList() }
            "writeFile" -> background(result) {
                write(folder(call), call.argument("name")!!, File(call.argument<String>("source")!!))
                null
            }
            "deleteFile" -> background(result) {
                val tree = folder(call)
                children(tree)[call.argument<String>("name")!!]?.let { id ->
                    DocumentsContract.deleteDocument(
                        activity.contentResolver,
                        DocumentsContract.buildDocumentUriUsingTree(tree, id),
                    )
                }
                null
            }
            "releaseFolder" -> background(result) {
                activity.contentResolver.releasePersistableUriPermission(folder(call), ACCESS)
                null
            }
            "saveSecret" -> background(result) {
                saveSecret(call.argument("value")!!)
                null
            }
            "readSecret" -> background(result) { readSecret() }
            "clearSecret" -> background(result) {
                secrets().edit().remove(SECRET).apply()
                null
            }
            else -> result.notImplemented()
        }
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                activity.runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                activity.runOnUiThread {
                    result.error("backup_folder", e.message ?: e.javaClass.simpleName, null)
                }
            }
        }
    }

    private fun folder(call: MethodCall): Uri = Uri.parse(call.argument<String>("folder")!!)

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "Picker already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            .addFlags(ACCESS or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        pendingPick = result
        try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, REQUEST_FOLDER)
        } catch (e: ActivityNotFoundException) {
            pendingPick = null
            result.error("backup_folder", "This phone has no folder picker", null)
        }
    }

    /** Returns true when the result belonged to the folder picker. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_FOLDER) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val tree = data?.data
        if (resultCode != Activity.RESULT_OK || tree == null) {
            result.success(null)
            return true
        }
        try {
            activity.contentResolver.takePersistableUriPermission(tree, ACCESS)
            result.success(mapOf("uri" to tree.toString(), "name" to folderName(tree)))
        } catch (e: SecurityException) {
            result.error("backup_folder", "Android did not allow access to that folder", null)
        }
        return true
    }

    // "primary:Documents/MyBudget" -> "Documents/MyBudget".
    private fun folderName(tree: Uri): String {
        val id = DocumentsContract.getTreeDocumentId(tree)
        return id.substringAfter(':').ifEmpty { id }
    }

    /** Display name -> document id for everything directly inside [tree]. */
    private fun children(tree: Uri): Map<String, String> {
        val uri = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        )
        val cursor = activity.contentResolver.query(uri, columns, null, null, null)
            ?: throw IOException("The backup folder cannot be opened")
        return cursor.use {
            val out = LinkedHashMap<String, String>()
            while (it.moveToNext()) out[it.getString(1)] = it.getString(0)
            out
        }
    }

    private fun write(tree: Uri, name: String, source: File) {
        val resolver = activity.contentResolver
        val parent = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val target = DocumentsContract.createDocument(resolver, parent, "application/json", name)
            ?: throw IOException("Could not create a file in the backup folder")
        try {
            val output = resolver.openOutputStream(target, "w")
                ?: throw IOException("Could not write to the backup folder")
            output.use { out -> source.inputStream().use { it.copyTo(out) } }
        } catch (e: Exception) {
            // Never leave a half-written backup behind.
            try {
                DocumentsContract.deleteDocument(resolver, target)
            } catch (_: Exception) {
            }
            throw e
        }
    }

    private fun secrets() = activity.getSharedPreferences("mybudget_secure", Context.MODE_PRIVATE)

    private fun key(): SecretKey {
        val store = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (store.getKey(KEY_ALIAS, null) as SecretKey?)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private fun saveSecret(value: String) {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val stored = encode(cipher.iv) + ":" + encode(encrypted)
        if (!secrets().edit().putString(SECRET, stored).commit()) {
            throw IOException("Could not save the backup password")
        }
    }

    private fun readSecret(): String? {
        val parts = secrets().getString(SECRET, null)?.split(":") ?: return null
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, decode(parts[0])))
        return String(cipher.doFinal(decode(parts[1])), Charsets.UTF_8)
    }

    private fun encode(bytes: ByteArray) = Base64.encodeToString(bytes, Base64.NO_WRAP)

    private fun decode(text: String) = Base64.decode(text, Base64.NO_WRAP)

    private companion object {
        const val REQUEST_FOLDER = 4712
        const val ACCESS =
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        const val KEYSTORE = "AndroidKeyStore"
        const val KEY_ALIAS = "mybudget_backup_password"
        const val SECRET = "backup_password"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
    }
}
