package com.aiyepeks.taskie.widgets

import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class WidgetItemsTest {
    private val utc = TimeZone.getTimeZone("UTC")
    private fun at(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0,
                   zone: TimeZone = utc): Long = Calendar.getInstance(zone).apply {
        clear(); set(year, month - 1, day, hour, minute)
    }.timeInMillis

    @Test fun tasksAreOrderedByTimeAndExpiredTasksAreSkipped() {
        val now = at(2026, 10, 28, 12)
        val tasks = listOf(WidgetTask(3, "Later", now + 5000),
            WidgetTask(1, "Expired", now - 1), WidgetTask(2, "Next", now + 1000))
        assertEquals(2L, WidgetItems.nextTask(tasks, now)?.id)
        assertEquals(3L, WidgetItems.nextTask(tasks, now + 1001)?.id)
        assertNull(WidgetItems.nextTask(tasks, now + 5001))
    }

    @Test fun tasksIncludeTheExactTimeAndBreakTiesConsistently() {
        val tasks = listOf(WidgetTask(2, "B", 100), WidgetTask(1, "A", 100))
        assertEquals(1L, WidgetItems.nextTask(tasks, 100)?.id)
        assertNull(WidgetItems.nextTask(emptyList(), 100))
    }

    @Test fun weeklyEntriesChooseTheNextStartAcrossAllSelectedDays() {
        val now = at(2026, 10, 28, 12) // Wednesday
        val entries = listOf(
            WidgetSchedule(1, "Started", listOf(3), 11 * 60, 13 * 60),
            WidgetSchedule(2, "Tomorrow", listOf(4, 6), 9 * 60, 10 * 60),
            WidgetSchedule(3, "This afternoon", listOf(1, 3, 5), 14 * 60, 15 * 60),
        )
        val next = WidgetItems.nextSchedule(entries, now, utc)!!
        assertEquals(3L, next.id)
        assertEquals(3, next.weekday)
        assertEquals(at(2026, 10, 28, 14), next.startsAt)
        assertEquals(at(2026, 10, 28, 15), next.endsAt)
        assertEquals(2L, WidgetItems.nextSchedule(entries, next.startsAt + 1, utc)?.id)
    }

    @Test fun aPassedWeeklyStartMovesToNextWeekEvenWithTheAppClosed() {
        val entry = WidgetSchedule(1, "Weekly", listOf(3), 9 * 60, 10 * 60)
        val today = at(2026, 10, 28, 9)
        assertEquals(today, WidgetItems.nextSchedule(listOf(entry), today, utc)?.startsAt)
        assertEquals(at(2026, 11, 4, 9), WidgetItems.nextSchedule(listOf(entry), today + 1, utc)?.startsAt)
    }

    @Test fun sundayRollsOverToMondayAndMidnightIsAValidStart() {
        val entry = WidgetSchedule(1, "Monday", listOf(1), 0, 60)
        assertEquals(at(2026, 11, 2), WidgetItems.nextSchedule(
            listOf(entry), at(2026, 11, 1, 23, 59), utc)?.startsAt)
    }

    @Test fun recurringTimesStayLocalAcrossDaylightSavingChanges() {
        val zone = TimeZone.getTimeZone("America/New_York")
        val entry = WidgetSchedule(1, "Sunday", listOf(7), 9 * 60, 10 * 60)
        val next = WidgetItems.nextSchedule(listOf(entry), at(2026, 3, 7, 12, zone = zone), zone)!!
        assertEquals(at(2026, 3, 8, 9, zone = zone), next.startsAt)
        assertEquals(at(2026, 3, 8, 13), next.startsAt)
    }

    @Test fun emptyOrInvalidSchedulesProduceAnEmptyWidget() {
        assertNull(WidgetItems.nextSchedule(emptyList(), 0, utc))
        assertNull(WidgetItems.nextSchedule(listOf(
            WidgetSchedule(1, "No days", emptyList(), 60, 120),
            WidgetSchedule(2, "Bad time", listOf(3), 1500, 1600),
            WidgetSchedule(3, "Bad days", listOf(0, 8), 60, 120),
        ), at(2026, 10, 28), utc))
    }
}
