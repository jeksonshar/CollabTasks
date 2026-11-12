package com.example.collab_tasks

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.*
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.*
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.layout.*
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*
import android.graphics.Color as AndroidColor

class TaskHomeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TaskHomeGlanceWidget()
}

class TaskHomeGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val cachedTaskSnapshot = context.getSharedPreferences(TaskHomeWidgetCache.PREFERENCES, Context.MODE_PRIVATE)
            .getString(TaskHomeWidgetCache.TASKS_KEY, "[]")

        provideContent {
            val preferences = currentState<Preferences>()
            val taskSnapshot = preferences[taskSnapshotKey] ?: cachedTaskSnapshot ?: "[]"
            TaskWidgetContent(taskSnapshot.toWidgetTasks())
        }
    }
}

object TaskHomeWidgetCache {
    const val PREFERENCES = "task_home_widget"
    const val TASKS_KEY = "tasks_json"

    private val updateMutex = Mutex()

    suspend fun updateAllWidgets(context: Context) = updateMutex.withLock {
        val taskSnapshot = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString(TASKS_KEY, "[]") ?: "[]"
        val widget = TaskHomeGlanceWidget()
        val glanceIds = GlanceAppWidgetManager(context).getGlanceIds(TaskHomeGlanceWidget::class.java)

        glanceIds.forEach { glanceId ->
            updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { preferences ->
                preferences.toMutablePreferences().apply { this[taskSnapshotKey] = taskSnapshot }
            }
        }
        widget.updateAll(context)
    }

    suspend fun refreshWidget(context: Context, glanceId: GlanceId) = updateMutex.withLock {
        val taskSnapshot = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString(TASKS_KEY, "[]") ?: "[]"
        updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { preferences ->
            preferences.toMutablePreferences().apply { this[taskSnapshotKey] = taskSnapshot }
        }
        TaskHomeGlanceWidget().update(context, glanceId)
    }
}

private val taskSnapshotKey = stringPreferencesKey("task_snapshot")

class RefreshTaskHomeWidgetAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        TaskHomeWidgetCache.refreshWidget(context, glanceId)
    }
}

private data class WidgetTask(
    val id: String,
    val title: String,
    val priority: Int,
    val isCompleted: Boolean,
    val isPinned: Boolean,
    val subtasksCount: Int,
    val completedSubtasksCount: Int,
    val deadlineMillis: Long?,
    val attachmentsCount: Int,
)

private fun String?.toWidgetTasks(): List<WidgetTask> = runCatching {
    val json = JSONArray(this ?: "[]")
    List(json.length()) { index ->
        val item = json.getJSONObject(index)
        WidgetTask(
            id = item.optString("id"),
            title = item.optString("title"),
            priority = item.optInt("priority"),
            isCompleted = item.optBoolean("isCompleted"),
            isPinned = item.optBoolean("isPinned"),
            subtasksCount = item.optInt("subtasksCount"),
            completedSubtasksCount = item.optInt("completedSubtasksCount"),
            deadlineMillis = if (item.has("deadlineMillis") && !item.isNull("deadlineMillis")) {
                item.optLong("deadlineMillis")
            } else {
                null
            },
            attachmentsCount = item.optInt("attachmentsCount"),
        )
    }
}.getOrDefault(emptyList())

private val taskIdKey = ActionParameters.Key<String>(MainActivity.EXTRA_TASK_ID)
private val openHomeKey = ActionParameters.Key<Boolean>(MainActivity.EXTRA_OPEN_HOME)

@GlanceComposable
@androidx.compose.runtime.Composable
private fun TaskWidgetContent(tasks: List<WidgetTask>) {
    val openHomeAction = actionStartActivity<MainActivity>(actionParametersOf(openHomeKey to true))
    val refreshTasksAction = actionRunCallback<RefreshTaskHomeWidgetAction>()
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(widgetColor(AndroidColor.rgb(21, 22, 28)))
            .padding(12.dp),
    ) {
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .clickable(openHomeAction)
                .padding(bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "Личные задачи",
                style = TextStyle(
                    color = widgetColor(AndroidColor.rgb(245, 245, 250)),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Text(
                text = "${tasks.size}",
                style = TextStyle(color = widgetColor(AndroidColor.rgb(160, 162, 176)), fontSize = 14.sp),
            )
            Spacer(modifier = GlanceModifier.width(10.dp))
            Image(
                provider = ImageProvider(R.drawable.ic_widget_refresh),
                contentDescription = "Обновить задачи",
                modifier = GlanceModifier
                    .size(32.dp)
                    .background(widgetColor(AndroidColor.rgb(45, 46, 55)))
                    .cornerRadius(8.dp)
                    .clickable(refreshTasksAction)
                    .padding(5.dp),
                colorFilter = ColorFilter.tint(widgetColor(AndroidColor.rgb(190, 192, 205))),
            )
        }

        if (tasks.isEmpty()) {
            Box(
                modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "Нет задач",
                    style = TextStyle(color = widgetColor(AndroidColor.rgb(160, 162, 176)), fontSize = 13.sp),
                )
            }
        } else {
            Box(
                modifier = GlanceModifier.defaultWeight().fillMaxWidth().clickable(openHomeAction),
            ) {
                LazyColumn(modifier = GlanceModifier.fillMaxWidth()) {
                    items(items = tasks, itemId = { it.id.hashCode().toLong() }) { task ->
                        Box(
                            modifier = GlanceModifier.fillMaxWidth().padding(top = 8.dp)
                        ) {
                            TaskWidgetRow(task)
                        }
                    }
                }
            }
        }
    }
}

@GlanceComposable
@androidx.compose.runtime.Composable
private fun TaskWidgetRow(task: WidgetTask) {
    val priorityColor = when (task.priority) {
        1 -> AndroidColor.rgb(76, 175, 80)
        2 -> AndroidColor.rgb(255, 193, 7)
        3 -> AndroidColor.rgb(244, 67, 54)
        else -> AndroidColor.rgb(143, 145, 163)
    }
    val taskAction = actionStartActivity<MainActivity>(actionParametersOf(taskIdKey to task.id))

    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(widgetColor(AndroidColor.rgb(36, 37, 45)))
            .cornerRadius(12.dp)
            .clickable(taskAction)
            .padding(horizontal = 10.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            provider = ImageProvider(
                if (task.isCompleted) R.drawable.ic_widget_task_alt else R.drawable.ic_widget_circle_outlined,
            ),
            contentDescription = if (task.isCompleted) "Задача выполнена" else "Задача не выполнена",
            modifier = GlanceModifier.width(22.dp).height(22.dp),
            colorFilter = ColorFilter.tint(widgetColor(priorityColor)),
        )
        Spacer(modifier = GlanceModifier.width(9.dp))
        Column(modifier = GlanceModifier.defaultWeight()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = task.title,
                    modifier = GlanceModifier.defaultWeight(),
                    maxLines = 2,
                    style = TextStyle(
                        color = widgetColor(AndroidColor.rgb(245, 245, 250)),
                        fontSize = 13.sp,
                        fontWeight = if (task.isPinned) FontWeight.Bold else FontWeight.Normal,
                    ),
                )
//                Spacer(modifier = GlanceModifier.width(6.dp))
//                Text(
//                    text = when (task.priority) {
//                        1 -> "P1"
//                        2 -> "P2"
//                        3 -> "P3"
//                        else -> "—"
//                    },
//                    style = TextStyle(color = widgetColor(priorityColor), fontSize = 10.sp)
//                )
            }

            val hasSubtasksIndicator = task.subtasksCount > 0
            val hasDeadlineIndicator = task.deadlineMillis != null
            val hasAttachmentsIndicator = task.attachmentsCount > 0
            if (hasSubtasksIndicator || hasDeadlineIndicator || hasAttachmentsIndicator) {
                Spacer(modifier = GlanceModifier.height(3.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (hasSubtasksIndicator) {
                        TaskWidgetIndicator(
                            iconRes = R.drawable.ic_widget_checklist,
                            contentDescription = "Подзадачи",
                            value = "${task.completedSubtasksCount}/${task.subtasksCount}",
                        )
                    }

                    task.deadlineMillis?.let { deadlineMillis ->
                        if (hasSubtasksIndicator) Spacer(modifier = GlanceModifier.width(8.dp))
                        val deadlineColor = if (deadlineMillis < System.currentTimeMillis()) {
                            AndroidColor.rgb(255, 120, 120)
                        } else {
                            AndroidColor.rgb(164, 166, 179)
                        }
                        TaskWidgetIndicator(
                            iconRes = R.drawable.ic_widget_alarm,
                            contentDescription = "Срок выполнения",
                            value = formatDeadline(deadlineMillis),
                            color = widgetColor(deadlineColor),
                        )
                    }

                    if (hasAttachmentsIndicator) {
                        if (hasSubtasksIndicator || hasDeadlineIndicator) {
                            Spacer(modifier = GlanceModifier.width(8.dp))
                        }
                        TaskWidgetIndicator(
                            iconRes = R.drawable.ic_widget_attach_file,
                            contentDescription = "Вложения",
                            value = "${task.attachmentsCount}",
                        )
                    }
                }
            }
        }
    }
}

@GlanceComposable
@androidx.compose.runtime.Composable
private fun TaskWidgetIndicator(
    iconRes: Int,
    contentDescription: String,
    value: String,
    color: ColorProvider = widgetColor(AndroidColor.rgb(164, 166, 179)),
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Image(
            provider = ImageProvider(iconRes),
            contentDescription = contentDescription,
            modifier = GlanceModifier.size(14.dp),
            colorFilter = ColorFilter.tint(color),
        )
        Spacer(modifier = GlanceModifier.width(3.dp))
        Text(
            text = value,
            maxLines = 1,
            style = TextStyle(color = color, fontSize = 10.sp),
        )
    }
}

private fun formatDeadline(deadlineMillis: Long): String =
    SimpleDateFormat("d MMM", Locale.getDefault()).format(Date(deadlineMillis))

private fun widgetColor(color: Int): ColorProvider = androidx.glance.color.ColorProvider(Color(color), Color(color))
