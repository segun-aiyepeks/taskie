package com.aiyepeks.taskie.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.widget.RemoteViews
import com.aiyepeks.taskie.MainActivity
import com.aiyepeks.taskie.R
import java.text.DateFormat
import java.util.Calendar
import java.util.Date

enum class WidgetKind(val wireName: String) { TASK("task"), SCHEDULE("schedule") }

class NextTaskWidgetProvider : TaskieWidgetProvider()
class NextScheduleWidgetProvider : TaskieWidgetProvider()

open class TaskieWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        TaskieWidgets.updateAll(context)
    }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        TaskieWidgets.updateAll(context)
    }
    override fun onDisabled(context: Context) { TaskieWidgets.updateAll(context) }
    override fun onDeleted(context: Context, ids: IntArray) { TaskieWidgets.updateAll(context) }
}

class WidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) { TaskieWidgets.updateAll(context) }
}

object TaskieWidgets {
    const val EXTRA_KIND = "taskie.widget.kind"
    const val EXTRA_ID = "taskie.widget.id"
    const val EXTRA_DAY = "taskie.widget.day"
    private const val REFRESH_ACTION = "com.aiyepeks.taskie.WIDGET_REFRESH"
    private const val TIMER_REQUEST = 940031

    private fun provider(context: Context, kind: WidgetKind) = ComponentName(
        context,
        if (kind == WidgetKind.TASK) NextTaskWidgetProvider::class.java
        else NextScheduleWidgetProvider::class.java,
    )

    fun status(context: Context): Map<String, Any> {
        val manager = AppWidgetManager.getInstance(context)
        return mapOf(
            "pinSupported" to (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported),
            "taskCount" to manager.getAppWidgetIds(provider(context, WidgetKind.TASK)).size,
            "scheduleCount" to manager.getAppWidgetIds(provider(context, WidgetKind.SCHEDULE)).size,
        )
    }

    fun requestPin(context: Context, kind: WidgetKind): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        if (Build.VERSION.SDK_INT < 26 || !manager.isRequestPinAppWidgetSupported) return false
        val callback = PendingIntent.getBroadcast(context, TIMER_REQUEST + 1,
            Intent(context, WidgetRefreshReceiver::class.java).setAction("$REFRESH_ACTION.PINNED"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return manager.requestPinAppWidget(provider(context, kind), null, callback)
    }

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val taskIds = manager.getAppWidgetIds(provider(context, WidgetKind.TASK))
        val scheduleIds = manager.getAppWidgetIds(provider(context, WidgetKind.SCHEDULE))
        if (taskIds.isEmpty() && scheduleIds.isEmpty()) {
            alarmManager(context).cancel(timerIntent(context))
            return
        }
        val now = System.currentTimeMillis()
        val snapshot = WidgetSnapshot.read(context)
        val task = WidgetItems.nextTask(snapshot.tasks, now)
        val schedule = WidgetItems.nextSchedule(snapshot.schedule, now)
        for (id in taskIds) manager.updateAppWidget(id, render(context, id, WidgetKind.TASK, task, now))
        for (id in scheduleIds) manager.updateAppWidget(id, render(context, id, WidgetKind.SCHEDULE, schedule, now))

        // Also refresh at midnight so Today/Tomorrow labels stay correct.
        val midnight = Calendar.getInstance().apply {
            timeInMillis = now
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val next = listOfNotNull(
            midnight,
            task?.startsAt?.plus(1000)?.takeIf { taskIds.isNotEmpty() },
            schedule?.startsAt?.plus(1000)?.takeIf { scheduleIds.isNotEmpty() },
        ).minOrNull()!!
        scheduleRefresh(context, next)
    }

    private fun render(context: Context, id: Int, kind: WidgetKind, item: WidgetItem?, now: Long): RemoteViews {
        val isTask = kind == WidgetKind.TASK
        val views = RemoteViews(context.packageName,
            if (isTask) R.layout.next_task_widget else R.layout.next_schedule_widget)
        if (item != null) {
            views.setTextViewText(R.id.widget_title, item.title)
            val time = android.text.format.DateFormat.getTimeFormat(context)
            val start = time.format(Date(item.startsAt))
            val range = item.endsAt?.let { "$start – ${time.format(Date(it))}" } ?: start
            views.setTextViewText(R.id.widget_when, "${dayLabel(context, item.startsAt, now)} · $range")
            views.setTextViewText(R.id.widget_hint, context.getString(
                if (isTask) R.string.widget_open_task else R.string.widget_open_schedule))
        } else {
            views.setTextViewText(R.id.widget_title, context.getString(
                if (isTask) R.string.widget_no_task else R.string.widget_no_schedule))
            views.setTextViewText(R.id.widget_when, context.getString(
                if (isTask) R.string.widget_no_task_hint else R.string.widget_no_schedule_hint))
            views.setTextViewText(R.id.widget_hint, context.getString(R.string.widget_open_app))
        }
        val open = Intent(context, MainActivity::class.java).apply {
            action = "com.aiyepeks.taskie.OPEN_WIDGET.$id"
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_KIND, kind.wireName)
            item?.let { putExtra(EXTRA_ID, it.id) }
            item?.weekday?.let { putExtra(EXTRA_DAY, it) }
        }
        views.setOnClickPendingIntent(R.id.widget_root, PendingIntent.getActivity(
            context, id, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        views.setOnClickPendingIntent(R.id.widget_refresh, PendingIntent.getBroadcast(
            context, id, Intent(context, WidgetRefreshReceiver::class.java).setAction(REFRESH_ACTION),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        return views
    }

    private fun dayLabel(context: Context, millis: Long, now: Long): String {
        val date = Calendar.getInstance().apply { timeInMillis = millis }
        val today = Calendar.getInstance().apply { timeInMillis = now }
        fun sameDay(other: Calendar) = date.get(Calendar.YEAR) == other.get(Calendar.YEAR) &&
            date.get(Calendar.DAY_OF_YEAR) == other.get(Calendar.DAY_OF_YEAR)
        if (sameDay(today)) return context.getString(R.string.widget_today)
        today.add(Calendar.DAY_OF_YEAR, 1)
        if (sameDay(today)) return context.getString(R.string.widget_tomorrow)
        return DateFormat.getDateInstance(DateFormat.MEDIUM).format(Date(millis))
    }

    private fun alarmManager(context: Context) = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private fun timerIntent(context: Context) = PendingIntent.getBroadcast(
        context, TIMER_REQUEST,
        Intent(context, WidgetRefreshReceiver::class.java).setAction("$REFRESH_ACTION.TIME"),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun scheduleRefresh(context: Context, at: Long) {
        val alarms = alarmManager(context)
        val pending = timerIntent(context)
        try {
            if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
                // Non-wakeup: a home-screen refresh should not wake a sleeping phone.
                alarms.setExact(AlarmManager.RTC, at, pending)
                return
            }
        } catch (_: SecurityException) {
            // Exact-alarm access may have been revoked between checking and scheduling.
        }
        alarms.set(AlarmManager.RTC, at, pending)
    }
}
