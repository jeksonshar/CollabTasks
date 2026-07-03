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
  String get addSubtaskTitle => 'Добавить';

  @override
  String get subtasksTitle => 'Подзадачи';

  @override
  String get subtaskTitle => 'Название подзадачи';

  @override
  String get noSubtasks => 'Нет подзадач';

  @override
  String get removeSubtaskTitle => 'Удалить';

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
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

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

  @override
  String get pin => 'Закрепить';

  @override
  String get unpin => 'Открепить';

  @override
  String get edit => 'Редактировать';

  @override
  String get filterAll => 'Все задачи';

  @override
  String get filterCompleted => 'Выполненные';

  @override
  String get filterIncomplete => 'Невыполненные';

  @override
  String get filterWithFiles => 'С файлами';

  @override
  String get filterWithoutFiles => 'Без файлов';

  @override
  String get filterWithDeadline => 'С крайним сроком';

  @override
  String get filterWithoutDeadline => 'Без крайнего срока';

  @override
  String get deadlineIn30MinutesTitle => 'Дедлайн через 30 минут';

  @override
  String get deadlineReachedTitle => 'Дедлайн наступил';

  @override
  String get confirmDeleteSubtask => 'Вы уверены, что хотите удалить подтаск?';

  @override
  String get confirmDeleteDeadline =>
      'Вы уверены, что хотите удалить deadline?';

  @override
  String confirmDeleteFile(Object file) {
    return 'Вы уверены, что хотите удалить файл \"$file\"?';
  }

  @override
  String get attentionTitle => 'Внимание!';

  @override
  String get authTitle => 'Авторизация';

  @override
  String get authLogin => 'Вход';

  @override
  String get authRegister => 'Регистрация';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authEnterEmail => 'Введите email';

  @override
  String get authInvalidEmail => 'Некорректный email';

  @override
  String get authEnterPassword => 'Введите пароль';

  @override
  String get authPasswordMinLength => 'Минимум 6 символов';

  @override
  String get authSignIn => 'Войти';

  @override
  String get authCreateAccount => 'Создать аккаунт';

  @override
  String get authContinueWithGoogle => 'Продолжить с Google';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authResetHint =>
      'Сброс пароля работает только для аккаунтов с входом Email/Password. Для Google-аккаунтов используйте вход через Google.';

  @override
  String get authResetPasswordSent =>
      'Если аккаунт с таким email существует, ссылка для сброса уже отправлена.';

  @override
  String get authEnterValidEmailToReset =>
      'Введите корректный email для сброса пароля.';

  @override
  String get authLogOut => 'Выйти';

  @override
  String get authProviderTitle => 'Способ авторизации';

  @override
  String get authProviderEmail => 'Email/Пароль';

  @override
  String get authProviderGoogle => 'Google';

  @override
  String get authProviderUnknown => 'Неизвестно';

  @override
  String get authNameNotProvided => 'Не указано';

  @override
  String get orTitle => 'или';

  @override
  String get authPasswordUpdated => 'Пароль обновлен. Войдите с новым паролем.';

  @override
  String get authVerificationCodeResent =>
      'Код подтверждения отправлен повторно. Проверьте почту.';

  @override
  String get authAccountConfirmed =>
      'Аккаунт подтвержден. Теперь вы можете войти.';

  @override
  String authVerificationCodeLabel(Object email) {
    return 'Код подтверждения для $email';
  }

  @override
  String get authConfirmSignUp => 'Подтвердить регистрацию';

  @override
  String get authResendCode => 'Отправить код повторно';

  @override
  String authResetCodeLabel(Object email) {
    return 'Код сброса для $email';
  }

  @override
  String get authNewPasswordLabel => 'Новый пароль';

  @override
  String get authConfirmResetPassword => 'Подтвердить сброс пароля';

  @override
  String get authErrorEnterValidEmail => 'Сначала введите корректный email.';

  @override
  String get authErrorEnterVerificationCode => 'Введите код подтверждения.';

  @override
  String get authErrorEnterResetCode => 'Введите код сброса.';

  @override
  String get authErrorNewPasswordTooShort => 'Новый пароль слишком короткий.';

  @override
  String get groupScreenAddGroupFunctionality =>
      'Функционал добавления проектов';

  @override
  String get profileScreenEditProfileFunctionality =>
      'Функционал редактирования профиля';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsTheme => 'Тема оформления';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get bytesSuffixB => 'Б';

  @override
  String get bytesSuffixKB => 'КБ';

  @override
  String get bytesSuffixMB => 'МБ';

  @override
  String get authErrorWrongPassword => 'Неверный пароль.';

  @override
  String get authErrorUserNotFound => 'Пользователь не найден.';

  @override
  String get authErrorNetwork => 'Ошибка сети.';

  @override
  String get authErrorActionCodeExpired => 'Код подтверждения истек.';

  @override
  String get authErrorEmailAlreadyInUse => 'Этот email уже используется.';

  @override
  String get authErrorInvalidEmail => 'Некорректный адрес электронной почты.';

  @override
  String get authErrorWeakPassword => 'Пароль слишком слабый.';

  @override
  String get authErrorTooManyRequests => 'Слишком много запросов.';

  @override
  String get authErrorUserDisabled => 'Учетная запись пользователя отключена.';

  @override
  String get authErrorEmailNotVerified => 'Email не подтвержден.';

  @override
  String get authErrorEmailNotVerifiedConfirmEmail =>
      'Подтвердите email с помощью кода верификации перед входом.';

  @override
  String get authErrorEmailNotVerifiedSent =>
      'Письмо с подтверждением отправлено. Подтвердите email, затем войдите.';

  @override
  String get authErrorInvalidCredential => 'Неверные учетные данные.';

  @override
  String get authErrorOperationNotAllowed => 'Операция не разрешена.';

  @override
  String get authErrorResetNotAvailable =>
      'Сброс пароля недоступен для этого аккаунта.';

  @override
  String get authErrorGoogleSignInNotSupported =>
      'Вход через Google не поддерживается на этой платформе.';

  @override
  String get authErrorNoPasswordProvider =>
      'Этот аккаунт не поддерживает сброс пароля.';

  @override
  String get authErrorPasswordResetRequired =>
      'Перед входом требуется сбросить пароль.';

  @override
  String get authErrorCanceledByUser => 'Операция отменена пользователем.';

  @override
  String get authErrorConfirmationNotComplete => 'Подтверждение не завершено.';

  @override
  String get authErrorUnknown => 'Неизвестная ошибка авторизации.';

  @override
  String get create_group_dialog_title => 'Новая рабочая группа';

  @override
  String get create_group_dialog_textFieldDecorationName => 'Название';

  @override
  String get create_group_dialog_textFieldValidatorName =>
      'Название не может быть пустым';

  @override
  String get create_group_dialog_textFieldDecorationDescription => 'Описание';

  @override
  String get create_group_dialog_cancelBtn => 'Отмена';

  @override
  String get create_group_dialog_createBtn => 'Создать';

  @override
  String get edit_group_dialog_title => 'Редактировать группу';

  @override
  String get edit_group_dialog_changeAvatarBtn => 'Сменить аватарку';

  @override
  String get edit_group_dialog_textFieldName => 'Название';

  @override
  String get edit_group_dialog_textFieldDesctiption => 'Описание';

  @override
  String get edit_group_dialog_cancelBtn => 'Отмена';

  @override
  String get edit_group_dialog_saveBtn => 'Сохранить';

  @override
  String get invite_participant_dialog_title => 'Пригласить участника';

  @override
  String get invite_participant_dialog_textFieldDecorationEmail => 'Email';

  @override
  String get invite_participant_dialog_textFieldValidator => 'Введите email';

  @override
  String get invite_participant_dialog_cancelBtn => 'Отмена';

  @override
  String get invite_participant_dialog_inviteBtn => 'Пригласить';

  @override
  String get group_details_defaultErrorMessage => 'Ошибка загрузки группы';

  @override
  String get group_details_popupItemEditGroup => 'Редактировать группу';

  @override
  String get group_details_popupItemInviteParticipant => 'Пригласить участника';

  @override
  String get group_details_popupItemLeaveGroup => 'Покинуть группу';

  @override
  String get group_details_popupItemDeleteGroup => 'Удалить группу';

  @override
  String get group_details_bottomNavItemParticipants => 'Участники';

  @override
  String get group_details_bottomNavItemTasks => 'Задачи';

  @override
  String get group_details_leaveGroupTitle => 'Покинуть группу?';

  @override
  String get group_details_leaveGroupBtn => 'Покинуть';

  @override
  String get group_details_cancelBtn => 'Отмена';

  @override
  String get group_details_deleteGroupTitle => 'Удалить группу?';

  @override
  String get group_details_deleteGroupContent =>
      'Группа, участники и задачи будут удалены.';

  @override
  String get group_details_deleteGroupBtn => 'Удалить';

  @override
  String get group_details_emptyParticipantsTitle =>
      'Участники еще не синхронизированы';

  @override
  String get group_details_titleWhenNoPartisipant => 'Участники';

  @override
  String get group_details_ifParticipantYou => 'Вы';

  @override
  String get group_details_taskBtnSegmentAll => 'Все';

  @override
  String get group_details_taskBtnSegmentAccessible => 'Доступные';

  @override
  String get group_details_taskBtnSegmentMy => 'Мои';

  @override
  String get group_details_taskListEmptyTitle => 'Задач нет';

  @override
  String get group_details_taskFree => 'Свободно';

  @override
  String group_details_taskInWork(Object participant) {
    return 'В работе у \"$participant\"';
  }

  @override
  String get group_task_details_defaultErrorMessage =>
      'Ошибка обновления задачи';

  @override
  String get group_task_details_descriptionTitle => 'Описание';

  @override
  String get group_task_details_deadlineTitle => 'Срок:';

  @override
  String get group_task_details_subtasksTitle => 'Подзадачи';

  @override
  String get group_task_details_takeTaskBtn => 'Взять задачу';

  @override
  String get group_task_details_releaseTask => 'Освободить задачу';

  @override
  String group_task_details_taskInWork(Object participant) {
    return 'В работе у \"$participant\"';
  }

  @override
  String get group_task_details_taskFree => 'Свободно';

  @override
  String get groups_toolbarTitle => 'Рабочие группы';

  @override
  String get groups_defaultErrorMessage => 'Ошибка загрузки групп';

  @override
  String get groups_emptyGroupListTitle => 'Рабочих групп пока нет';

  @override
  String get groups_emptyGroupListDescription =>
      'Создайте группу, чтобы вести совместные задачи.';
}
