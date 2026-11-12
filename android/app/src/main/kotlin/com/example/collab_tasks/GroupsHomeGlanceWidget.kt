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
            val widgetContext = WidgetLocalization.localizedContext(context, preferences[groupsWidgetLocaleKey])
            val expandedIds = preferences[expandedGroupsKey].orEmpty().split('|').filter(String::isNotBlank).toSet()
            GroupsWidgetContent(widgetContext, groupsSnapshot.toWidgetGroups(), expandedIds)
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
                preferences.toMutablePreferences().apply {
                    this[groupsSnapshotKey] = groupsSnapshot
                    this[groupsWidgetLocaleKey] = WidgetLocalization.languageCode(context)
                }
            }
        }
        widget.updateAll(context)
    }

    suspend fun updateLocale(context: Context, languageCode: String) = updateMutex.withLock {
        val groupsSnapshot = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString(GROUPS_KEY, "[]") ?: "[]"
        val glanceIds = GlanceAppWidgetManager(context).getGlanceIds(GroupsHomeGlanceWidget::class.java)
        val widget = GroupsHomeGlanceWidget()
        glanceIds.forEach { glanceId ->
            updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { preferences ->
                preferences.toMutablePreferences().apply {
                    this[groupsSnapshotKey] = groupsSnapshot
                    this[groupsWidgetLocaleKey] = languageCode
                }
            }
            widget.update(context, glanceId)
        }
    }
}

private val groupsSnapshotKey = stringPreferencesKey("groups_snapshot")
private val groupsWidgetLocaleKey = stringPreferencesKey("widget_locale")
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

private data class WidgetParticipant(
    val id: String,
    val userId: String,
    val name: String,
    val isCurrentUser: Boolean,
)

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
                    isCurrentUser = participant.optBoolean("isCurrentUser"),
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

@GlanceComposable
@androidx.compose.runtime.Composable
private fun GroupsWidgetContent(context: Context, groups: List<WidgetGroup>, expandedIds: Set<String>) {
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
                text = context.getString(R.string.widget_groups_title),
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
                    context.getString(R.string.widget_groups_empty),
                    style = TextStyle(color = widgetColor(AndroidColor.rgb(160, 162, 176)), fontSize = 13.sp)
                )
            }
        } else {
            Box(modifier = GlanceModifier.defaultWeight().fillMaxWidth().clickable(openGroupsAction)) {
                LazyColumn(modifier = GlanceModifier.fillMaxWidth()) {
                    items(items = groups, itemId = { it.id.hashCode().toLong() }) { group ->
                        Box(
                            modifier = GlanceModifier.fillMaxWidth().padding(top = 8.dp)
                        ) {
                            GroupWidgetSection(context, group, group.id in expandedIds)
                        }
                    }
                }
            }
        }
    }
}

@GlanceComposable
@androidx.compose.runtime.Composable
private fun GroupWidgetSection(context: Context, group: WidgetGroup, isExpanded: Boolean) {
    val toggleAction = actionRunCallback<ToggleGroupExpansionAction>(actionParametersOf(groupIdParameter to group.id))
    Column(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(widgetColor(AndroidColor.rgb(36, 37, 45)))
            .cornerRadius(12.dp),
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth().clickable(toggleAction)
                .padding(horizontal = 11.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Image(
                provider = ImageProvider(R.drawable.ic_widget_groups),
                contentDescription = context.getString(R.string.widget_group_accessibility),
                modifier = GlanceModifier.size(18.dp),
                colorFilter = ColorFilter.tint(widgetColor(AndroidColor.rgb(160, 170, 255))),
            )
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
            Image(
                provider = ImageProvider(
                    if (isExpanded) R.drawable.ic_widget_keyboard_arrow_up
                    else R.drawable.ic_widget_keyboard_arrow_down,
                ),
                contentDescription = context.getString(
                    if (isExpanded) R.string.widget_group_collapse else R.string.widget_group_expand,
                ),
                modifier = GlanceModifier.size(20.dp),
                colorFilter = ColorFilter.tint(widgetColor(AndroidColor.rgb(180, 182, 198))),
            )
        }

        if (isExpanded) {
            SectionHeading(
                context.resources.getQuantityString(
                    R.plurals.widget_participants_count,
                    group.participants.size,
                    group.participants.size,
                ),
            )
            if (group.participants.isEmpty()) {
                SectionEmpty(context.getString(R.string.widget_participants_empty))
            } else {
                group.participants.forEach { participant -> ParticipantWidgetRow(group.id, participant) }
            }

            SectionHeading(
                context.resources.getQuantityString(
                    R.plurals.widget_group_tasks_count,
                    group.tasks.size,
                    group.tasks.size,
                ),
            )
            if (group.tasks.isEmpty()) {
                SectionEmpty(context.getString(R.string.widget_group_tasks_empty))
            } else {
                group.tasks.forEach { task -> GroupTaskWidgetRow(context, group.id, task) }
            }
        }
    }
}

@GlanceComposable
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

@GlanceComposable
@androidx.compose.runtime.Composable
private fun SectionEmpty(text: String) {
    Text(
        text,
        modifier = GlanceModifier.padding(start = 12.dp, end = 12.dp, bottom = 7.dp),
        style = TextStyle(color = widgetColor(AndroidColor.rgb(130, 132, 148)), fontSize = 10.sp)
    )
}

@GlanceComposable
@androidx.compose.runtime.Composable
private fun ParticipantWidgetRow(groupId: String, participant: WidgetParticipant) {
    val action = actionStartActivity<MainActivity>(
        actionParametersOf(
            participantGroupParameter to groupId,
            participantIdParameter to participant.id,
        )
    )
    val rowModifier = GlanceModifier.fillMaxWidth()
        .padding(start = 11.dp, end = 11.dp, top = 4.dp, bottom = 5.dp)
    Row(
        modifier = if (participant.isCurrentUser) rowModifier else rowModifier.clickable(action),
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
        if (!participant.isCurrentUser) {
            Image(
                provider = ImageProvider(R.drawable.ic_widget_chevron_right),
                contentDescription = null,
                modifier = GlanceModifier.size(16.dp),
                colorFilter = ColorFilter.tint(widgetColor(AndroidColor.rgb(130, 132, 148))),
            )
        }
    }
}

@GlanceComposable
@androidx.compose.runtime.Composable
private fun GroupTaskWidgetRow(context: Context, groupId: String, task: WidgetGroupTask) {
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
        Image(
            provider = ImageProvider(
                if (task.isCompleted) R.drawable.ic_widget_task_alt else R.drawable.ic_widget_circle_outlined,
            ),
            contentDescription = context.getString(
                if (task.isCompleted) R.string.widget_task_completed else R.string.widget_task_not_completed,
            ),
            modifier = GlanceModifier.size(16.dp),
            colorFilter = ColorFilter.tint(widgetColor(priorityColor)),
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
                    context.getString(R.string.widget_task_assignee, it),
                    maxLines = 1,
                    style = TextStyle(color = widgetColor(AndroidColor.rgb(145, 147, 164)), fontSize = 9.sp)
                )
            }
        }
        Image(
            provider = ImageProvider(R.drawable.ic_widget_chevron_right),
            contentDescription = null,
            modifier = GlanceModifier.size(16.dp),
            colorFilter = ColorFilter.tint(widgetColor(AndroidColor.rgb(130, 132, 148))),
        )
    }
}

private fun String.initials(): String = trim().split(Regex("\\s+")).filter(String::isNotBlank)
    .take(2).mapNotNull { it.firstOrNull()?.uppercaseChar() }.joinToString("").ifBlank { "?" }

private fun widgetColor(color: Int): ColorProvider = androidx.glance.color.ColorProvider(Color(color), Color(color))
