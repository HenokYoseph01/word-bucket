package com.elst.wordbucket

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import kotlin.math.hypot

class ReadingCompanionService : Service() {
    private lateinit var windowManager: WindowManager
    private var bubble: ImageView? = null
    private var removeTarget: ImageView? = null
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var draggingToRemove = false

    override fun onCreate() {
        super.onCreate()
        if (!Settings.canDrawOverlays(this)) {
            stopSelf()
            return
        }
        instance = this
        preferences().edit().putBoolean(KEY_ACTIVE, true).apply()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        showBubble()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopSelf()
            ACTION_UPDATE_COLOR -> updateColor(intent.getIntExtra(EXTRA_COLOR, defaultColor()))
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        bubble?.let { runCatching { windowManager.removeView(it) } }
        removeTarget?.let { runCatching { windowManager.removeView(it) } }
        bubble = null
        removeTarget = null
        preferences().edit().putBoolean(KEY_ACTIVE, false).apply()
        instance = null
        super.onDestroy()
    }

    private fun showBubble() {
        val size = dp(58)
        val view = ImageView(this).apply {
            setImageResource(R.drawable.ic_quick_bucketify)
            setPadding(dp(15), dp(15), dp(15), dp(15))
            elevation = dp(8).toFloat()
            contentDescription = "Bucketify copied word"
            background = bubbleBackground(savedColor())
        }
        val prefs = preferences()
        val params = WindowManager.LayoutParams(
            size,
            size,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = prefs.getInt(KEY_X, dp(16))
            y = prefs.getInt(KEY_Y, dp(180))
        }
        bubble = view
        bubbleParams = params
        view.setOnTouchListener(BubbleTouchListener())
        windowManager.addView(view, params)
    }

    private inner class BubbleTouchListener : View.OnTouchListener {
        private var startX = 0
        private var startY = 0
        private var touchX = 0f
        private var touchY = 0f
        private var moved = false

        override fun onTouch(view: View, event: MotionEvent): Boolean {
            val params = bubbleParams ?: return false
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startX = params.x
                    startY = params.y
                    touchX = event.rawX
                    touchY = event.rawY
                    moved = false
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - touchX).toInt()
                    val dy = (event.rawY - touchY).toInt()
                    if (!moved && hypot(dx.toDouble(), dy.toDouble()) > dp(6)) {
                        moved = true
                        showRemoveTarget()
                    }
                    params.x = startX + dx
                    params.y = startY + dy
                    windowManager.updateViewLayout(view, params)
                    updateRemoveState(event.rawX, event.rawY)
                    return true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (!moved && event.actionMasked == MotionEvent.ACTION_UP) {
                        openClipboardBucketify()
                    } else if (draggingToRemove) {
                        hideRemoveTarget()
                        stopSelf()
                    } else {
                        snapToEdge(view, params)
                        hideRemoveTarget()
                    }
                    return true
                }
            }
            return false
        }
    }

    private fun openClipboardBucketify() {
        startActivity(Intent(this, BucketifyActivity::class.java).apply {
            action = BucketifyActivity.ACTION_BUCKETIFY_CLIPBOARD
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        })
    }

    private fun snapToEdge(view: View, params: WindowManager.LayoutParams) {
        val screenWidth = resources.displayMetrics.widthPixels
        val margin = dp(16)
        params.x = if (params.x + view.width / 2 < screenWidth / 2) {
            margin
        } else {
            screenWidth - view.width - margin
        }
        params.y = params.y.coerceIn(dp(36), resources.displayMetrics.heightPixels - view.height - dp(80))
        windowManager.updateViewLayout(view, params)
        preferences().edit().putInt(KEY_X, params.x).putInt(KEY_Y, params.y).apply()
    }

    private fun showRemoveTarget() {
        if (removeTarget != null) return
        val size = dp(70)
        val target = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_delete)
            setColorFilter(Color.WHITE)
            setPadding(dp(21), dp(21), dp(21), dp(21))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0xFF8C2F39.toInt())
            }
        }
        val params = WindowManager.LayoutParams(
            size,
            size,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = dp(38)
        }
        removeTarget = target
        windowManager.addView(target, params)
    }

    private fun updateRemoveState(rawX: Float, rawY: Float) {
        val screenHeight = resources.displayMetrics.heightPixels
        val screenWidth = resources.displayMetrics.widthPixels
        val inside = hypot(
            rawX.toDouble() - screenWidth / 2.0,
            rawY.toDouble() - (screenHeight - dp(73)).toDouble(),
        ) < dp(72)
        if (inside == draggingToRemove) return
        draggingToRemove = inside
        removeTarget?.animate()?.scaleX(if (inside) 1.2f else 1f)
            ?.scaleY(if (inside) 1.2f else 1f)?.setDuration(120)?.start()
    }

    private fun hideRemoveTarget() {
        removeTarget?.let { runCatching { windowManager.removeView(it) } }
        removeTarget = null
        draggingToRemove = false
    }

    fun updateColor(color: Int) {
        preferences().edit().putInt(KEY_COLOR, color).apply()
        bubble?.background = bubbleBackground(color)
    }

    private fun bubbleBackground(color: Int) = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(color)
        setStroke(dp(2), Color.argb(80, 255, 255, 255))
    }

    private fun buildNotification(): android.app.Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            1,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stopIntent = PendingIntent.getService(
            this,
            2,
            Intent(this, ReadingCompanionService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(getString(R.string.reading_companion_active))
            .setContentText(getString(R.string.reading_companion_hint))
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(0, getString(R.string.stop_reading_companion), stopIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.reading_companion_channel),
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
    }

    private fun preferences() = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private fun savedColor() = preferences().getInt(KEY_COLOR, defaultColor())
    private fun defaultColor() = 0xFF203A43.toInt()
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun overlayType() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    } else {
        @Suppress("DEPRECATION")
        WindowManager.LayoutParams.TYPE_PHONE
    }

    companion object {
        private const val CHANNEL_ID = "reading_companion"
        private const val NOTIFICATION_ID = 4402
        private const val PREFS = "reading_companion"
        private const val KEY_ACTIVE = "active"
        private const val KEY_COLOR = "color"
        private const val KEY_X = "x"
        private const val KEY_Y = "y"
        const val ACTION_STOP = "com.elst.wordbucket.action.STOP_READING_COMPANION"
        const val ACTION_UPDATE_COLOR = "com.elst.wordbucket.action.UPDATE_COMPANION_COLOR"
        const val EXTRA_COLOR = "color"

        @Volatile
        private var instance: ReadingCompanionService? = null

        fun isActive(context: Context): Boolean =
            instance != null || context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_ACTIVE, false)

        fun updateActiveColor(context: Context, color: Int) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putInt(KEY_COLOR, color).apply()
            instance?.updateColor(color)
        }
    }
}
