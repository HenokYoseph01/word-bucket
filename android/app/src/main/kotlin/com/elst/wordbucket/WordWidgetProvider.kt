package com.elst.wordbucket

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class WordWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val word = widgetData.getString("word", null) ?: "No words yet"
        val partOfSpeech = widgetData.getString("partOfSpeech", null).orEmpty()
        val definition = widgetData.getString("definition", null)
            ?: "Save a word in WordBucket to see it here."

        val openAppIntent = Intent(context, MainActivity::class.java)
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val refreshPendingIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("wordbucket://refresh"),
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.word_widget).apply {
                setTextViewText(R.id.widget_word, word)
                setTextViewText(R.id.widget_part_of_speech, partOfSpeech)
                setTextViewText(R.id.widget_definition, definition)
                setOnClickPendingIntent(R.id.word_widget, openAppPendingIntent)
                setOnClickPendingIntent(R.id.widget_refresh, refreshPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
