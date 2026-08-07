package com.elst.wordbucket

import android.content.Intent
import android.content.ClipboardManager
import android.os.Bundle
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class BucketifyActivity : FlutterActivity() {
    private val channelName = "wordbucket/intent"
    private var channel: MethodChannel? = null
    private var selectedWord: String? = null
    private var clipboardHandled = false
    private var wordDelivered = false

    override fun onCreate(savedInstanceState: Bundle?) {
        selectedWord = extractSelectedWord(intent)
        super.onCreate(savedInstanceState)

        if (selectedWord == null && intent?.action != ACTION_BUCKETIFY_CLIPBOARD) finish()
    }

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun getDartEntrypointArgs(): List<String> = listOf("bucketify")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialWord" -> {
                        if (selectedWord != null) wordDelivered = true
                        result.success(selectedWord)
                    }
                    "finishBucketify" -> {
                        val savedWord = call.arguments as? String
                        if (!savedWord.isNullOrBlank()) {
                            Toast.makeText(
                                this@BucketifyActivity,
                                getString(R.string.word_saved, savedWord),
                                Toast.LENGTH_SHORT,
                            ).show()
                        }
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

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (
            hasFocus &&
            intent?.action == ACTION_BUCKETIFY_CLIPBOARD &&
            !clipboardHandled
        ) {
            clipboardHandled = true
            readClipboardWord()
        }
    }

    private fun readClipboardWord() {
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        val clipboardText = if (clip != null && clip.itemCount > 0) {
            clip.getItemAt(0).coerceToText(this)
        } else {
            null
        }
        selectedWord = extractFirstWord(clipboardText)

        if (selectedWord == null) {
            Toast.makeText(this, R.string.copy_word_first, Toast.LENGTH_LONG).show()
            finish()
            return
        }

        window.decorView.postDelayed({
            if (!wordDelivered && !isFinishing) {
                wordDelivered = true
                channel?.invokeMethod("defineWord", selectedWord)
            }
        }, 250)
    }

    private fun extractSelectedWord(intent: Intent?): String? {
        val incomingText = when (intent?.action) {
            Intent.ACTION_PROCESS_TEXT -> intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
            Intent.ACTION_SEND -> intent.getCharSequenceExtra(Intent.EXTRA_TEXT)
            else -> null
        }

        return extractFirstWord(incomingText)
    }

    private fun extractFirstWord(text: CharSequence?): String? {
        return text
            ?.toString()
            ?.trim()
            ?.split(Regex("\\s+"))
            ?.firstOrNull()
            ?.trim { character -> !character.isLetter() && character != '\'' && character != '-' }
            ?.takeIf { it.isNotBlank() }
    }

    companion object {
        const val ACTION_BUCKETIFY_CLIPBOARD =
            "com.elst.wordbucket.action.BUCKETIFY_CLIPBOARD"
    }
}
