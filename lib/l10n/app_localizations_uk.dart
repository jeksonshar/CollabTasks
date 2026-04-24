// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get addTaskTitle => 'Додати задачу';

  @override
  String get editTaskTitle => 'Редагувати задачу';

  @override
  String get completedTaskTitle => 'Виконано';

  @override
  String get titleField => 'Назва';

  @override
  String get titlePlaceholder => 'Введіть назву задачі';

  @override
  String get descriptionField => 'Опис';

  @override
  String get formattingTitle => 'Параметри форматування: ';

  @override
  String get attachFileTitle => 'Прикріпити файл: ';

  @override
  String get attachmentsTitle => 'Вкладення: ';

  @override
  String get priorityTitle => 'Пріоритет: ';

  @override
  String get addSubtaskTitle => 'Добавити';

  @override
  String get subtasksTitle => 'Підзадачі';

  @override
  String get noSubtasks => 'Немає підзадач';

  @override
  String get removeSubtaskTitle => 'Видалити';

  @override
  String get taskPriorityNone => 'Без пріоритету';

  @override
  String get taskPriorityLow => 'Низький пріоритет';

  @override
  String get taskPriorityMedium => 'Середній пріоритет';

  @override
  String get taskPriorityHigh => 'Високий пріоритет';

  @override
  String get sortByDate => 'За датою';

  @override
  String get sortByPriority => 'За пріоритетом';

  @override
  String get sortByTitle => 'За назвою';

  @override
  String get viewFileTitle => 'Переглянути';

  @override
  String get openFileTitle => 'Відкрити';

  @override
  String get downloadFileTitle => 'Завантажити';

  @override
  String get deleteFileTitle => 'Видалити';

  @override
  String get fileDeleted => 'Файл видалено';

  @override
  String get fileDownloaded => 'Файл збережено';

  @override
  String get deleteFileFailed => 'Не вдалося видалити файл';

  @override
  String get loadTasksError => 'Не вдалося завантажити задачі';

  @override
  String get addTaskError => 'Не вдалося додати задачу';

  @override
  String get updateTaskError => 'Не вдалося оновити задачу';

  @override
  String get deleteTaskError => 'Не вдалося видалити задачу';

  @override
  String get cancel => 'Скасувати';

  @override
  String get home => 'Головна';

  @override
  String get nameTitle => 'Ім\'я';

  @override
  String get emailTitle => 'Email';

  @override
  String get statusTitle => 'Статус';

  @override
  String get groups => 'Групи';

  @override
  String get profile => 'Профіль';

  @override
  String get settings => 'Налаштування';

  @override
  String get language => 'Мова';

  @override
  String get userProfile => 'Профіль користувача';

  @override
  String get editProfile => 'Редагувати профіль';

  @override
  String get my_tasks => 'Мої задачі';

  @override
  String get enter => 'Додати';

  @override
  String get update => 'Оновити';

  @override
  String get delete => 'Видалити';

  @override
  String get emptyTaskTitle => 'Поки немає задач';

  @override
  String get emptyGroupsTitle => 'Поки немає груп';

  @override
  String get emptyTaskDescription =>
      'Натисніть \"Додати задачу\", щоб створити її';

  @override
  String taskAdded(Object task) {
    return 'Задачу додано: \"$task\"';
  }

  @override
  String taskUpdated(Object task) {
    return 'Задачу оновлено: \"$task\"';
  }

  @override
  String taskDeleted(Object task) {
    return 'Задачу видалено: \"$task\"';
  }

  @override
  String taskAddedError(Object task) {
    return 'Не вдалося додати файл: \"$task\"';
  }

  @override
  String fileDownloadError(Object file) {
    return 'Не вдалося зберегти файл: \"$file\"';
  }

  @override
  String fileOpenError(Object file) {
    return 'Не вдалося відкрити файл: \"$file\"';
  }

  @override
  String get editorPlaceholder => 'Введіть текст задачі...';

  @override
  String get deleteTaskTitle => 'Видалити задачу?';

  @override
  String get noTasksYet => 'Поки немає задач';

  @override
  String get tapAddTaskHint => 'Натисніть \"Додати задачу\", щоб створити її';

  @override
  String tasksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задач',
      one: '1 задача',
      zero: 'Немає задач',
    );
    return '$_temp0';
  }

  @override
  String get deadlineTitle => 'Дедлайн';

  @override
  String get setDeadline => 'Встановити дедлайн';

  @override
  String get clearDeadline => 'Очистити дедлайн';

  @override
  String get pin => 'Закріпити';

  @override
  String get unpin => 'Відкріпити';

  @override
  String get edit => 'Редагувати';

  @override
  String get filterAll => 'Усі задачі';

  @override
  String get filterCompleted => 'Виконані';

  @override
  String get filterIncomplete => 'Невиконані';

  @override
  String get filterWithFiles => 'З файлами';

  @override
  String get filterWithoutFiles => 'Без файлів';

  @override
  String get filterWithDeadline => 'З дедлайном';

  @override
  String get filterWithoutDeadline => 'Без дедлайну';
}
