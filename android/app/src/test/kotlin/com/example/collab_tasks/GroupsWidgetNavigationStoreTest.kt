package com.example.collab_tasks

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class GroupsWidgetNavigationStoreTest {
    @Test
    fun enqueueAssignsAnIdAndPersistsTheNavigationPayload() {
        val persistence = FakePersistence()
        val store = GroupsWidgetNavigationStore(persistence) { "request-1" }
        val navigation = GroupsWidgetNavigation(
            openGroups = false,
            participantGroupId = "group-1",
            participantId = "group-1:user-7",
        )

        val queued = store.enqueue(navigation)

        assertEquals("request-1", queued.requestId)
        assertEquals(queued, store.pending())
        assertEquals(queued, persistence.value)
        assertEquals(
            mapOf(
                "requestId" to "request-1",
                "openGroups" to false,
                "participantGroupId" to "group-1",
                "participantId" to "group-1:user-7",
                "taskGroupId" to null,
                "taskId" to null,
            ),
            queued.toMethodChannelArguments(),
        )
    }

    @Test
    fun acknowledgeClearsOnlyTheMatchingPendingRequest() {
        val persistence = FakePersistence()
        val store = GroupsWidgetNavigationStore(persistence) { "request-1" }
        store.enqueue(GroupsWidgetNavigation(openGroups = true))

        assertFalse(store.acknowledge("stale-request"))
        assertEquals("request-1", store.pending()?.requestId)

        assertTrue(store.acknowledge("request-1"))
        assertNull(store.pending())
    }

    @Test
    fun aNewerWidgetTapReplacesThePendingRequest() {
        val persistence = FakePersistence()
        val requestIds = iteratorOf("request-1", "request-2")
        val store = GroupsWidgetNavigationStore(persistence) { requestIds.next() }

        store.enqueue(GroupsWidgetNavigation(openGroups = true))
        val latest = store.enqueue(
            GroupsWidgetNavigation(taskGroupId = "group-2", taskId = "task-9"),
        )

        assertEquals("request-2", store.pending()?.requestId)
        assertEquals(latest, store.pending())
        assertFalse(store.acknowledge("request-1"))
        assertEquals(latest, store.pending())
    }

    private fun iteratorOf(vararg values: String): Iterator<String> = values.iterator()

    private class FakePersistence : GroupsWidgetNavigationPersistence {
        var value: GroupsWidgetNavigation? = null

        override fun read(): GroupsWidgetNavigation? = value

        override fun write(navigation: GroupsWidgetNavigation) {
            value = navigation
        }

        override fun clear() {
            value = null
        }
    }
}
