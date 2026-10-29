package com.aiyepeks.taskie

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.aiyepeks.taskie.widgets.TaskieWidgets
import com.aiyepeks.taskie.widgets.WidgetKind
import com.aiyepeks.taskie.widgets.WidgetSnapshot

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.aiyepeks.taskie/home_widgets").also { channel ->
            channel.setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "updateSnapshot" -> {
                            val saved = WidgetSnapshot.save(this, call.arguments as String)
                            if (!saved) result.error("save_failed", "Could not save widget data", null)
                            else {
                                TaskieWidgets.updateAll(this)
                                result.success(null)
                            }
                        }
                        "getStatus" -> result.success(TaskieWidgets.status(this))
                        "requestPin" -> {
                            val kind = WidgetKind.values().firstOrNull { it.wireName == call.arguments }
                            if (kind == null) result.error("invalid_kind", "Unknown widget", null)
                            else result.success(TaskieWidgets.requestPin(this, kind))
                        }
                        "consumeLaunch" -> {
                            val kind = intent.getStringExtra(TaskieWidgets.EXTRA_KIND)
                            if (kind == null) result.success(null)
                            else {
                                val target = mutableMapOf<String, Any>("kind" to kind)
                                if (intent.hasExtra(TaskieWidgets.EXTRA_ID))
                                    target["id"] = intent.getLongExtra(TaskieWidgets.EXTRA_ID, -1)
                                if (intent.hasExtra(TaskieWidgets.EXTRA_DAY))
                                    target["weekday"] = intent.getIntExtra(TaskieWidgets.EXTRA_DAY, 1)
                                intent.removeExtra(TaskieWidgets.EXTRA_KIND)
                                intent.removeExtra(TaskieWidgets.EXTRA_ID)
                                intent.removeExtra(TaskieWidgets.EXTRA_DAY)
                                result.success(target)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("widget_error", error.message, null)
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.hasExtra(TaskieWidgets.EXTRA_KIND)) {
            widgetChannel?.invokeMethod("widgetTapped", null)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        widgetChannel?.setMethodCallHandler(null)
        widgetChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
