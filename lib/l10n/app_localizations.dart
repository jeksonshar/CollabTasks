import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uk'),
  ];

  /// No description provided for @addTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTaskTitle;

  /// No description provided for @editTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTaskTitle;

  /// No description provided for @completedTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTaskTitle;

  /// No description provided for @titleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleField;

  /// No description provided for @titlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter task title'**
  String get titlePlaceholder;

  /// No description provided for @descriptionField.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionField;

  /// No description provided for @formattingTitle.
  ///
  /// In en, this message translates to:
  /// **'Formatting options: '**
  String get formattingTitle;

  /// No description provided for @attachFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach file: '**
  String get attachFileTitle;

  /// No description provided for @attachmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachments: '**
  String get attachmentsTitle;

  /// No description provided for @priorityTitle.
  ///
  /// In en, this message translates to:
  /// **'Priority: '**
  String get priorityTitle;

  /// No description provided for @addSubtaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addSubtaskTitle;

  /// No description provided for @subtasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasksTitle;

  /// No description provided for @subtaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtask title'**
  String get subtaskTitle;

  /// No description provided for @noSubtasks.
  ///
  /// In en, this message translates to:
  /// **'No subtasks'**
  String get noSubtasks;

  /// No description provided for @removeSubtaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeSubtaskTitle;

  /// No description provided for @taskPriorityNone.
  ///
  /// In en, this message translates to:
  /// **'No priority'**
  String get taskPriorityNone;

  /// No description provided for @taskPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low priority'**
  String get taskPriorityLow;

  /// No description provided for @taskPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium priority'**
  String get taskPriorityMedium;

  /// No description provided for @taskPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get taskPriorityHigh;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get sortByDate;

  /// No description provided for @sortByPriority.
  ///
  /// In en, this message translates to:
  /// **'By priority'**
  String get sortByPriority;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'By title'**
  String get sortByTitle;

  /// No description provided for @viewFileTitle.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewFileTitle;

  /// No description provided for @openFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openFileTitle;

  /// No description provided for @downloadFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadFileTitle;

  /// No description provided for @deleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteFileTitle;

  /// No description provided for @fileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get fileDeleted;

  /// No description provided for @fileDownloaded.
  ///
  /// In en, this message translates to:
  /// **'File downloaded'**
  String get fileDownloaded;

  /// No description provided for @deleteFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file'**
  String get deleteFileFailed;

  /// No description provided for @loadTasksError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tasks'**
  String get loadTasksError;

  /// No description provided for @addTaskError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add task'**
  String get addTaskError;

  /// No description provided for @updateTaskError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update task'**
  String get updateTaskError;

  /// No description provided for @deleteTaskError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete task'**
  String get deleteTaskError;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @nameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameTitle;

  /// No description provided for @emailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailTitle;

  /// No description provided for @statusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusTitle;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @my_tasks.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get my_tasks;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @emptyTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get emptyTaskTitle;

  /// No description provided for @emptyGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get emptyGroupsTitle;

  /// No description provided for @emptyTaskDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Task\" to create one'**
  String get emptyTaskDescription;

  /// Shown when a task is added
  ///
  /// In en, this message translates to:
  /// **'Task added: \"{task}\"'**
  String taskAdded(Object task);

  /// Shown when a task is updated
  ///
  /// In en, this message translates to:
  /// **'Task added: \"{task}\"'**
  String taskUpdated(Object task);

  /// Shown when a task is deleted
  ///
  /// In en, this message translates to:
  /// **'Task deleted: \"{task}\"'**
  String taskDeleted(Object task);

  /// Shown after receiving an error when adding a task
  ///
  /// In en, this message translates to:
  /// **'Failed to add file: \"{task}\"'**
  String taskAddedError(Object task);

  /// Shown after receiving an error while saving a file
  ///
  /// In en, this message translates to:
  /// **'Failed to save file: \"{file}\"'**
  String fileDownloadError(Object file);

  /// Shown after receiving an error while opening a file
  ///
  /// In en, this message translates to:
  /// **'Failed to open file: \"{file}\"'**
  String fileOpenError(Object file);

  /// No description provided for @editorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter task text...'**
  String get editorPlaceholder;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTaskTitle;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @tapAddTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Task\" to create one'**
  String get tapAddTaskHint;

  /// Number of tasks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tasks} =1{1 task} other{{count} tasks}}'**
  String tasksCount(num count);

  /// No description provided for @deadlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineTitle;

  /// No description provided for @setDeadline.
  ///
  /// In en, this message translates to:
  /// **'Set Deadline'**
  String get setDeadline;

  /// No description provided for @clearDeadline.
  ///
  /// In en, this message translates to:
  /// **'Clear Deadline'**
  String get clearDeadline;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get filterAll;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @filterIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get filterIncomplete;

  /// No description provided for @filterWithFiles.
  ///
  /// In en, this message translates to:
  /// **'With files'**
  String get filterWithFiles;

  /// No description provided for @filterWithoutFiles.
  ///
  /// In en, this message translates to:
  /// **'Without files'**
  String get filterWithoutFiles;

  /// No description provided for @filterWithDeadline.
  ///
  /// In en, this message translates to:
  /// **'With deadlines'**
  String get filterWithDeadline;

  /// No description provided for @filterWithoutDeadline.
  ///
  /// In en, this message translates to:
  /// **'Without deadlines'**
  String get filterWithoutDeadline;

  /// No description provided for @deadlineIn30MinutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Deadline in 30 minutes'**
  String get deadlineIn30MinutesTitle;

  /// No description provided for @deadlineReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deadline reached'**
  String get deadlineReachedTitle;

  /// No description provided for @confirmDeleteSubtask.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the subtask?'**
  String get confirmDeleteSubtask;

  /// No description provided for @confirmDeleteDeadline.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the deadline?'**
  String get confirmDeleteDeadline;

  /// Shown when a file need to delete
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the file \"{file}\"?'**
  String confirmDeleteFile(Object file);

  /// No description provided for @attentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Attention!'**
  String get attentionTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
