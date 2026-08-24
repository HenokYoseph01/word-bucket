package com.elst.wordbucket

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
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
        val appearance = resolveAppearance(
            widgetData.getString("themePalette", "classicInk") ?: "classicInk",
            widgetData.getString("themeMode", "system") ?: "system",
            context,
        )

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
                setTextColor(R.id.widget_brand, appearance.accent)
                setTextColor(R.id.widget_word, appearance.text)
                setTextColor(R.id.widget_part_of_speech, appearance.badgeText)
                setTextColor(R.id.widget_definition, appearance.muted)
                setTextColor(R.id.widget_position, appearance.muted)
                setTextColor(R.id.widget_open_hint, appearance.hint)
                setImageViewBitmap(
                    R.id.widget_background_surface,
                    roundedBackground(
                        widthPx = 360,
                        heightPx = 240,
                        radiusPx = 20f,
                        fill = appearance.background,
                        border = appearance.border,
                    ),
                )
                setImageViewBitmap(
                    R.id.widget_badge_surface,
                    roundedBackground(
                        widthPx = 180,
                        heightPx = 50,
                        radiusPx = 25f,
                        fill = appearance.badgeBackground,
                        border = appearance.badgeBackground,
                    ),
                )
                setInt(R.id.widget_refresh, "setColorFilter", appearance.accent)
                setTextViewText(
                    R.id.widget_position,
                    if (items.isEmpty()) "0 words" else "${index + 1} / ${items.size}",
                )
                setViewVisibility(
                    R.id.widget_badge,
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

    private fun resolveAppearance(
        palette: String,
        themeMode: String,
        context: Context,
    ): WidgetAppearance {
        val systemDark =
            context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
                Configuration.UI_MODE_NIGHT_YES
        val dark = themeMode == "dark" || (themeMode == "system" && systemDark)

        return when (palette) {
            "forestJournal" -> if (dark) {
                WidgetAppearance("#121C17", "#405048", "#EDF5EF", "#B8C7BD", "#839087", "#C79A45", "#314B3B", "#E4EEE7")
            } else {
                WidgetAppearance("#FBF8ED", "#DED8C7", "#315B45", "#5D6B61", "#8A938C", "#8A6525", "#DFEBDD", "#315B45")
            }
            "sepiaLibrary" -> if (dark) {
                WidgetAppearance("#211813", "#554238", "#FFF1DF", "#D4C1B0", "#9C8B7F", "#D5A06B", "#51382A", "#F2DDC8")
            } else {
                WidgetAppearance("#FFF5DF", "#E8D7BB", "#6B4932", "#735F50", "#9A8876", "#9A5D2D", "#F2DFC4", "#6B4932")
            }
            "plumNotebook" -> if (dark) {
                WidgetAppearance("#20171F", "#523D50", "#F9EDF7", "#D1BECF", "#998896", "#D09A5B", "#4D3449", "#F1DDEE")
            } else {
                WidgetAppearance("#FFF7FA", "#E8D8E3", "#65445F", "#725F6E", "#998994", "#9A643D", "#F0DFEB", "#65445F")
            }
            "midnightBlue" -> if (dark) {
                WidgetAppearance("#111821", "#263B5A", "#EEF3FF", "#BAC7DA", "#8291A5", "#72A9FF", "#173B78", "#D9E6FF")
            } else {
                WidgetAppearance("#F6F8FC", "#D8DFEA", "#2457D6", "#586A82", "#8390A2", "#3478EE", "#DCE6FF", "#2457D6")
            }
            "monochromePaper" -> if (dark) {
                WidgetAppearance("#000000", "#444444", "#FFFFFF", "#C8C8C8", "#888888", "#D0D0D0", "#292929", "#FFFFFF")
            } else {
                WidgetAppearance("#FFFFFF", "#D8D8D8", "#111111", "#555555", "#888888", "#333333", "#E8E8E8", "#111111")
            }
            "rosePetal" -> if (dark) {
                WidgetAppearance("#21151B", "#573947", "#FFF0F5", "#D9BEC8", "#A58B95", "#E7A5B8", "#53303F", "#FFE7EF")
            } else {
                WidgetAppearance("#FFF5F8", "#E9D5DC", "#7C3F59", "#765F68", "#9A858D", "#A75A7A", "#F4DDE5", "#7C3F59")
            }
            "matchaHoney" -> if (dark) {
                WidgetAppearance("#1B1D13", "#4A4E32", "#F5F1DA", "#CFC9A9", "#96937C", "#F1E8C7", "#42472C", "#F5F1DA")
            } else {
                WidgetAppearance("#FCFAEF", "#DED9BC", "#56602E", "#6E705B", "#969584", "#7E883E", "#F1E8C7", "#56602E")
            }
            "lilacEvening" -> if (dark) {
                WidgetAppearance("#222433", "#47485A", "#F3F0FF", "#C9C5D8", "#9592A3", "#B8A9D6", "#463B5E", "#E9DFFF")
            } else {
                WidgetAppearance("#FCFCE2", "#D9D9C5", "#4D3E6B", "#6D657A", "#918C98", "#81749C", "#E4E8D9", "#4D3E6B")
            }
            "cherryInk" -> if (dark) {
                WidgetAppearance("#180C11", "#471D27", "#FFF0F2", "#D9BBC1", "#A58A90", "#FF5874", "#650F28", "#FFD9DE")
            } else {
                WidgetAppearance("#FFF8F3", "#E8D2D2", "#C90E36", "#73565A", "#998589", "#D9143F", "#FFD0D6", "#C90E36")
            }
            "hotPink" -> if (dark) {
                WidgetAppearance("#080308", "#341522", "#FFF0F7", "#DDBBC9", "#AA8997", "#FF4FA3", "#58002D", "#FFD9E7")
            } else {
                WidgetAppearance("#FFF7FB", "#EBD6DE", "#D10068", "#765963", "#9C8790", "#E60073", "#FFD7E6", "#D10068")
            }
            "pressedFlowers" -> if (dark) {
                WidgetAppearance("#2A171D", "#59333E", "#FFF0F3", "#D9BBC3", "#A58A92", "#EE9DB0", "#652B3C", "#FFD9E0")
            } else {
                WidgetAppearance("#F2E7D2", "#D9C9BB", "#473469", "#6D6075", "#948994", "#9A617E", "#E9D7DA", "#473469")
            }
            "moonlitLagoon" -> if (dark) {
                WidgetAppearance("#071F28", "#294751", "#E5FFFA", "#B7D3CF", "#839D9B", "#69D2CD", "#155653", "#B9FFF9")
            } else {
                WidgetAppearance("#F1F6CE", "#D2DAB8", "#294380", "#5A6875", "#87918A", "#287F83", "#D7E9D0", "#294380")
            }
            else -> if (dark) {
                WidgetAppearance("#111A1D", "#3F4B4F", "#F0F5F3", "#BCC8C6", "#899694", "#B5CCC7", "#314B4B", "#DCE8E3")
            } else {
                WidgetAppearance("#FFFFFBF3", "#E2D9CA", "#203A43", "#59686B", "#899294", "#315B61", "#DCE8E3", "#203A43")
            }
        }
    }

    private fun roundedBackground(
        widthPx: Int,
        heightPx: Int,
        radiusPx: Float,
        fill: Int,
        border: Int,
    ): Bitmap {
        val width = widthPx
        val height = heightPx
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val rect = RectF(1f, 1f, width - 1f, height - 1f)
        val radius = radiusPx
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = fill
        }
        canvas.drawRoundRect(rect, radius, radius, paint)
        paint.apply {
            style = Paint.Style.STROKE
            strokeWidth = 1.5f
            color = border
        }
        canvas.drawRoundRect(rect, radius, radius, paint)
        return bitmap
    }

    private data class WidgetWord(
        val word: String,
        val partOfSpeech: String,
        val definition: String,
    )

    private data class WidgetAppearance(
        val background: Int,
        val border: Int,
        val text: Int,
        val muted: Int,
        val hint: Int,
        val accent: Int,
        val badgeBackground: Int,
        val badgeText: Int,
    ) {
        constructor(
            background: String,
            border: String,
            text: String,
            muted: String,
            hint: String,
            accent: String,
            badgeBackground: String,
            badgeText: String,
        ) : this(
            Color.parseColor(background),
            Color.parseColor(border),
            Color.parseColor(text),
            Color.parseColor(muted),
            Color.parseColor(hint),
            Color.parseColor(accent),
            Color.parseColor(badgeBackground),
            Color.parseColor(badgeText),
        )
    }
}
