import 'dart:async';

import 'package:collab_tasks/features/tasks/data/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/features/tasks/data/notifications/task_notification_event_type.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_titles_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {}

class TaskNotificationsManager implements TaskNotificationService {
  static const _androidChannelId = 'task_deadline_reminders';
  static const _androidChannelName = 'Task deadline reminders';
  static const _androidChannelDescription = 'Deadline reminders for tasks';
  static const _reminderLeadTime = Duration(minutes: 30);

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final StreamController<NotificationTapPayload> _notificationTapController;
  final TaskNotificationTitlesProvider _titleProvider;

  bool _isInitialized = false;
  bool _isNotificationsSupported = false;
  bool _canScheduleExactAlarms = false;
  NotificationTapPayload? _initialTapPayload;

  TaskNotificationsManager({
    required TaskNotificationTitlesProvider titleProvider,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    StreamController<NotificationTapPayload>? notificationTapController,
  }) : _notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
       _notificationTapController =
           notificationTapController ?? StreamController<NotificationTapPayload>.broadcast(),
       _titleProvider = titleProvider;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _isNotificationsSupported = false;
      _isInitialized = true;
      debugPrint('NotificationsManager: local notifications are not supported on this platform.');
      return;
    }

    _isNotificationsSupported = true;
    await _configureTimeZone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );
    await _createAndroidNotificationChannel();
    await _requestPermissionsIfNeeded();
    await _resolveExactAlarmCapability();

    final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    final parsedPayload = NotificationTapPayload.tryParse(launchPayload);
    if (parsedPayload != null) {
      _initialTapPayload = parsedPayload;
    }

    // _isInitialized = true; // when app is open notifications doesn't arrive
  }

  @override
  Stream<NotificationTapPayload> get notificationTapStream => _notificationTapController.stream;

  @override
  NotificationTapPayload? consumeInitialTapPayload() {
    final payload = _initialTapPayload;
    _initialTapPayload = null;
    return payload;
  }

  @override
  Future<void> syncTaskNotifications(List<Task> tasks) async {
    if (!_isNotificationsSupported) {
      return;
    }

    for (final task in tasks) {
      await cancelTaskNotifications(task.id);
    }
    for (final task in tasks) {
      await scheduleTaskNotifications(task);
    }
  }

  @override
  Future<void> scheduleTaskNotifications(Task task) async {
    if (!_isNotificationsSupported) {
      return;
    }

    await _resolveExactAlarmCapability();
    await cancelTaskNotifications(task.id);

    final deadline = task.deadline;
    if (deadline == null || task.isCompleted) {
      return;
    }

    final now = DateTime.now();
    final titles = await _titleProvider.getTitles();

    final reminderAt = deadline.subtract(_reminderLeadTime);
    if (reminderAt.isAfter(now)) {
      await _schedule(
        id: _buildNotificationId(task.id, TaskNotificationEventType.beforeDeadline),
        title: titles.reminderTitle,
        body: task.title,
        at: reminderAt,
        payload: NotificationTapPayload(
          taskId: task.id,
          eventType: TaskNotificationEventType.beforeDeadline,
        ),
      );
    }

    if (deadline.isAfter(now)) {
      await _schedule(
        id: _buildNotificationId(task.id, TaskNotificationEventType.deadlineReached),
        title: titles.deadlineTitle,
        body: task.title,
        at: deadline,
        payload: NotificationTapPayload(
          taskId: task.id,
          eventType: TaskNotificationEventType.deadlineReached,
        ),
      );
    }

    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint(
      'NotificationsManager: scheduled for task=${task.id}, pending=${pending.length}, deadline=$deadline',
    );
  }

  @override
  Future<void> cancelTaskNotifications(String taskId) async {
    if (!_isNotificationsSupported) {
      return;
    }

    await _notificationsPlugin.cancel(
      _buildNotificationId(taskId, TaskNotificationEventType.beforeDeadline),
    );
    await _notificationsPlugin.cancel(
      _buildNotificationId(taskId, TaskNotificationEventType.deadlineReached),
    );
  }

  void dispose() {
    _notificationTapController.close();
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required NotificationTapPayload payload,
  }) async {
    final tzDate = tz.TZDateTime.from(at, tz.local);
    debugPrint(
      'NotificationsManager: schedule id=$id local=$at tz=${tz.local.name} mode=${_resolveScheduleMode().name}',
    );
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: _resolveScheduleMode(),
        payload: payload.toJson(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationsManager: schedule failed in preferred mode, fallback to inexact. error=$error\n$stackTrace',
      );
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        payload: payload.toJson(),
      );
    }
  }

  Future<void> _configureTimeZone() async {
    tz_data.initializeTimeZones();

    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      debugPrint('NotificationsManager: timezone configured name=$timezoneName');
    } catch (error, stackTrace) {
      debugPrint('NotificationsManager timezone fallback to UTC: $error\n$stackTrace');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _requestPermissionsIfNeeded() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final notificationsEnabled = await androidPlugin?.areNotificationsEnabled();
    debugPrint('NotificationsManager: notifications enabled before request=$notificationsEnabled');
    final granted = await androidPlugin?.requestNotificationsPermission();
    debugPrint('NotificationsManager: notifications permission granted=$granted');
    final exactGranted = await androidPlugin?.requestExactAlarmsPermission();
    debugPrint('NotificationsManager: exact alarms permission request result=$exactGranted');
  }

  Future<void> _createAndroidNotificationChannel() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.max,
      ),
    );
    debugPrint('NotificationsManager: notification channel created id=$_androidChannelId');
  }

  Future<void> _resolveExactAlarmCapability() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      _canScheduleExactAlarms = false;
      return;
    }

    final canSchedule = await androidPlugin.canScheduleExactNotifications();
    _canScheduleExactAlarms = canSchedule ?? false;
    debugPrint('NotificationsManager: exact alarms available=$_canScheduleExactAlarms');
  }

  AndroidScheduleMode _resolveScheduleMode() {
    return _canScheduleExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final parsedPayload = NotificationTapPayload.tryParse(response.payload);
    if (parsedPayload != null) {
      _notificationTapController.add(parsedPayload);
    }
  }

  int _buildNotificationId(String taskId, TaskNotificationEventType eventType) {
    final key = 'task:$taskId:${eventType.name}';

    var hash = 0x811C9DC5;
    for (final code in key.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }

    return hash;
  }
}
