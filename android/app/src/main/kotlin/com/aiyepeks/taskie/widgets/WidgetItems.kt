package com.aiyepeks.taskie.widgets

import java.util.Calendar
import java.util.TimeZone

data class WidgetTask(val id: Long, val title: String, val dueAt: Long)
data class WidgetSchedule(
    val id: Long, val title: String, val days: List<Int>,
    val startMinutes: Int, val endMinutes: Int,
)
data class WidgetItem(
    val id: Long, val title: String, val startsAt: Long,
    val endsAt: Long? = null, val weekday: Int? = null,
)

/** Pure calendar selection, shared by updates, refresh taps and reboot recovery. */
object WidgetItems {
    fun nextTask(tasks: List<WidgetTask>, now: Long): WidgetItem? = tasks
        .filter { it.dueAt >= now }
        .minWithOrNull(compareBy<WidgetTask> { it.dueAt }.thenBy { it.id })
        ?.let { WidgetItem(it.id, it.title, it.dueAt) }

    fun nextSchedule(
        entries: List<WidgetSchedule>, now: Long,
        zone: TimeZone = TimeZone.getDefault(),
    ): WidgetItem? {
        var next: WidgetItem? = null
        for (entry in entries) {
            if (entry.startMinutes !in 0..1439 || entry.endMinutes !in 0..1440) continue
            for (offset in 0..7) {
                val start = Calendar.getInstance(zone).apply {
                    timeInMillis = now
                    add(Calendar.DAY_OF_YEAR, offset)
                    set(Calendar.HOUR_OF_DAY, entry.startMinutes / 60)
                    set(Calendar.MINUTE, entry.startMinutes % 60)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val weekday = (start.get(Calendar.DAY_OF_WEEK) + 5) % 7 + 1
                if (weekday !in entry.days || start.timeInMillis < now) continue
                val end = (start.clone() as Calendar).apply {
                    set(Calendar.HOUR_OF_DAY, entry.endMinutes / 60)
                    set(Calendar.MINUTE, entry.endMinutes % 60)
                    if (entry.endMinutes <= entry.startMinutes) add(Calendar.DAY_OF_YEAR, 1)
                }
                val candidate = WidgetItem(entry.id, entry.title, start.timeInMillis, end.timeInMillis, weekday)
                val current = next
                if (current == null || candidate.startsAt < current.startsAt ||
                    (candidate.startsAt == current.startsAt && candidate.id < current.id)) {
                    next = candidate
                }
                break
            }
        }
        return next
    }
}
