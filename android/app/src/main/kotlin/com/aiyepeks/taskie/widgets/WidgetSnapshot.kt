package com.aiyepeks.taskie.widgets

import android.content.Context
import org.json.JSONObject

data class WidgetSnapshot(val tasks: List<WidgetTask>, val schedule: List<WidgetSchedule>) {
    companion object {
        private const val PREFERENCES = "taskie_home_widgets"

        fun save(context: Context, json: String): Boolean {
            require(JSONObject(json).getInt("version") == 1)
            return context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .edit().putString("snapshot", json).commit()
        }

        fun read(context: Context): WidgetSnapshot {
            val json = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .getString("snapshot", null) ?: return WidgetSnapshot(emptyList(), emptyList())
            return try {
                val root = JSONObject(json)
                if (root.optInt("version") != 1) return WidgetSnapshot(emptyList(), emptyList())
                val tasks = mutableListOf<WidgetTask>()
                val entries = mutableListOf<WidgetSchedule>()
                root.optJSONArray("tasks")?.let { array ->
                    for (index in 0 until array.length()) {
                        val task = array.optJSONObject(index) ?: continue
                        val id = task.optLong("id", -1)
                        val dueAt = task.optLong("dueAt", -1)
                        if (id > 0 && dueAt > 0) tasks.add(WidgetTask(id, task.optString("title"), dueAt))
                    }
                }
                root.optJSONArray("schedule")?.let { array ->
                    for (index in 0 until array.length()) {
                        val entry = array.optJSONObject(index) ?: continue
                        val days = entry.optJSONArray("days") ?: continue
                        val id = entry.optLong("id", -1)
                        if (id <= 0) continue
                        entries.add(WidgetSchedule(
                            id, entry.optString("title"),
                            (0 until days.length()).map { days.optInt(it) }.filter { it in 1..7 },
                            entry.optInt("startMinutes", -1), entry.optInt("endMinutes", -1),
                        ))
                    }
                }
                WidgetSnapshot(tasks, entries)
            } catch (_: Exception) {
                WidgetSnapshot(emptyList(), emptyList())
            }
        }
    }
}
