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
