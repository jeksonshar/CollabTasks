package com.example.collab_tasks

internal data class WidgetGroup(
    val id: String,
    val title: String,
    val description: String,
    val participants: List<WidgetParticipant>,
    val tasks: List<WidgetGroupTask>,
)

internal data class WidgetParticipant(
    val id: String,
    val userId: String,
    val name: String,
    val isCurrentUser: Boolean,
)

internal data class WidgetGroupTask(
    val id: String,
    val title: String,
    val priority: Int,
    val isCompleted: Boolean,
    val assignedUserName: String?,
)

internal sealed interface GroupsWidgetRow {
    val key: String

    data class GroupHeader(val group: WidgetGroup, val isExpanded: Boolean) : GroupsWidgetRow {
        override val key: String = "${group.id}:header"
    }

    data class ParticipantsHeading(val groupId: String, val count: Int) : GroupsWidgetRow {
        override val key: String = "$groupId:participants:heading"
    }

    data class Participant(val groupId: String, val participant: WidgetParticipant) : GroupsWidgetRow {
        override val key: String = "$groupId:participant:${participant.id}"
    }

    data class ParticipantsEmpty(val groupId: String) : GroupsWidgetRow {
        override val key: String = "$groupId:participants:empty"
    }

    data class TasksHeading(val groupId: String, val count: Int) : GroupsWidgetRow {
        override val key: String = "$groupId:tasks:heading"
    }

    data class Task(val groupId: String, val task: WidgetGroupTask) : GroupsWidgetRow {
        override val key: String = "$groupId:task:${task.id}"
    }

    data class TasksEmpty(val groupId: String) : GroupsWidgetRow {
        override val key: String = "$groupId:tasks:empty"
    }
}

internal object GroupsWidgetContentModel {
    fun rows(groups: List<WidgetGroup>, expandedGroupIds: Set<String>): List<GroupsWidgetRow> = buildList {
        groups.forEach { group ->
            val isExpanded = group.id in expandedGroupIds
            add(GroupsWidgetRow.GroupHeader(group, isExpanded))
            if (!isExpanded) return@forEach

            add(GroupsWidgetRow.ParticipantsHeading(group.id, group.participants.size))
            if (group.participants.isEmpty()) {
                add(GroupsWidgetRow.ParticipantsEmpty(group.id))
            } else {
                group.participants.forEach { add(GroupsWidgetRow.Participant(group.id, it)) }
            }

            add(GroupsWidgetRow.TasksHeading(group.id, group.tasks.size))
            if (group.tasks.isEmpty()) {
                add(GroupsWidgetRow.TasksEmpty(group.id))
            } else {
                group.tasks.forEach { add(GroupsWidgetRow.Task(group.id, it)) }
            }
        }
    }
}

internal fun String.toGlanceItemId(): Long = fold(-3750763034362895579L) { hash, character ->
    (hash xor character.code.toLong()) * 1099511628211L
}.and(Long.MAX_VALUE)
