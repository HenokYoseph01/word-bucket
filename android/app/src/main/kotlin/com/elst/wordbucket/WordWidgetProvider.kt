package com.elst.wordbucket

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class WordWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val ACTION_REFRESH = "com.elst.wordbucket.WIDGET_REFRESH"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds, rotateRequested = false)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, WordWidgetProvider::class.java))
            updateWidgets(context, manager, ids, rotateRequested = true)
            return
        }
        super.onReceive(context, intent)
    }

    private fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        rotateRequested: Boolean,
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val items = readItems(widgetData.getString("itemsJson", "[]") ?: "[]")
        val dataVersion = readInt(widgetData.all["dataVersion"], 0)
        val renderedVersion = readInt(widgetData.all["renderedVersion"], -1)
        val dataChanged = dataVersion != renderedVersion

        var index = readInt(widgetData.all["currentIndex"], 0)
        if (items.isNotEmpty()) {
            index = index.coerceIn(0, items.lastIndex)
            if ((rotateRequested || !dataChanged) && items.size > 1) {
                index = (index + 1) % items.size
            }
        } else {
            index = 0
        }

        widgetData.edit()
            .putInt("currentIndex", index)
            .putInt("renderedVersion", dataVersion)
            .apply()

        val item = items.getOrNull(index)
        val word = item?.word ?: "No words yet"
        val partOfSpeech = item?.partOfSpeech.orEmpty()
        val definition = item?.definition ?: "Save a word in WordBucket to see it here."

        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val refreshIntent = Intent(context, WordWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.word_widget).apply {
                setTextViewText(R.id.widget_word, word)
                setTextViewText(R.id.widget_part_of_speech, partOfSpeech)
                setTextViewText(R.id.widget_definition, definition)
                setTextViewText(
                    R.id.widget_position,
                    if (items.isEmpty()) "0 words" else "${index + 1} / ${items.size}",
                )
                setViewVisibility(
                    R.id.widget_part_of_speech,
                    if (partOfSpeech.isNotEmpty()) View.VISIBLE else View.GONE,
                )
                setViewVisibility(
                    R.id.widget_refresh,
                    if (items.size > 1) View.VISIBLE else View.GONE,
                )
                setOnClickPendingIntent(R.id.word_widget, openAppPendingIntent)
                setOnClickPendingIntent(R.id.widget_refresh, refreshPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun readItems(json: String): List<WidgetWord> {
        return try {
            val array = JSONArray(json)
            List(array.length()) { index ->
                val item = array.getJSONObject(index)
                WidgetWord(
                    word = item.optString("word"),
                    partOfSpeech = item.optString("partOfSpeech"),
                    definition = item.optString("definition"),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun readInt(value: Any?, fallback: Int): Int {
        return (value as? Number)?.toInt() ?: fallback
    }

    private data class WidgetWord(
        val word: String,
        val partOfSpeech: String,
        val definition: String,
    )
}
