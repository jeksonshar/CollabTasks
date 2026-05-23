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
  String get completedTaskTitle => 'Completed';

  @override
  String get titleField => 'Title';

  @override
  String get titlePlaceholder => 'Enter task title';

  @override
  String get descriptionField => 'Description';

  @override
  String get formattingTitle => 'Formatting options: ';

  @override
  String get attachFileTitle => 'Attach file: ';

  @override
  String get attachmentsTitle => 'Attachments: ';

  @override
  String get priorityTitle => 'Priority: ';

  @override
  String get addSubtaskTitle => 'Add';

  @override
  String get subtasksTitle => 'Subtasks';

  @override
  String get subtaskTitle => 'Subtask title';

  @override
  String get noSubtasks => 'No subtasks';

  @override
  String get removeSubtaskTitle => 'Remove';

  @override
  String get taskPriorityNone => 'No priority';

  @override
  String get taskPriorityLow => 'Low priority';

  @override
  String get taskPriorityMedium => 'Medium priority';

  @override
  String get taskPriorityHigh => 'High priority';

  @override
  String get sortByDate => 'By date';

  @override
  String get sortByPriority => 'By priority';

  @override
  String get sortByTitle => 'By title';

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
  String get nameTitle => 'Name';

  @override
  String get emailTitle => 'Email';

  @override
  String get statusTitle => 'Status';

  @override
  String get groups => 'Groups';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get userProfile => 'User Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get my_tasks => 'My tasks';

  @override
  String get enter => 'Enter';

  @override
  String get update => 'Update';

  @override
  String get delete => 'Delete';

  @override
  String get emptyTaskTitle => 'No tasks yet';

  @override
  String get emptyGroupsTitle => 'No groups yet';

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

  @override
  String get deadlineTitle => 'Deadline';

  @override
  String get setDeadline => 'Set Deadline';

  @override
  String get clearDeadline => 'Clear Deadline';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get edit => 'Edit';

  @override
  String get filterAll => 'All tasks';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get filterIncomplete => 'Incomplete';

  @override
  String get filterWithFiles => 'With files';

  @override
  String get filterWithoutFiles => 'Without files';

  @override
  String get filterWithDeadline => 'With deadlines';

  @override
  String get filterWithoutDeadline => 'Without deadlines';

  @override
  String get deadlineIn30MinutesTitle => 'Deadline in 30 minutes';

  @override
  String get deadlineReachedTitle => 'Deadline reached';

  @override
  String get confirmDeleteSubtask =>
      'Are you sure you want to delete the subtask?';

  @override
  String get confirmDeleteDeadline =>
      'Are you sure you want to delete the deadline?';

  @override
  String confirmDeleteFile(Object file) {
    return 'Are you sure you want to delete the file \"$file\"?';
  }

  @override
  String get attentionTitle => 'Attention!';

  @override
  String get authTitle => 'Authentication';

  @override
  String get authLogin => 'Login';

  @override
  String get authRegister => 'Register';

  @override
  String get authPassword => 'Password';

  @override
  String get authEnterEmail => 'Enter email';

  @override
  String get authInvalidEmail => 'Invalid email';

  @override
  String get authEnterPassword => 'Enter password';

  @override
  String get authPasswordMinLength => 'Minimum 6 characters';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authResetHint =>
      'Password reset works only for accounts with Email/Password sign-in. Google accounts should use Google sign-in.';

  @override
  String get authResetPasswordSent =>
      'If an account exists for this email, a reset link has been sent.';

  @override
  String get authEnterValidEmailToReset =>
      'Enter a valid email to reset password.';

  @override
  String get authLogOut => 'Log out';

  @override
  String get authProviderTitle => 'Auth method';

  @override
  String get authProviderEmail => 'Email/Password';

  @override
  String get authProviderGoogle => 'Google';

  @override
  String get authProviderUnknown => 'Unknown';

  @override
  String get authNameNotProvided => 'Not provided';

  @override
  String get orTitle => 'or';
}
