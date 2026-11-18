package com.example.collab_tasks

import android.content.Context
import android.content.SharedPreferences
import java.util.*

internal data class GroupsWidgetNavigation(
    val requestId: String? = null,
    val openGroups: Boolean = false,
    val participantGroupId: String? = null,
    val participantId: String? = null,
    val taskGroupId: String? = null,
    val taskId: String? = null,
) {
    fun toMethodChannelArguments(): HashMap<String, Any?> = hashMapOf(
        "requestId" to requestId,
        "openGroups" to openGroups,
        "participantGroupId" to participantGroupId,
        "participantId" to participantId,
        "taskGroupId" to taskGroupId,
        "taskId" to taskId,
    )
}

internal interface GroupsWidgetNavigationPersistence {
    fun read(): GroupsWidgetNavigation?
    fun write(navigation: GroupsWidgetNavigation)
    fun clear()
}

internal class GroupsWidgetNavigationStore(
    private val persistence: GroupsWidgetNavigationPersistence,
    private val createRequestId: () -> String = { UUID.randomUUID().toString() },
) {
    constructor(context: Context) : this(
        SharedPreferencesGroupsWidgetNavigationPersistence(
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE),
        ),
    )

    fun enqueue(navigation: GroupsWidgetNavigation): GroupsWidgetNavigation {
        val identified = navigation.copy(requestId = createRequestId())
        persistence.write(identified)
        return identified
    }

    fun pending(): GroupsWidgetNavigation? = persistence.read()

    fun acknowledge(requestId: String): Boolean {
        if (persistence.read()?.requestId != requestId) return false
        persistence.clear()
        return true
    }

    companion object {
        private const val PREFERENCES = "groups_widget_navigation"
    }
}

private class SharedPreferencesGroupsWidgetNavigationPersistence(
    private val preferences: SharedPreferences,
) : GroupsWidgetNavigationPersistence {
    override fun read(): GroupsWidgetNavigation? {
        val requestId = preferences.getString(KEY_REQUEST_ID, null) ?: return null
        return GroupsWidgetNavigation(
            requestId = requestId,
            openGroups = preferences.getBoolean(KEY_OPEN_GROUPS, false),
            participantGroupId = preferences.getString(KEY_PARTICIPANT_GROUP_ID, null),
            participantId = preferences.getString(KEY_PARTICIPANT_ID, null),
            taskGroupId = preferences.getString(KEY_TASK_GROUP_ID, null),
            taskId = preferences.getString(KEY_TASK_ID, null),
        )
    }

    override fun write(navigation: GroupsWidgetNavigation) {
        val editor = preferences.edit()
        editor.putString(KEY_REQUEST_ID, navigation.requestId)
        editor.putBoolean(KEY_OPEN_GROUPS, navigation.openGroups)
        editor.putNullableString(KEY_PARTICIPANT_GROUP_ID, navigation.participantGroupId)
        editor.putNullableString(KEY_PARTICIPANT_ID, navigation.participantId)
        editor.putNullableString(KEY_TASK_GROUP_ID, navigation.taskGroupId)
        editor.putNullableString(KEY_TASK_ID, navigation.taskId)
        check(editor.commit()) { "Could not persist groups widget navigation request." }
    }

    override fun clear() {
        check(preferences.edit().clear().commit()) {
            "Could not acknowledge groups widget navigation request."
        }
    }

    private fun SharedPreferences.Editor.putNullableString(key: String, value: String?) {
        if (value == null) remove(key) else putString(key, value)
    }

    private companion object {
        const val KEY_REQUEST_ID = "request_id"
        const val KEY_OPEN_GROUPS = "open_groups"
        const val KEY_PARTICIPANT_GROUP_ID = "participant_group_id"
        const val KEY_PARTICIPANT_ID = "participant_id"
        const val KEY_TASK_GROUP_ID = "task_group_id"
        const val KEY_TASK_ID = "task_id"
    }
}
