package com.mybudget.my_budget

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth (biometric prompt).
class MainActivity : FlutterFragmentActivity() {
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Financial data: hide the app from the recents thumbnail and block
        // screenshots / screen recording of its window.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }

    // System notification-sound picker (no plugin): returns
    // {uri: String, title: String}; uri "" = silent, "default" = system default;
    // null when the user cancelled.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "pick") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("busy", "Picker already open", null)
                    return@setMethodCallHandler
                }
                val current = call.argument<String>("current")
                val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                    putExtra(
                        RingtoneManager.EXTRA_RINGTONE_TYPE,
                        RingtoneManager.TYPE_NOTIFICATION,
                    )
                    putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                    putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, true)
                    putExtra(
                        RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI,
                        Settings.System.DEFAULT_NOTIFICATION_URI,
                    )
                    val existing: Uri? = when {
                        current == null || current == "default" ->
                            Settings.System.DEFAULT_NOTIFICATION_URI
                        current.isEmpty() -> null
                        else -> Uri.parse(current)
                    }
                    putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, existing)
                }
                pendingResult = result
                @Suppress("DEPRECATION")
                startActivityForResult(intent, REQUEST_RINGTONE)
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_RINGTONE) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingResult
        pendingResult = null
        if (result == null) return
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }
        val uri: Uri? = if (Build.VERSION.SDK_INT >= 33) {
            data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }
        when {
            uri == null -> result.success(mapOf("uri" to "", "title" to ""))
            uri == Settings.System.DEFAULT_NOTIFICATION_URI ->
                result.success(mapOf("uri" to "default", "title" to ""))
            else -> {
                val title = try {
                    RingtoneManager.getRingtone(this, uri)?.getTitle(this) ?: ""
                } catch (e: Exception) {
                    ""
                }
                result.success(mapOf("uri" to uri.toString(), "title" to title))
            }
        }
    }

    companion object {
        private const val CHANNEL = "mybudget/ringtone"
        private const val REQUEST_RINGTONE = 4711
    }
}
