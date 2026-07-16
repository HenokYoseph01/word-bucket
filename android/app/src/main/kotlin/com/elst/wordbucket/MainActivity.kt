package com.elst.wordbucket

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "wordbucket/intent"
    private var channel: MethodChannel? = null
    private var pendingWord: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingWord = extractSelectedWord(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialWord" -> {
                        result.success(pendingWord)
                        pendingWord = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val word = extractSelectedWord(intent) ?: return
        pendingWord = word
        channel?.invokeMethod("defineWord", word)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.setMethodCallHandler(null)
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun extractSelectedWord(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_PROCESS_TEXT) return null

        return intent
            .getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
            ?.toString()
            ?.trim()
            ?.split(Regex("\\s+"))
            ?.firstOrNull()
            ?.trim { character -> !character.isLetter() && character != '\'' && character != '-' }
            ?.takeIf { it.isNotBlank() }
    }
}
