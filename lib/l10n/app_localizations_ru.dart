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
  String get editTaskTitle => 'Редактировать задачу';

  @override
  String get completedTaskTitle => 'Выполнена';

  @override
  String get titleField => 'Название';

  @override
  String get titlePlaceholder => 'Введите название задачи';

  @override
  String get descriptionField => 'Описание';

  @override
  String get formattingTitle => 'Параметры форматирования: ';

  @override
  String get attachFileTitle => 'Прикрепить файл: ';

  @override
  String get attachmentsTitle => 'Вложения: ';

  @override
  String get priorityTitle => 'Приоритет: ';

  @override
  String get taskPriorityNone => 'Без приоритета';

  @override
  String get taskPriorityLow => 'Низкий приоритет';

  @override
  String get taskPriorityMedium => 'Средний приоритет';

  @override
  String get taskPriorityHigh => 'Высокий приоритет';

  @override
  String get sortByDate => 'По дате';

  @override
  String get sortByPriority => 'По приоритету';

  @override
  String get sortByTitle => 'По имени';

  @override
  String get viewFileTitle => 'Просмотреть';

  @override
  String get openFileTitle => 'Открыть';

  @override
  String get downloadFileTitle => 'Скачать';

  @override
  String get deleteFileTitle => 'Удалить';

  @override
  String get fileDeleted => 'Файл удалён';

  @override
  String get fileDownloaded => 'Файл сохранён';

  @override
  String get deleteFileFailed => 'Не удалось удалить файл';

  @override
  String get loadTasksError => 'Не удалось загрузить задачи';

  @override
  String get addTaskError => 'Не удалось добавить задачу';

  @override
  String get updateTaskError => 'Не удалось обновить задачу';

  @override
  String get deleteTaskError => 'Не удалось удалить задачу';

  @override
  String get cancel => 'Отмена';

  @override
  String get home => 'Главная';

  @override
  String get nameTitle => 'Имя';

  @override
  String get emailTitle => 'Email';

  @override
  String get statusTitle => 'Статус';

  @override
  String get groups => 'Проекты';

  @override
  String get profile => 'Профиль';

  @override
  String get userProfile => 'Профиль пользователя';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get my_tasks => 'Moи задачи';

  @override
  String get enter => 'Добавить';

  @override
  String get update => 'Обновить';

  @override
  String get delete => 'Удалить';

  @override
  String get emptyTaskTitle => 'Еще нет задач';

  @override
  String get emptyGroupsTitle => 'Еще нет проектов';

  @override
  String get emptyTaskDescription => 'Нажми \"Добавить задачу\" для создания';

  @override
  String taskAdded(Object task) {
    return 'Задача добавлена: \"$task\"';
  }

  @override
  String taskUpdated(Object task) {
    return 'Задача обновлена: \"$task\"';
  }

  @override
  String taskDeleted(Object task) {
    return 'Задача удалена: \"$task\"';
  }

  @override
  String taskAddedError(Object task) {
    return 'Не удалось добавить файл: \"$task\"';
  }

  @override
  String fileDownloadError(Object file) {
    return 'Не удалось сохранить файл: \"$file\"';
  }

  @override
  String fileOpenError(Object file) {
    return 'Не удалось открыть файл: \"$file\"';
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

  @override
  String get deadlineTitle => 'Дедлайн';

  @override
  String get setDeadline => 'Установить дедлайн';

  @override
  String get clearDeadline => 'Очистить дедлайн';
}
