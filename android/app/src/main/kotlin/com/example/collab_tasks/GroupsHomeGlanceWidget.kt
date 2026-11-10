package com.example.collab_tasks

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.appwidget.updateAll
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import android.graphics.Color as AndroidColor

class GroupsHomeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = GroupsHomeGlanceWidget()
}

class GroupsHomeGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val cachedGroupsSnapshot = context
            .getSharedPreferences(GroupsHomeWidgetCache.PREFERENCES, Context.MODE_PRIVATE)
            .getString(GroupsHomeWidgetCache.GROUPS_KEY, "[]")

        provideContent {
            val preferences = currentState<Preferences>()
            val groupsSnapshot = preferences[groupsSnapshotKey] ?: cachedGroupsSnapshot ?: "[]"
            val expandedIds = preferences[expandedGroupsKey].orEmpty().split('|').filter(String::isNotBlank).toSet()
            GroupsWidgetContent(groupsSnapshot.toWidgetGroups(), expandedIds)
        }
    }
}

object GroupsHomeWidgetCache {
    const val PREFERENCES = "groups_home_widget"
    const val GROUPS_KEY = "groups_json"

    private val updateMutex = Mutex()

    suspend fun updateAllWidgets(context: Context) = updateMutex.withLock {
        val groupsSnapshot = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString(GROUPS_KEY, "[]") ?: "[]"
        val widget = GroupsHomeGlanceWidget()
        val glanceIds = GlanceAppWidgetManager(context).getGlanceIds(GroupsHomeGlanceWidget::class.java)

        glanceIds.forEach { glanceId ->
            updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { preferences ->
                preferences.toMutablePreferences().apply { this[groupsSnapshotKey] = groupsSnapshot }
            }
        }
        widget.updateAll(context)
    }
}

private val groupsSnapshotKey = stringPreferencesKey("groups_snapshot")
private val expandedGroupsKey = stringPreferencesKey("expanded_groups")
private val groupIdParameter = ActionParameters.Key<String>("group_id")
private val openGroupsParameter = ActionParameters.Key<Boolean>(MainActivity.EXTRA_GROUPS_OPEN_HOME)
private val participantGroupParameter = ActionParameters.Key<String>(MainActivity.EXTRA_GROUPS_PARTICIPANT_GROUP_ID)
private val participantIdParameter = ActionParameters.Key<String>(MainActivity.EXTRA_GROUPS_PARTICIPANT_ID)
private val taskGroupParameter = ActionParameters.Key<String>(MainActivity.EXTRA_GROUPS_TASK_GROUP_ID)
private val taskIdParameter = ActionParameters.Key<String>(MainActivity.EXTRA_GROUPS_TASK_ID)

class ToggleGroupExpansionAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val groupId = parameters[groupIdParameter] ?: return
        updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { preferences ->
            val expanded = preferences[expandedGroupsKey].orEmpty().split('|').filter(String::isNotBlank).toMutableSet()
            if (!expanded.add(groupId)) expanded.remove(groupId)
            preferences.toMutablePreferences().apply { this[expandedGroupsKey] = expanded.joinToString("|") }
        }
        GroupsHomeGlanceWidget().update(context, glanceId)
    }
}

private data class WidgetGroup(
    val id: String,
    val title: String,
    val description: String,
    val participants: List<WidgetParticipant>,
    val tasks: List<WidgetGroupTask>,
)

private data class WidgetParticipant(val id: String, val userId: String, val name: String)

private data class WidgetGroupTask(
    val id: String,
    val title: String,
    val priority: Int,
    val isCompleted: Boolean,
    val assignedUserName: String?,
)

private fun String?.toWidgetGroups(): List<WidgetGroup> = runCatching {
    val json = JSONArray(this ?: "[]")
    List(json.length()) { index ->
        val item = json.getJSONObject(index)
        val participantsJson = item.optJSONArray("participants") ?: JSONArray()
        val tasksJson = item.optJSONArray("tasks") ?: JSONArray()
        WidgetGroup(
            id = item.optString("id"),
            title = item.optString("title"),
            description = item.optString("description"),
            participants = List(participantsJson.length()) { participantIndex ->
                val participant = participantsJson.getJSONObject(participantIndex)
                WidgetParticipant(
                    id = participant.optString("id"),
                    userId = participant.optString("userId"),
                    name = participant.optString("name"),
                )
            },
            tasks = List(tasksJson.length()) { taskIndex ->
                val task = tasksJson.getJSONObject(taskIndex)
                WidgetGroupTask(
                    id = task.optString("id"),
                    title = task.optString("title"),
                    priority = task.optInt("priority"),
                    isCompleted = task.optBoolean("isCompleted"),
                    assignedUserName = task.optString("assignedUserName").takeIf(String::isNotBlank),
                )
            },
        )
    }
}.getOrDefault(emptyList())

@androidx.glance.GlanceComposable
@androidx.compose.runtime.Composable
private fun GroupsWidgetContent(groups: List<WidgetGroup>, expandedIds: Set<String>) {
    val openGroupsAction = actionStartActivity<MainActivity>(actionParametersOf(openGroupsParameter to true))
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(widgetColor(AndroidColor.rgb(21, 22, 28)))
            .padding(12.dp),
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth().clickable(openGroupsAction).padding(bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "Группы",
                style = TextStyle(
                    color = widgetColor(AndroidColor.rgb(245, 245, 250)),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                ),
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Text(
                text = groups.size.toString(),
                style = TextStyle(color = widgetColor(AndroidColor.rgb(160, 162, 176)), fontSize = 14.sp),
            )
        }

        if (groups.isEmpty()) {
            Box(
                modifier = GlanceModifier.defaultWeight().fillMaxWidth().clickable(openGroupsAction),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Нет групп",
                    style = TextStyle(color = widgetColor(AndroidColor.rgb(160, 162, 176)), fontSize = 13.sp)
                )
            }
        } else {
            Box(modifier = GlanceModifier.defaultWeight().fillMaxWidth().clickable(openGroupsAction)) {
                LazyColumn(modifier = GlanceModifier.fillMaxWidth()) {
                    items(items = groups, itemId = { it.id.hashCode().toLong() }) { group ->
                        GroupWidgetSection(group, group.id in expandedIds)
                    }
                }
            }
        }
    }
}

@androidx.glance.GlanceComposable
@androidx.compose.runtime.Composable
private fun GroupWidgetSection(group: WidgetGroup, isExpanded: Boolean) {
    val toggleAction = actionRunCallback<ToggleGroupExpansionAction>(actionParametersOf(groupIdParameter to group.id))
    Column(
        modifier = GlanceModifier.fillMaxWidth().padding(top = 7.dp)
            .background(widgetColor(AndroidColor.rgb(36, 37, 45))).cornerRadius(12.dp),
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth().clickable(toggleAction)
                .padding(horizontal = 11.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("▦", style = TextStyle(color = widgetColor(AndroidColor.rgb(160, 170, 255)), fontSize = 18.sp))
            Spacer(modifier = GlanceModifier.width(9.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    group.title,
                    maxLines = 1,
                    style = TextStyle(
                        color = widgetColor(AndroidColor.rgb(245, 245, 250)),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
                if (group.description.isNotBlank()) {
                    Text(
                        group.description,
                        maxLines = 1,
                        style = TextStyle(color = widgetColor(AndroidColor.rgb(160, 162, 176)), fontSize = 10.sp)
                    )
                }
            }
            Text(
                if (isExpanded) "⌃" else "⌄",
                style = TextStyle(color = widgetColor(AndroidColor.rgb(180, 182, 198)), fontSize = 16.sp)
            )
        }

        if (isExpanded) {
            SectionHeading("Участники (${group.participants.size})")
            if (group.participants.isEmpty()) {
                SectionEmpty("Нет участников")
            } else {
                group.participants.forEach { participant -> ParticipantWidgetRow(group.id, participant) }
            }

            SectionHeading("Задачи (${group.tasks.size})")
            if (group.tasks.isEmpty()) {
                SectionEmpty("Нет задач")
            } else {
                group.tasks.forEach { task -> GroupTaskWidgetRow(group.id, task) }
            }
        }
    }
}

@androidx.glance.GlanceComposable
@androidx.compose.runtime.Composable
private fun SectionHeading(title: String) {
    Text(
        text = title,
        modifier = GlanceModifier.fillMaxWidth().padding(start = 11.dp, top = 3.dp, end = 11.dp, bottom = 4.dp),
        style = TextStyle(
            color = widgetColor(AndroidColor.rgb(174, 177, 199)),
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold
        ),
    )
}

@androidx.glance.GlanceComposable
@androidx.compose.runtime.Composable
private fun SectionEmpty(text: String) {
    Text(
        text,
        modifier = GlanceModifier.padding(start = 12.dp, end = 12.dp, bottom = 7.dp),
        style = TextStyle(color = widgetColor(AndroidColor.rgb(130, 132, 148)), fontSize = 10.sp)
    )
}

@androidx.glance.GlanceComposable
@androidx.compose.runtime.Composable
private fun ParticipantWidgetRow(groupId: String, participant: WidgetParticipant) {
    val action = actionStartActivity<MainActivity>(
        actionParametersOf(
            participantGroupParameter to groupId,
            participantIdParameter to participant.id,
        )
    )
    Row(
        modifier = GlanceModifier.fillMaxWidth().clickable(action)
            .padding(start = 11.dp, end = 11.dp, top = 4.dp, bottom = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = GlanceModifier.size(25.dp).background(widgetColor(AndroidColor.rgb(62, 66, 87)))
                .cornerRadius(13.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                participant.name.initials(),
                style = TextStyle(
                    color = widgetColor(AndroidColor.rgb(224, 226, 255)),
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold
                )
            )
        }
        Spacer(modifier = GlanceModifier.width(8.dp))
        Text(
            participant.name,
            maxLines = 1,
            modifier = GlanceModifier.defaultWeight(),
            style = TextStyle(color = widgetColor(AndroidColor.rgb(230, 231, 239)), fontSize = 12.sp)
        )
        Text("›", style = TextStyle(color = widgetColor(AndroidColor.rgb(130, 132, 148)), fontSize = 17.sp))
    }
}

@androidx.glance.GlanceComposable
@androidx.compose.runtime.Composable
private fun GroupTaskWidgetRow(groupId: String, task: WidgetGroupTask) {
    val action =
        actionStartActivity<MainActivity>(actionParametersOf(taskGroupParameter to groupId, taskIdParameter to task.id))
    val priorityColor = when (task.priority) {
        1 -> AndroidColor.rgb(76, 175, 80)
        2 -> AndroidColor.rgb(255, 193, 7)
        3 -> AndroidColor.rgb(244, 67, 54)
        else -> AndroidColor.rgb(143, 145, 163)
    }
    Row(
        modifier = GlanceModifier.fillMaxWidth().clickable(action)
            .padding(start = 12.dp, end = 11.dp, top = 4.dp, bottom = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            if (task.isCompleted) "✓" else "○",
            style = TextStyle(color = widgetColor(priorityColor), fontSize = 14.sp)
        )
        Spacer(modifier = GlanceModifier.width(8.dp))
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(
                task.title,
                maxLines = 1,
                style = TextStyle(color = widgetColor(AndroidColor.rgb(230, 231, 239)), fontSize = 12.sp)
            )
            task.assignedUserName?.let {
                Text(
                    "Исполнитель: $it",
                    maxLines = 1,
                    style = TextStyle(color = widgetColor(AndroidColor.rgb(145, 147, 164)), fontSize = 9.sp)
                )
            }
        }
        Text("›", style = TextStyle(color = widgetColor(AndroidColor.rgb(130, 132, 148)), fontSize = 17.sp))
    }
}

private fun String.initials(): String = trim().split(Regex("\\s+")).filter(String::isNotBlank)
    .take(2).mapNotNull { it.firstOrNull()?.uppercaseChar() }.joinToString("").ifBlank { "?" }

private fun widgetColor(color: Int): ColorProvider = ColorProvider(Color(color))
