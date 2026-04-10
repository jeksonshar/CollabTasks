// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addTaskTitle => 'Add Task';

  @override
  String get editTaskTitle => 'Edit Task';

  @override
  String get formattingTitle => 'Formatting options: ';

  @override
  String get attachFileTitle => 'Attach file: ';

  @override
  String get attachmentsTitle => 'Attachments: ';

  @override
  String get priorityTitle => 'Priority: ';

  @override
  String get taskPriorityNone => 'No priority';

  @override
  String get taskPriorityLow => 'Low priority';

  @override
  String get taskPriorityMedium => 'Medium priority';

  @override
  String get taskPriorityHigh => 'High priority';

  @override
  String get viewFileTitle => 'View';

  @override
  String get openFileTitle => 'Open';

  @override
  String get downloadFileTitle => 'Download';

  @override
  String get deleteFileTitle => 'Delete';

  @override
  String get fileDeleted => 'File deleted';

  @override
  String get fileDownloaded => 'File downloaded';

  @override
  String get deleteFileFailed => 'Failed to delete file';

  @override
  String get loadTasksError => 'Failed to load tasks';

  @override
  String get addTaskError => 'Failed to add task';

  @override
  String get updateTaskError => 'Failed to update task';

  @override
  String get deleteTaskError => 'Failed to delete task';

  @override
  String get cancel => 'Cancel';

  @override
  String get home => 'Home';

  @override
  String get enter => 'Enter';

  @override
  String get update => 'Update';

  @override
  String get delete => 'Delete';

  @override
  String get emptyTaskTitle => 'No tasks yet';

  @override
  String get emptyTaskDescription => 'Tap \"Add Task\" to create one';

  @override
  String taskAdded(Object task) {
    return 'Task added: \"$task\"';
  }

  @override
  String taskUpdated(Object task) {
    return 'Task added: \"$task\"';
  }

  @override
  String taskDeleted(Object task) {
    return 'Task deleted: \"$task\"';
  }

  @override
  String taskAddedError(Object task) {
    return 'Failed to add file: \"$task\"';
  }

  @override
  String fileDownloadError(Object file) {
    return 'Failed to save file: \"$file\"';
  }

  @override
  String fileOpenError(Object file) {
    return 'Failed to open file: \"$file\"';
  }

  @override
  String get editorPlaceholder => 'Enter task text...';

  @override
  String get deleteTaskTitle => 'Delete task?';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get tapAddTaskHint => 'Tap \"Add Task\" to create one';

  @override
  String tasksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }
}
