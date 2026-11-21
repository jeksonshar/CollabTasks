package com.example.collab_tasks

import org.junit.Assert.*
import org.junit.Test

class GroupsWidgetContentModelTest {
    @Test
    fun collapsedGroupsContainOnlyTheirHeadersInInputOrder() {
        val first = group("group-1")
        val second = group("group-2")

        val rows = GroupsWidgetContentModel.rows(listOf(first, second), emptySet())

        assertEquals(
            listOf(
                GroupsWidgetRow.GroupHeader(first, isExpanded = false),
                GroupsWidgetRow.GroupHeader(second, isExpanded = false),
            ),
            rows,
        )
    }

    @Test
    fun expandedRowsPlaceParticipantsBeforeTasksAndKeepGroupsOrdered() {
        val participant = WidgetParticipant("participant-1", "user-1", "Alex", false)
        val task = WidgetGroupTask("task-1", "Prepare release", 2, false, "Alex")
        val first = group("group-1", participants = listOf(participant), tasks = listOf(task))
        val second = group("group-2")

        val rows = GroupsWidgetContentModel.rows(listOf(first, second), setOf("group-1"))

        assertEquals(
            listOf(
                GroupsWidgetRow.GroupHeader(first, isExpanded = true),
                GroupsWidgetRow.ParticipantsHeading("group-1", count = 1),
                GroupsWidgetRow.Participant("group-1", participant),
                GroupsWidgetRow.TasksHeading("group-1", count = 1),
                GroupsWidgetRow.Task("group-1", task),
                GroupsWidgetRow.GroupHeader(second, isExpanded = false),
            ),
            rows,
        )
        val participantIndex = rows.indexOfFirst { it is GroupsWidgetRow.Participant }
        val taskIndex = rows.indexOfFirst { it is GroupsWidgetRow.Task }
        assertTrue(participantIndex < taskIndex)
        assertFalse(rows.any { it is GroupsWidgetRow.Participant && it.groupId == "group-2" })
        val itemIds = rows.map { it.key.toGlanceItemId() }
        assertTrue(itemIds.all { it >= 0L })
        assertEquals(itemIds.size, itemIds.toSet().size)
    }

    @Test
    fun expandedEmptyGroupStillHasBothSectionHeadingsAndEmptyRows() {
        val emptyGroup = group("group-empty")

        val rows = GroupsWidgetContentModel.rows(listOf(emptyGroup), setOf(emptyGroup.id))

        assertEquals(
            listOf(
                GroupsWidgetRow.GroupHeader(emptyGroup, isExpanded = true),
                GroupsWidgetRow.ParticipantsHeading(emptyGroup.id, count = 0),
                GroupsWidgetRow.ParticipantsEmpty(emptyGroup.id),
                GroupsWidgetRow.TasksHeading(emptyGroup.id, count = 0),
                GroupsWidgetRow.TasksEmpty(emptyGroup.id),
            ),
            rows,
        )
    }

    private fun group(
        id: String,
        participants: List<WidgetParticipant> = emptyList(),
        tasks: List<WidgetGroupTask> = emptyList(),
    ) = WidgetGroup(
        id = id,
        title = "Group $id",
        description = "",
        participants = participants,
        tasks = tasks,
    )
}
