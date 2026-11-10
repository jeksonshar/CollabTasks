package com.example.collab_tasks

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class TaskHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { appWidgetId ->
            val serviceIntent = Intent(context, TaskWidgetRemoteViewsService::class.java)
            val views = RemoteViews(context.packageName, R.layout.task_home_widget).apply {
                setRemoteAdapter(R.id.task_grid, serviceIntent)
                setEmptyView(R.id.task_grid, R.id.empty_tasks)
                setPendingIntentTemplate(R.id.task_grid, openTaskPendingIntent(context))
                setOnClickPendingIntent(R.id.widget_title, openAppPendingIntent(context))
            }
            manager.updateAppWidget(appWidgetId, views)
        }
    }

    companion object {
        const val PREFERENCES = "task_home_widget"
        const val TASKS_KEY = "tasks_json"
        const val EXTRA_TASK_ID = MainActivity.EXTRA_TASK_ID

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TaskHomeWidgetProvider::class.java)
            manager.notifyAppWidgetViewDataChanged(manager.getAppWidgetIds(component), R.id.task_grid)
        }

        private fun openTaskPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
        }

        private fun openAppPendingIntent(context: Context): PendingIntent {
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            return PendingIntent.getActivity(
                context,
                1,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}

class TaskWidgetRemoteViewsService : android.widget.RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = TaskWidgetViewsFactory(applicationContext)
}

private class TaskWidgetViewsFactory(private val context: Context) :
    android.widget.RemoteViewsService.RemoteViewsFactory {
    private var tasks: List<org.json.JSONObject> = emptyList()

    override fun onCreate() = Unit
    override fun onDataSetChanged() {
        val json = context.getSharedPreferences(TaskHomeWidgetProvider.PREFERENCES, Context.MODE_PRIVATE)
            .getString(TaskHomeWidgetProvider.TASKS_KEY, "[]") ?: "[]"
        tasks = runCatching {
            val array = org.json.JSONArray(json)
            List(array.length()) { index -> array.getJSONObject(index) }
        }.getOrDefault(emptyList())
    }

    override fun onDestroy() {
        tasks = emptyList()
    }

    override fun getCount() = tasks.size
    override fun getViewAt(position: Int): RemoteViews? {
        val task = tasks.getOrNull(position) ?: return null
        return RemoteViews(context.packageName, R.layout.task_home_widget_item).apply {
            setTextViewText(R.id.task_title, task.optString("title"))
            setTextViewText(R.id.task_status, if (task.optBoolean("isCompleted")) "✓" else "○")
            val fillInIntent = Intent().putExtra(MainActivity.EXTRA_TASK_ID, task.optString("id"))
            setOnClickFillInIntent(R.id.task_item, fillInIntent)
        }
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount() = 1
    override fun getItemId(position: Int) =
        tasks.getOrNull(position)?.optString("id")?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds() = true
}
