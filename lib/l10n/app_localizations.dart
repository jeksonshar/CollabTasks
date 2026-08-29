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
  /// **'Tasks'**
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

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authTitle;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get authEnterEmail;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authInvalidEmail;

  /// No description provided for @authEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get authEnterPassword;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authResetHint.
  ///
  /// In en, this message translates to:
  /// **'Password reset works only for accounts with Email/Password sign-in. Google accounts should use Google sign-in.'**
  String get authResetHint;

  /// No description provided for @authResetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link has been sent.'**
  String get authResetPasswordSent;

  /// No description provided for @authEnterValidEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email to reset password.'**
  String get authEnterValidEmailToReset;

  /// No description provided for @authLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get authLogOut;

  /// No description provided for @authProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Auth method'**
  String get authProviderTitle;

  /// No description provided for @authProviderEmail.
  ///
  /// In en, this message translates to:
  /// **'Email/Password'**
  String get authProviderEmail;

  /// No description provided for @authProviderGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get authProviderGoogle;

  /// No description provided for @authProviderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get authProviderUnknown;

  /// No description provided for @authNameNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get authNameNotProvided;

  /// No description provided for @orTitle.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orTitle;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in with new password.'**
  String get authPasswordUpdated;

  /// No description provided for @authVerificationCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent again. Check your email.'**
  String get authVerificationCodeResent;

  /// No description provided for @authAccountConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Account confirmed. You can sign in now.'**
  String get authAccountConfirmed;

  /// No description provided for @authVerificationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code for {email}'**
  String authVerificationCodeLabel(Object email);

  /// No description provided for @authConfirmSignUp.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sign Up'**
  String get authConfirmSignUp;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get authResendCode;

  /// No description provided for @authResetCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset code for {email}'**
  String authResetCodeLabel(Object email);

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// No description provided for @authConfirmResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset Password'**
  String get authConfirmResetPassword;

  /// No description provided for @authErrorEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email first.'**
  String get authErrorEnterValidEmail;

  /// No description provided for @authErrorEnterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code.'**
  String get authErrorEnterVerificationCode;

  /// No description provided for @authErrorEnterResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter reset code.'**
  String get authErrorEnterResetCode;

  /// No description provided for @authErrorNewPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password is too short.'**
  String get authErrorNewPasswordTooShort;

  /// No description provided for @groupScreenAddGroupFunctionality.
  ///
  /// In en, this message translates to:
  /// **'Add group functionality'**
  String get groupScreenAddGroupFunctionality;

  /// No description provided for @profileScreenEditProfileFunctionality.
  ///
  /// In en, this message translates to:
  /// **'Edit profile functionality'**
  String get profileScreenEditProfileFunctionality;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get settingsLanguageRussian;

  /// No description provided for @settingsLanguageUkrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get settingsLanguageUkrainian;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @bytesSuffixB.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get bytesSuffixB;

  /// No description provided for @bytesSuffixKB.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get bytesSuffixKB;

  /// No description provided for @bytesSuffixMB.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get bytesSuffixMB;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorActionCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Action code expired.'**
  String get authErrorActionCodeExpired;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email is already in use.'**
  String get authErrorEmailAlreadyInUse;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'User account is disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email is not verified.'**
  String get authErrorEmailNotVerified;

  /// No description provided for @authErrorEmailNotVerifiedConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm email with verification code before sign-in.'**
  String get authErrorEmailNotVerifiedConfirmEmail;

  /// No description provided for @authErrorEmailNotVerifiedSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Confirm your email, then sign in.'**
  String get authErrorEmailNotVerifiedSent;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid credential.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Operation is not allowed.'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorResetNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Reset password flow is not available for this account.'**
  String get authErrorResetNotAvailable;

  /// No description provided for @authErrorGoogleSignInNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-in is not supported on this platform.'**
  String get authErrorGoogleSignInNotSupported;

  /// No description provided for @authErrorNoPasswordProvider.
  ///
  /// In en, this message translates to:
  /// **'This account does not support password reset.'**
  String get authErrorNoPasswordProvider;

  /// No description provided for @authErrorPasswordResetRequired.
  ///
  /// In en, this message translates to:
  /// **'Password reset is required before sign-in.'**
  String get authErrorPasswordResetRequired;

  /// No description provided for @authErrorCanceledByUser.
  ///
  /// In en, this message translates to:
  /// **'Operation was canceled by user.'**
  String get authErrorCanceledByUser;

  /// No description provided for @authErrorConfirmationNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Confirmation is not complete.'**
  String get authErrorConfirmationNotComplete;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown authentication error.'**
  String get authErrorUnknown;

  /// No description provided for @create_group_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'New Working Group'**
  String get create_group_dialog_title;

  /// No description provided for @create_group_dialog_textFieldDecorationName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get create_group_dialog_textFieldDecorationName;

  /// No description provided for @create_group_dialog_textFieldValidatorName.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get create_group_dialog_textFieldValidatorName;

  /// No description provided for @create_group_dialog_textFieldDecorationDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get create_group_dialog_textFieldDecorationDescription;

  /// No description provided for @create_group_dialog_cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get create_group_dialog_cancelBtn;

  /// No description provided for @create_group_dialog_createBtn.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create_group_dialog_createBtn;

  /// No description provided for @edit_group_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get edit_group_dialog_title;

  /// No description provided for @edit_group_dialog_changeAvatarBtn.
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get edit_group_dialog_changeAvatarBtn;

  /// No description provided for @edit_group_dialog_textFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get edit_group_dialog_textFieldName;

  /// No description provided for @edit_group_dialog_textFieldDesctiption.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get edit_group_dialog_textFieldDesctiption;

  /// No description provided for @edit_group_dialog_cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get edit_group_dialog_cancelBtn;

  /// No description provided for @edit_group_dialog_saveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get edit_group_dialog_saveBtn;

  /// No description provided for @invite_participant_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Invite Participant'**
  String get invite_participant_dialog_title;

  /// No description provided for @invite_participant_dialog_textFieldDecorationEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get invite_participant_dialog_textFieldDecorationEmail;

  /// No description provided for @invite_participant_dialog_textFieldValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email'**
  String get invite_participant_dialog_textFieldValidator;

  /// No description provided for @invite_participant_dialog_cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get invite_participant_dialog_cancelBtn;

  /// No description provided for @invite_participant_dialog_inviteBtn.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite_participant_dialog_inviteBtn;

  /// No description provided for @group_details_defaultErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading group'**
  String get group_details_defaultErrorMessage;

  /// No description provided for @group_details_popupItemEditGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get group_details_popupItemEditGroup;

  /// No description provided for @group_details_popupItemInviteParticipant.
  ///
  /// In en, this message translates to:
  /// **'Invite participant'**
  String get group_details_popupItemInviteParticipant;

  /// No description provided for @group_details_popupItemLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get group_details_popupItemLeaveGroup;

  /// No description provided for @group_details_popupItemDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get group_details_popupItemDeleteGroup;

  /// No description provided for @group_details_bottomNavItemParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get group_details_bottomNavItemParticipants;

  /// No description provided for @group_details_bottomNavItemTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get group_details_bottomNavItemTasks;

  /// No description provided for @group_details_bottomNavItemChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get group_details_bottomNavItemChat;

  /// No description provided for @group_details_leaveGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave group?'**
  String get group_details_leaveGroupTitle;

  /// No description provided for @group_details_leaveGroupBtn.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get group_details_leaveGroupBtn;

  /// No description provided for @group_details_cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get group_details_cancelBtn;

  /// No description provided for @group_details_deleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get group_details_deleteGroupTitle;

  /// No description provided for @group_details_deleteGroupContent.
  ///
  /// In en, this message translates to:
  /// **'Group, participants and tasks will be deleted.'**
  String get group_details_deleteGroupContent;

  /// No description provided for @group_details_deleteGroupBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get group_details_deleteGroupBtn;

  /// No description provided for @group_details_emptyParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants not yet synchronized'**
  String get group_details_emptyParticipantsTitle;

  /// No description provided for @group_details_titleWhenNoPartisipant.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get group_details_titleWhenNoPartisipant;

  /// No description provided for @group_details_ifParticipantYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get group_details_ifParticipantYou;

  /// No description provided for @group_details_taskBtnSegmentAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get group_details_taskBtnSegmentAll;

  /// No description provided for @group_details_taskBtnSegmentAccessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get group_details_taskBtnSegmentAccessible;

  /// No description provided for @group_details_taskBtnSegmentMy.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get group_details_taskBtnSegmentMy;

  /// No description provided for @group_details_taskListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get group_details_taskListEmptyTitle;

  /// No description provided for @group_details_taskFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get group_details_taskFree;

  /// No description provided for @group_details_taskInWork.
  ///
  /// In en, this message translates to:
  /// **'In work by \"{participant}\"'**
  String group_details_taskInWork(Object participant);

  /// No description provided for @group_task_details_defaultErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error updating task'**
  String get group_task_details_defaultErrorMessage;

  /// No description provided for @group_task_details_descriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get group_task_details_descriptionTitle;

  /// No description provided for @group_task_details_deadlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Deadline:'**
  String get group_task_details_deadlineTitle;

  /// No description provided for @group_task_details_subtasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get group_task_details_subtasksTitle;

  /// No description provided for @group_task_details_takeTaskBtn.
  ///
  /// In en, this message translates to:
  /// **'Take the task'**
  String get group_task_details_takeTaskBtn;

  /// No description provided for @group_task_details_releaseTask.
  ///
  /// In en, this message translates to:
  /// **'Release the task'**
  String get group_task_details_releaseTask;

  /// No description provided for @group_task_details_taskInWork.
  ///
  /// In en, this message translates to:
  /// **'In work by \"{participant}\"'**
  String group_task_details_taskInWork(Object participant);

  /// No description provided for @group_task_details_taskFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get group_task_details_taskFree;

  /// No description provided for @groups_toolbarTitle.
  ///
  /// In en, this message translates to:
  /// **'Working Groups'**
  String get groups_toolbarTitle;

  /// No description provided for @groups_defaultErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading groups'**
  String get groups_defaultErrorMessage;

  /// No description provided for @groups_emptyGroupListTitle.
  ///
  /// In en, this message translates to:
  /// **'No working groups yet'**
  String get groups_emptyGroupListTitle;

  /// No description provided for @groups_emptyGroupListDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a group to start collaborating on tasks.'**
  String get groups_emptyGroupListDescription;

  /// No description provided for @group_details_leaveRejectedWithActiveTasks.
  ///
  /// In en, this message translates to:
  /// **'You cannot leave the group while you have active assigned tasks.'**
  String get group_details_leaveRejectedWithActiveTasks;

  /// No description provided for @direct_chat_toolbarTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get direct_chat_toolbarTitle;

  /// No description provided for @direct_chat_senderNameDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get direct_chat_senderNameDefaultTitle;

  /// No description provided for @direct_chat_hintTextInputMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get direct_chat_hintTextInputMessage;

  /// No description provided for @direct_chat_emptyMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get direct_chat_emptyMessagesTitle;

  /// No description provided for @direct_chat_deleteMessageConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get direct_chat_deleteMessageConfirmationTitle;

  /// No description provided for @direct_chat_deleteMessageConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get direct_chat_deleteMessageConfirmBtn;

  /// No description provided for @direct_chat_deleteMessageCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get direct_chat_deleteMessageCancelBtn;

  /// No description provided for @direct_chat_typingStatus.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get direct_chat_typingStatus;

  /// No description provided for @direct_chat_opponentStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get direct_chat_opponentStatusOnline;

  /// No description provided for @direct_chat_opponentStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get direct_chat_opponentStatusOffline;

  /// No description provided for @direct_chat_wasOnline.
  ///
  /// In en, this message translates to:
  /// **'was online \"{time}\"'**
  String direct_chat_wasOnline(Object time);

  /// No description provided for @group_chat_toolbarSabTitle.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get group_chat_toolbarSabTitle;

  /// No description provided for @chat_connectingToServer.
  ///
  /// In en, this message translates to:
  /// **'Server is starting up…'**
  String get chat_connectingToServer;
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
