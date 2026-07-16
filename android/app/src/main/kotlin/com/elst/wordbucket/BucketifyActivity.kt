package com.elst.wordbucket

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class BucketifyActivity : FlutterActivity() {
    private val channelName = "wordbucket/intent"
    private var channel: MethodChannel? = null
    private var selectedWord: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        selectedWord = extractSelectedWord(intent)
        super.onCreate(savedInstanceState)

        if (selectedWord == null) finish()
    }

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun getDartEntrypointArgs(): List<String> = listOf("bucketify")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialWord" -> result.success(selectedWord)
                    "finishBucketify" -> {
                        result.success(null)
                        finish()
                    }
                    else -> result.notImplemented()
                }
            }
        }
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
