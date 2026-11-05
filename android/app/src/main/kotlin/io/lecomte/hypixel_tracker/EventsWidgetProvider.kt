package io.lecomte.hypixel_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

// The SkyBlock events widget. The lines are written by Dart
// (lib/features/events/background/events_home_widget.dart); this only puts
// them in the layout, and picks the next event that has not passed yet.
// Tapping the widget opens the app.
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
            showNextEvent(this, widgetData)
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  // "millis<TAB>label" lines, the soonest first. Redraws are scheduled at
  // each time, so the first one still to come is the one to show.
  private fun showNextEvent(views: RemoteViews, widgetData: SharedPreferences) {
    val now = System.currentTimeMillis()
    val next =
        widgetData
            .getString("next_events", null)
            ?.lines()
            ?.mapNotNull { line ->
              val (millis, label) = line.split('\t', limit = 2).takeIf { it.size == 2 }
                  ?: return@mapNotNull null
              millis.toLongOrNull()?.let { it to label }
            }
            ?.firstOrNull { (millis, _) -> millis > now }

    if (next == null) {
      views.setTextViewText(R.id.events_next, "No event scheduled")
      views.setViewVisibility(R.id.events_next_countdown, android.view.View.GONE)
      return
    }

    val (millis, label) = next
    views.setTextViewText(R.id.events_next, label)
    views.setViewVisibility(R.id.events_next_countdown, android.view.View.VISIBLE)
    // A Chronometer counts on its own, without waking the app every second.
    views.setChronometer(
        R.id.events_next_countdown,
        SystemClock.elapsedRealtime() + (millis - now),
        "in %s",
        true,
    )
    views.setChronometerCountDown(R.id.events_next_countdown, true)
  }
}
