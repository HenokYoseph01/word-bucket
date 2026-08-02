package com.elst.wordbucket

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService

class QuickBucketifyTileService : TileService() {
    override fun onClick() {
        super.onClick()
        if (isLocked) {
            unlockAndRun { openClipboardBucketify() }
        } else {
            openClipboardBucketify()
        }
    }

    private fun openClipboardBucketify() {
        val intent = Intent(this, BucketifyActivity::class.java).apply {
            action = BucketifyActivity.ACTION_BUCKETIFY_CLIPBOARD
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                401,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
