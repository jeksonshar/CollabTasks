// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get addTaskTitle => 'Добавить задачу';

  @override
  String get cancel => 'Отмена';

  @override
  String get home => 'Главная';

  @override
  String get enter => 'Добавить';

  @override
  String get delete => 'Удалить';

  @override
  String get emptyTaskTitle => 'Еще нет задач';

  @override
  String get emptyTaskDescription => 'Нажми \"Добавить задачу\" для создания';

  @override
  String taskAdded(Object task) {
    return 'Задача добавлена: \"$task\"';
  }

  @override
  String taskDeleted(Object task) {
    return 'Задача удалена: \"$task\"';
  }

  @override
  String get editorPlaceholder => 'Введите текст задачи...';

  @override
  String get deleteTaskTitle => 'Удалить задачу?';

  @override
  String get noTasksYet => 'Пока нет задач';

  @override
  String get tapAddTaskHint => 'Нажмите «Добавить задачу», чтобы создать одну';

  @override
  String tasksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задач',
      one: '1 задача',
      zero: 'Нет задач',
    );
    return '$_temp0';
  }
}
