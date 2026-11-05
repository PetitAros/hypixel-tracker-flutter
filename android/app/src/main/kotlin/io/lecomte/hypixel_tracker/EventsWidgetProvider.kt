package io.lecomte.hypixel_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

// The SkyBlock events widget. The lines are written by Dart
// (lib/features/events/background/events_home_widget.dart); this only puts
// them in the layout. Tapping the widget opens the app.
class EventsWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val lines =
        mapOf(
            R.id.events_mayor to "mayor",
            R.id.events_mayor_detail to "mayor_detail",
            R.id.events_bingo to "bingo",
            R.id.events_bingo_detail to "bingo_detail",
            R.id.events_fire_sale to "fire_sale",
            R.id.events_fire_sale_detail to "fire_sale_detail",
            R.id.events_updated to "updated",
        )

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.events_widget).apply {
            setOnClickPendingIntent(
                R.id.events_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            // Before the first sync, the layout's placeholders stay.
            lines.forEach { (viewId, key) ->
              widgetData.getString(key, null)?.let { setTextViewText(viewId, it) }
            }
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
