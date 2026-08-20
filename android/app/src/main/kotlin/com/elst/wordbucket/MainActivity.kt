package com.elst.wordbucket

import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Intent
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "wordbucket/quick_tile",
        ).setMethodCallHandler { call, result ->
            if (call.method != "requestAddQuickTile") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                result.success("manual")
                return@setMethodCallHandler
            }

            val statusBarManager = getSystemService(StatusBarManager::class.java)
            statusBarManager.requestAddTileService(
                ComponentName(this, QuickBucketifyTileService::class.java),
                getString(R.string.quick_bucketify_tile),
                Icon.createWithResource(this, R.drawable.ic_quick_bucketify),
                mainExecutor,
            ) { status ->
                val outcome = when (status) {
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED -> "added"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED -> "already_added"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED -> "not_added"
                    else -> "error"
                }
                result.success(outcome)
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "wordbucket/reading_companion",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" -> result.success(Settings.canDrawOverlays(this))
                "requestOverlayPermission" -> {
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                    result.success(null)
                }
                "isReadingCompanionActive" -> {
                    result.success(ReadingCompanionService.isActive(this))
                }
                "startReadingCompanion" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        result.error("permission_denied", "Overlay permission is required.", null)
                        return@setMethodCallHandler
                    }
                    val color = (call.argument<Number>("color"))?.toInt()
                        ?: 0xFF203A43.toInt()
                    ReadingCompanionService.updateActiveColor(this, color)
                    val serviceIntent = Intent(this, ReadingCompanionService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "stopReadingCompanion" -> {
                    stopService(Intent(this, ReadingCompanionService::class.java))
                    result.success(true)
                }
                "updateReadingCompanionColor" -> {
                    val color = (call.argument<Number>("color"))?.toInt()
                        ?: 0xFF203A43.toInt()
                    ReadingCompanionService.updateActiveColor(this, color)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
