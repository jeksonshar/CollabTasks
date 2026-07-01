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
  String get subtaskTitle => 'Назва пiдзадачи';

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
  String get emptyTaskDescription => 'Натисніть \"Додати задачу\", щоб створити її';

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

  @override
  String get deadlineIn30MinutesTitle => 'Дедлайн через 30 хвилин';

  @override
  String get deadlineReachedTitle => 'Дедлайн настав';

  @override
  String get confirmDeleteSubtask => 'Ви впевнені, що хочете видалити підзадачу?';

  @override
  String get confirmDeleteDeadline => 'Ви впевнені, що хочете видалити deadline?';

  @override
  String confirmDeleteFile(Object file) {
    return 'Ви впевнені, що хочете видалити файл \"$file\"?';
  }

  @override
  String get attentionTitle => 'Увага!';

  @override
  String get authTitle => 'Авторизація';

  @override
  String get authLogin => 'Вхід';

  @override
  String get authRegister => 'Реєстрація';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authEnterEmail => 'Введіть email';

  @override
  String get authInvalidEmail => 'Некоректний email';

  @override
  String get authEnterPassword => 'Введіть пароль';

  @override
  String get authPasswordMinLength => 'Мінімум 6 символів';

  @override
  String get authSignIn => 'Увійти';

  @override
  String get authCreateAccount => 'Створити акаунт';

  @override
  String get authContinueWithGoogle => 'Продовжити з Google';

  @override
  String get authForgotPassword => 'Забули пароль?';

  @override
  String get authResetHint =>
      'Скидання пароля працює лише для акаунтів із входом Email/Password. Для Google-акаунтів використовуйте вхід через Google.';

  @override
  String get authResetPasswordSent =>
      'Якщо акаунт із таким email існує, посилання для скидання вже надіслано.';

  @override
  String get authEnterValidEmailToReset => 'Введіть коректний email для скидання пароля.';

  @override
  String get authLogOut => 'Вийти';

  @override
  String get authProviderTitle => 'Спосіб авторизації';

  @override
  String get authProviderEmail => 'Email/Пароль';

  @override
  String get authProviderGoogle => 'Google';

  @override
  String get authProviderUnknown => 'Невідомо';

  @override
  String get authNameNotProvided => 'Не вказано';

  @override
  String get orTitle => 'або';

  @override
  String get authPasswordUpdated => 'Пароль оновлено. Увійдіть з новим паролем.';

  @override
  String get authVerificationCodeResent => 'Код підтвердження надіслано знову. Перевірте пошту.';

  @override
  String get authAccountConfirmed => 'Акаунт підтверджено. Тепер ви можете увійти.';

  @override
  String authVerificationCodeLabel(Object email) {
    return 'Код підтвердження для $email';
  }

  @override
  String get authConfirmSignUp => 'Підтвердити реєстрацію';

  @override
  String get authResendCode => 'Надіслати код знову';

  @override
  String authResetCodeLabel(Object email) {
    return 'Код скидання для $email';
  }

  @override
  String get authNewPasswordLabel => 'Новий пароль';

  @override
  String get authConfirmResetPassword => 'Підтвердити скидання пароля';

  @override
  String get authErrorEnterValidEmail => 'Спочатку введіть коректний email.';

  @override
  String get authErrorEnterVerificationCode => 'Введіть код підтвердження.';

  @override
  String get authErrorEnterResetCode => 'Введіть код скидання.';

  @override
  String get authErrorNewPasswordTooShort => 'Новий пароль занадто короткий.';

  @override
  String get groupScreenAddGroupFunctionality => 'Функціонал додавання груп';

  @override
  String get profileScreenEditProfileFunctionality => 'Функціонал редагування профілю';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Російська';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsTheme => 'Тема оформлення';

  @override
  String get settingsThemeLight => 'Світла';

  @override
  String get settingsThemeDark => 'Темна';

  @override
  String get settingsThemeSystem => 'Системна';

  @override
  String get bytesSuffixB => 'Б';

  @override
  String get bytesSuffixKB => 'КБ';

  @override
  String get bytesSuffixMB => 'МБ';

  @override
  String get authErrorWrongPassword => 'Невірний пароль.';

  @override
  String get authErrorUserNotFound => 'Користувача не знайдено.';

  @override
  String get authErrorNetwork => 'Помилка мережі.';

  @override
  String get authErrorActionCodeExpired => 'Код підтвердження закінчився.';

  @override
  String get authErrorEmailAlreadyInUse => 'Цей email вже використовується.';

  @override
  String get authErrorInvalidEmail => 'Некоректна адреса електронної пошти.';

  @override
  String get authErrorWeakPassword => 'Пароль занадто слабкий.';

  @override
  String get authErrorTooManyRequests => 'Занадто багато запитів.';

  @override
  String get authErrorUserDisabled => 'Обліковий запис користувача вимкнено.';

  @override
  String get authErrorEmailNotVerified => 'Email не підтверджено.';

  @override
  String get authErrorEmailNotVerifiedConfirmEmail =>
      'Підтвердьте email за допомогою коду верифікації перед входом.';

  @override
  String get authErrorEmailNotVerifiedSent =>
      'Лист із підтвердженням надіслано. Підтвердьте email, потім увійдіть.';

  @override
  String get authErrorInvalidCredential => 'Невірні облікові дані.';

  @override
  String get authErrorOperationNotAllowed => 'Операція не дозволена.';

  @override
  String get authErrorResetNotAvailable => 'Скидання пароля недоступне для цього акаунту.';

  @override
  String get authErrorGoogleSignInNotSupported =>
      'Вхід через Google не підтримується на цій платформі.';

  @override
  String get authErrorNoPasswordProvider => 'Цей акаунт не підтримує скидання пароля.';

  @override
  String get authErrorPasswordResetRequired => 'Перед входом необхідно скинути пароль.';

  @override
  String get authErrorCanceledByUser => 'Операція скасована користувачем.';

  @override
  String get authErrorConfirmationNotComplete => 'Підтвердження не завершено.';

  @override
  String get authErrorUnknown => 'Невідома помилка авторизації.';
}
