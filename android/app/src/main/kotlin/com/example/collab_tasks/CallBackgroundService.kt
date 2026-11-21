package com.example.collab_tasks

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class CallBackgroundService : Service() {
    private var callWakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        callWakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$packageName:CallBackgroundService",
        )?.apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        val displayName = intent?.getStringExtra(EXTRA_DISPLAY_NAME)
            ?.takeIf(String::isNotBlank)
            ?: applicationInfo.loadLabel(packageManager).toString()
        val notification = buildNotification(displayName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            ongoingCallText(),
            NotificationManager.IMPORTANCE_LOW,
        )
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    private fun buildNotification(displayName: String): Notification {
        val restoreIntent = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val icon = applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.sym_call_incoming
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(icon)
            .setContentTitle(displayName)
            .setContentText(ongoingCallText())
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setContentIntent(restoreIntent)
            .build()
    }

    private fun ongoingCallText(): String = when (WidgetLocalization.languageCode(applicationContext)) {
        "ru" -> "Звонок продолжается"
        "uk" -> "Дзвінок триває"
        else -> "Call in progress"
    }

    override fun onDestroy() {
        callWakeLock?.let { wakeLock ->
            if (wakeLock.isHeld) wakeLock.release()
        }
        callWakeLock = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val EXTRA_DISPLAY_NAME = "com.example.collab_tasks.extra.CALL_DISPLAY_NAME"
        private const val CHANNEL_ID = "active_call_service"
        private const val NOTIFICATION_ID = 9417
    }
}
