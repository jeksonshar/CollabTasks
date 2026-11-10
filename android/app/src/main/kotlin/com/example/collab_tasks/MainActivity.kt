package com.example.collab_tasks

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.collab_tasks/task_widget"
    private val groupsChannelName = "com.collab_tasks/groups_widget"
    private var taskWidgetChannel: MethodChannel? = null
    private var groupsWidgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        taskWidgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        taskWidgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeInitialWidgetNavigation" -> {
                    val taskId = intent?.getStringExtra(EXTRA_TASK_ID)
                    val openHome = intent?.getBooleanExtra(EXTRA_OPEN_HOME, false) == true
                    val refreshTasks = intent?.getBooleanExtra(EXTRA_REFRESH_TASKS, false) == true
                    val navigation = if (taskId != null || openHome || refreshTasks) {
                        hashMapOf<String, Any?>(
                            "taskId" to taskId,
                            "openHome" to openHome,
                            "refreshTasks" to refreshTasks,
                        )
                    } else {
                        null
                    }
                    intent?.removeExtra(EXTRA_TASK_ID)
                    intent?.removeExtra(EXTRA_OPEN_HOME)
                    intent?.removeExtra(EXTRA_REFRESH_TASKS)
                    result.success(navigation)
                }

                "updateTasks" -> {
                    val tasksJson = call.arguments as? String ?: "[]"
                    getSharedPreferences(TaskHomeWidgetCache.PREFERENCES, MODE_PRIVATE)
                        .edit()
                        .putString(TaskHomeWidgetCache.TASKS_KEY, tasksJson)
                        .apply()
                    CoroutineScope(Dispatchers.IO).launch {
                        TaskHomeWidgetCache.updateAllWidgets(applicationContext)
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        groupsWidgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, groupsChannelName)
        groupsWidgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeInitialGroupsWidgetNavigation" -> {
                    val navigation = groupsWidgetNavigation(intent)
                    clearGroupsWidgetNavigation(intent)
                    result.success(navigation)
                }

                "updateGroups" -> {
                    val groupsJson = call.arguments as? String ?: "[]"
                    getSharedPreferences(GroupsHomeWidgetCache.PREFERENCES, MODE_PRIVATE)
                        .edit()
                        .putString(GroupsHomeWidgetCache.GROUPS_KEY, groupsJson)
                        .apply()
                    CoroutineScope(Dispatchers.IO).launch {
                        GroupsHomeWidgetCache.updateAllWidgets(applicationContext)
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val openHome = intent.getBooleanExtra(EXTRA_OPEN_HOME, false)
        val refreshTasks = intent.getBooleanExtra(EXTRA_REFRESH_TASKS, false)
        val taskId = intent.getStringExtra(EXTRA_TASK_ID)
        if (openHome) {
            taskWidgetChannel?.invokeMethod("openHome", null)
        } else if (refreshTasks) {
            taskWidgetChannel?.invokeMethod("refreshTasks", null)
        } else if (taskId != null) {
            taskWidgetChannel?.invokeMethod("openTask", taskId)
        }
        intent.removeExtra(EXTRA_OPEN_HOME)
        intent.removeExtra(EXTRA_REFRESH_TASKS)
        intent.removeExtra(EXTRA_TASK_ID)

        val groupsNavigation = groupsWidgetNavigation(intent)
        if (groupsNavigation != null) {
            groupsWidgetChannel?.invokeMethod("widgetNavigation", groupsNavigation)
            clearGroupsWidgetNavigation(intent)
        }
    }

    private fun groupsWidgetNavigation(sourceIntent: Intent?): HashMap<String, Any?>? {
        val openGroups = sourceIntent?.getBooleanExtra(EXTRA_GROUPS_OPEN_HOME, false) == true
        val participantGroupId = sourceIntent?.getStringExtra(EXTRA_GROUPS_PARTICIPANT_GROUP_ID)
        val participantId = sourceIntent?.getStringExtra(EXTRA_GROUPS_PARTICIPANT_ID)
        val taskGroupId = sourceIntent?.getStringExtra(EXTRA_GROUPS_TASK_GROUP_ID)
        val taskId = sourceIntent?.getStringExtra(EXTRA_GROUPS_TASK_ID)
        if (!openGroups && participantGroupId == null && taskGroupId == null) return null
        return hashMapOf(
            "openGroups" to openGroups,
            "participantGroupId" to participantGroupId,
            "participantId" to participantId,
            "taskGroupId" to taskGroupId,
            "taskId" to taskId,
        )
    }

    private fun clearGroupsWidgetNavigation(sourceIntent: Intent?) {
        sourceIntent?.removeExtra(EXTRA_GROUPS_OPEN_HOME)
        sourceIntent?.removeExtra(EXTRA_GROUPS_PARTICIPANT_GROUP_ID)
        sourceIntent?.removeExtra(EXTRA_GROUPS_PARTICIPANT_ID)
        sourceIntent?.removeExtra(EXTRA_GROUPS_TASK_GROUP_ID)
        sourceIntent?.removeExtra(EXTRA_GROUPS_TASK_ID)
    }

    companion object {
        const val EXTRA_TASK_ID = "com.collab_tasks.extra.TASK_ID"
        const val EXTRA_OPEN_HOME = "com.collab_tasks.extra.OPEN_HOME"
        const val EXTRA_REFRESH_TASKS = "com.collab_tasks.extra.REFRESH_TASKS"
        const val EXTRA_GROUPS_OPEN_HOME = "com.collab_tasks.extra.GROUPS_OPEN_HOME"
        const val EXTRA_GROUPS_PARTICIPANT_GROUP_ID = "com.collab_tasks.extra.GROUPS_PARTICIPANT_GROUP_ID"
        const val EXTRA_GROUPS_PARTICIPANT_ID = "com.collab_tasks.extra.GROUPS_PARTICIPANT_ID"
        const val EXTRA_GROUPS_TASK_GROUP_ID = "com.collab_tasks.extra.GROUPS_TASK_GROUP_ID"
        const val EXTRA_GROUPS_TASK_ID = "com.collab_tasks.extra.GROUPS_TASK_ID"
    }
}
