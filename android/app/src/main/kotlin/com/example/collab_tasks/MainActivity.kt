package com.example.collab_tasks

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Log
import android.util.Rational
import androidx.core.content.ContextCompat
import androidx.core.content.edit
import io.agora.agora_rtc_ng.AgoraPIPFlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.*

class MainActivity : AgoraPIPFlutterFragmentActivity() {
    private val channelName = "com.collab_tasks/task_widget"
    private val groupsChannelName = "com.collab_tasks/groups_widget"
    private var taskWidgetChannel: MethodChannel? = null
    private var groupsWidgetChannel: MethodChannel? = null
    private var callPictureInPictureEventSink: EventChannel.EventSink? = null
    private var callPictureInPictureConfigured = false
    private var isGroupPictureInPictureCall = false
    private var isCallMicrophoneMuted = false
    private var audioPictureInPicturePrepared = false
    private var callPictureInPictureParams: PictureInPictureParams? = null
    private var callPictureInPictureReceiverRegistered = false

    private val callPictureInPictureReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = when (intent?.action) {
                ACTION_PIP_TOGGLE_MICROPHONE -> "toggleMicrophone"
                ACTION_PIP_END_CALL -> if (isGroupPictureInPictureCall) "leaveCall" else "endCall"
                else -> return
            }
            callPictureInPictureEventSink?.success(mapOf("type" to "action", "action" to action))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        taskWidgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_PICTURE_IN_PICTURE_EVENTS_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                callPictureInPictureEventSink = events
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    events.success(
                        mapOf(
                            "type" to "modeChanged",
                            "isInPictureInPicture" to isInPictureInPictureMode,
                        ),
                    )
                }
            }

            override fun onCancel(arguments: Any?) {
                callPictureInPictureEventSink = null
            }
        })
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_PICTURE_IN_PICTURE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "configureCallActions" -> {
                    val arguments = call.arguments as? Map<*, *>
                    isGroupPictureInPictureCall = arguments?.get("isGroup") as? Boolean == true
                    isCallMicrophoneMuted = arguments?.get("isMicrophoneMuted") as? Boolean == true
                    audioPictureInPicturePrepared = false
                    callPictureInPictureConfigured = true
                    result.success(true)
                }
// for video calls prepare PiP execute by Agora (AgoraPipController), for audio calls Agora PiP-controller doesn't use
                "prepareAudioPictureInPicture" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.success(false)
                    } else {
                        try {
                            val parameters = buildAudioPictureInPictureParams(autoEnterEnabled = true)
                            callPictureInPictureParams = parameters
                            audioPictureInPicturePrepared = true
                            setPictureInPictureParams(parameters)
                            result.success(true)
                        } catch (error: IllegalArgumentException) {
                            audioPictureInPicturePrepared = false
                            Log.e(TAG_CALL_PIP, "Failed to prepare audio PiP parameters", error)
                            result.success(false)
                        }
                    }
                }

                "updateCallMicrophoneState" -> {
                    val arguments = call.arguments as? Map<*, *>
                    isCallMicrophoneMuted = arguments?.get("isMicrophoneMuted") as? Boolean == true
                    callPictureInPictureParams?.let(::applyCallPictureInPictureParams)
                    result.success(null)
                }

                "startCallBackgroundService" -> {
                    val arguments = call.arguments as? Map<*, *>
                    val serviceIntent = Intent(this, CallBackgroundService::class.java).apply {
                        putExtra(
                            CallBackgroundService.EXTRA_DISPLAY_NAME,
                            arguments?.get("displayName") as? String,
                        )
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            ContextCompat.startForegroundService(this, serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("call_background_service_start_failed", error.message, null)
                    }
                }

                "stopCallBackgroundService" -> {
                    audioPictureInPicturePrepared = false
                    stopService(Intent(this, CallBackgroundService::class.java))
                    result.success(null)
                }

                "enterAudioPictureInPicture" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.success(false)
                    } else {
                        try {
                            if (isInPictureInPictureMode) {
                                result.success(true)
                                return@setMethodCallHandler
                            }
                            val parameters = buildAudioPictureInPictureParams()
                            callPictureInPictureParams = parameters
                            result.success(enterPictureInPictureMode(parameters))
                        } catch (_: IllegalArgumentException) {
                            Log.w(TAG_CALL_PIP, "Android rejected audio PiP entry")
                            result.success(false)
                        }
                    }
                }

                "dismissCallPictureInPicture" -> {
                    val shouldFinish = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            isInPictureInPictureMode
                    callPictureInPictureParams = null
                    audioPictureInPicturePrepared = false
                    result.success(null)
                    if (shouldFinish) {
                        window.decorView.post {
                            if (!isFinishing && isInPictureInPictureMode) finish()
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
        registerCallPictureInPictureReceiver()
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
                        .edit {
                            putString(TaskHomeWidgetCache.TASKS_KEY, tasksJson)
                        }
                    CoroutineScope(Dispatchers.IO).launch {
                        TaskHomeWidgetCache.updateAllWidgets(applicationContext)
                    }
                    result.success(null)
                }

                "setWidgetLocale" -> {
                    val languageCode = call.arguments as? String
                    val supportedLanguage = languageCode?.takeIf { it in SUPPORTED_WIDGET_LANGUAGES } ?: "en"
                    WidgetLocalization.saveLanguage(applicationContext, supportedLanguage)
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            TaskHomeWidgetCache.updateLocale(applicationContext, supportedLanguage)
                            GroupsHomeWidgetCache.updateLocale(applicationContext, supportedLanguage)
                            withContext(Dispatchers.Main) { result.success(null) }
                        } catch (error: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("widget_locale_update_failed", error.message, null)
                            }
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }

        groupsWidgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, groupsChannelName)
        groupsWidgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeInitialGroupsWidgetNavigation" -> {
                    val store = groupsWidgetNavigationStore()
                    val navigation = groupsWidgetNavigation(intent)?.let { incoming ->
                        store.enqueue(incoming).also { clearGroupsWidgetNavigation(intent) }
                    } ?: store.pending()
                    result.success(navigation?.toMethodChannelArguments())
                }

                "acknowledgeGroupsWidgetNavigation" -> {
                    val requestId = call.arguments as? String
                    result.success(
                        requestId != null && groupsWidgetNavigationStore().acknowledge(requestId),
                    )
                }

                "updateGroups" -> {
                    val groupsJson = call.arguments as? String ?: "[]"
                    getSharedPreferences(GroupsHomeWidgetCache.PREFERENCES, MODE_PRIVATE)
                        .edit {
                            putString(GroupsHomeWidgetCache.GROUPS_KEY, groupsJson)
                        }
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
            val pendingNavigation = groupsWidgetNavigationStore().enqueue(groupsNavigation)
            clearGroupsWidgetNavigation(intent)
            groupsWidgetChannel?.invokeMethod(
                "widgetNavigation",
                pendingNavigation.toMethodChannelArguments(),
            )
        }
    }

    override fun setPictureInPictureParams(params: PictureInPictureParams) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || !callPictureInPictureConfigured) {
            super.setPictureInPictureParams(params)
            return
        }

        callPictureInPictureParams = params
        applyCallPictureInPictureParams(params)
    }

    private fun applyCallPictureInPictureParams(params: PictureInPictureParams) {
        val builder = PictureInPictureParams.Builder()
        params.aspectRatio?.let { builder.setAspectRatio(it) }
        params.sourceRectHint?.let { builder.setSourceRectHint(it) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(params.isAutoEnterEnabled)
        }
        builder.setActions(pictureInPictureActions())
        super.setPictureInPictureParams(builder.build())
    }

    private fun buildAudioPictureInPictureParams(
        autoEnterEnabled: Boolean = false,
    ): PictureInPictureParams {
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(10, 16))
            .setActions(pictureInPictureActions())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(autoEnterEnabled)
        }
        return builder.build()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        callPictureInPictureEventSink?.success(
            mapOf(
                "type" to "modeChanged",
                "isInPictureInPicture" to isInPictureInPictureMode,
            ),
        )
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ||
            !audioPictureInPicturePrepared ||
            isInPictureInPictureMode
        ) return

        val parameters = callPictureInPictureParams ?: return
        try {
            if (!enterPictureInPictureMode(parameters)) {
                Log.w(TAG_CALL_PIP, "Android declined legacy audio PiP entry")
            }
        } catch (error: IllegalArgumentException) {
            Log.e(TAG_CALL_PIP, "Failed to enter legacy audio PiP", error)
        }
    }

    override fun onDestroy() {
        if (callPictureInPictureReceiverRegistered) {
            unregisterReceiver(callPictureInPictureReceiver)
            callPictureInPictureReceiverRegistered = false
        }
        super.onDestroy()
    }

    private fun registerCallPictureInPictureReceiver() {
        if (callPictureInPictureReceiverRegistered) return
        val filter = IntentFilter().apply {
            addAction(ACTION_PIP_TOGGLE_MICROPHONE)
            addAction(ACTION_PIP_END_CALL)
        }
        ContextCompat.registerReceiver(
            this,
            callPictureInPictureReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        callPictureInPictureReceiverRegistered = true
    }

    private fun pictureInPictureActions(): List<RemoteAction> {
        val localizedContext = WidgetLocalization.localizedContext(applicationContext)
        val microphoneLabel = localizedContext.getString(
            if (isCallMicrophoneMuted) R.string.call_pip_unmute_microphone
            else R.string.call_pip_mute_microphone,
        )
        val microphoneIcon = if (isCallMicrophoneMuted) {
            R.drawable.ic_pip_mic_off
        } else {
            R.drawable.ic_pip_mic
        }
        val endLabel = localizedContext.getString(
            if (isGroupPictureInPictureCall) R.string.call_pip_leave_call else R.string.call_pip_end_call,
        )
        return listOf(
            RemoteAction(
                Icon.createWithResource(this, microphoneIcon),
                microphoneLabel,
                microphoneLabel,
                pictureInPictureBroadcastPendingIntent(ACTION_PIP_TOGGLE_MICROPHONE, 702),
            ),
            RemoteAction(
                Icon.createWithResource(this, R.drawable.ic_pip_call_end),
                endLabel,
                endLabel,
                pictureInPictureBroadcastPendingIntent(ACTION_PIP_END_CALL, 703),
            ),
        )
    }

    private fun pictureInPictureBroadcastPendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(action).setPackage(packageName)
        return PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun groupsWidgetNavigation(sourceIntent: Intent?): GroupsWidgetNavigation? {
        val openGroups = sourceIntent?.getBooleanExtra(EXTRA_GROUPS_OPEN_HOME, false) == true
        val participantGroupId = sourceIntent?.getStringExtra(EXTRA_GROUPS_PARTICIPANT_GROUP_ID)
        val participantId = sourceIntent?.getStringExtra(EXTRA_GROUPS_PARTICIPANT_ID)
        val taskGroupId = sourceIntent?.getStringExtra(EXTRA_GROUPS_TASK_GROUP_ID)
        val taskId = sourceIntent?.getStringExtra(EXTRA_GROUPS_TASK_ID)
        if (!openGroups && participantGroupId == null && taskGroupId == null) return null
        return GroupsWidgetNavigation(
            openGroups = openGroups,
            participantGroupId = participantGroupId,
            participantId = participantId,
            taskGroupId = taskGroupId,
            taskId = taskId,
        )
    }

    private fun groupsWidgetNavigationStore() = GroupsWidgetNavigationStore(applicationContext)

    private fun clearGroupsWidgetNavigation(sourceIntent: Intent?) {
        sourceIntent?.removeExtra(EXTRA_GROUPS_OPEN_HOME)
        sourceIntent?.removeExtra(EXTRA_GROUPS_PARTICIPANT_GROUP_ID)
        sourceIntent?.removeExtra(EXTRA_GROUPS_PARTICIPANT_ID)
        sourceIntent?.removeExtra(EXTRA_GROUPS_TASK_GROUP_ID)
        sourceIntent?.removeExtra(EXTRA_GROUPS_TASK_ID)
    }

    companion object {
        private const val TAG_CALL_PIP = "CallPiP"
        private const val CALL_PICTURE_IN_PICTURE_CHANNEL = "com.collab_tasks/call_picture_in_picture"
        private const val CALL_PICTURE_IN_PICTURE_EVENTS_CHANNEL =
            "com.collab_tasks/call_picture_in_picture/events"
        private const val ACTION_PIP_TOGGLE_MICROPHONE = "com.collab_tasks.action.PIP_TOGGLE_MICROPHONE"
        private const val ACTION_PIP_END_CALL = "com.collab_tasks.action.PIP_END_CALL"

        private val SUPPORTED_WIDGET_LANGUAGES = setOf("en", "ru", "uk")

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

internal object WidgetLocalization {
    private const val PREFERENCES = "widget_localization"
    private const val LANGUAGE_CODE_KEY = "language_code"
    private val supportedLanguages = setOf("en", "ru", "uk")

    fun languageCode(context: Context): String {
        val savedCode = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString(LANGUAGE_CODE_KEY, null)
        return savedCode?.takeIf { it in supportedLanguages }
            ?: Locale.getDefault().language.takeIf { it in supportedLanguages }
            ?: "en"
    }

    fun localizedContext(context: Context, localeCode: String? = null): Context {
        val configuration = Configuration(context.resources.configuration)
        val selectedLanguage = localeCode?.takeIf { it in supportedLanguages } ?: languageCode(context)
        configuration.setLocale(Locale.forLanguageTag(selectedLanguage))
        return context.createConfigurationContext(configuration)
    }

    fun saveLanguage(context: Context, languageCode: String) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit {
            putString(LANGUAGE_CODE_KEY, languageCode)
        }
    }
}
