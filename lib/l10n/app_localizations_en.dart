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
  String get home => 'Tasks';

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

  @override
  String get authPasswordUpdated =>
      'Password updated. Sign in with new password.';

  @override
  String get authVerificationCodeResent =>
      'Verification code sent again. Check your email.';

  @override
  String get authAccountConfirmed => 'Account confirmed. You can sign in now.';

  @override
  String authVerificationCodeLabel(Object email) {
    return 'Verification code for $email';
  }

  @override
  String get authConfirmSignUp => 'Confirm Sign Up';

  @override
  String get authResendCode => 'Resend Code';

  @override
  String authResetCodeLabel(Object email) {
    return 'Reset code for $email';
  }

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authConfirmResetPassword => 'Confirm Reset Password';

  @override
  String get authErrorEnterValidEmail => 'Enter a valid email first.';

  @override
  String get authErrorEnterVerificationCode => 'Enter verification code.';

  @override
  String get authErrorEnterResetCode => 'Enter reset code.';

  @override
  String get authErrorNewPasswordTooShort => 'New password is too short.';

  @override
  String get groupScreenAddGroupFunctionality => 'Add group functionality';

  @override
  String get profileScreenEditProfileFunctionality =>
      'Edit profile functionality';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Russian';

  @override
  String get settingsLanguageUkrainian => 'Ukrainian';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get bytesSuffixB => 'B';

  @override
  String get bytesSuffixKB => 'KB';

  @override
  String get bytesSuffixMB => 'MB';

  @override
  String get authErrorWrongPassword => 'Wrong password.';

  @override
  String get authErrorUserNotFound => 'User not found.';

  @override
  String get authErrorNetwork => 'Network error.';

  @override
  String get authErrorActionCodeExpired => 'Action code expired.';

  @override
  String get authErrorEmailAlreadyInUse => 'Email is already in use.';

  @override
  String get authErrorInvalidEmail => 'Invalid email address.';

  @override
  String get authErrorWeakPassword => 'Password is too weak.';

  @override
  String get authErrorTooManyRequests => 'Too many requests.';

  @override
  String get authErrorUserDisabled => 'User account is disabled.';

  @override
  String get authErrorEmailNotVerified => 'Email is not verified.';

  @override
  String get authErrorEmailNotVerifiedConfirmEmail =>
      'Confirm email with verification code before sign-in.';

  @override
  String get authErrorEmailNotVerifiedSent =>
      'Verification email sent. Confirm your email, then sign in.';

  @override
  String get authErrorInvalidCredential => 'Invalid credential.';

  @override
  String get authErrorOperationNotAllowed => 'Operation is not allowed.';

  @override
  String get authErrorResetNotAvailable =>
      'Reset password flow is not available for this account.';

  @override
  String get authErrorGoogleSignInNotSupported =>
      'Google Sign-in is not supported on this platform.';

  @override
  String get authErrorNoPasswordProvider =>
      'This account does not support password reset.';

  @override
  String get authErrorPasswordResetRequired =>
      'Password reset is required before sign-in.';

  @override
  String get authErrorCanceledByUser => 'Operation was canceled by user.';

  @override
  String get authErrorConfirmationNotComplete =>
      'Confirmation is not complete.';

  @override
  String get authErrorUnknown => 'Unknown authentication error.';

  @override
  String get create_group_dialog_title => 'New Working Group';

  @override
  String get create_group_dialog_textFieldDecorationName => 'Name';

  @override
  String get create_group_dialog_textFieldValidatorName =>
      'Name cannot be empty';

  @override
  String get create_group_dialog_textFieldDecorationDescription =>
      'Description';

  @override
  String get create_group_dialog_cancelBtn => 'Cancel';

  @override
  String get create_group_dialog_createBtn => 'Create';

  @override
  String get edit_group_dialog_title => 'Edit Group';

  @override
  String get edit_group_dialog_changeAvatarBtn => 'Change Avatar';

  @override
  String get edit_group_dialog_textFieldName => 'Name';

  @override
  String get edit_group_dialog_textFieldDesctiption => 'Description';

  @override
  String get edit_group_dialog_cancelBtn => 'Cancel';

  @override
  String get edit_group_dialog_saveBtn => 'Save';

  @override
  String get invite_participant_dialog_title => 'Invite Participant';

  @override
  String get invite_participant_dialog_textFieldDecorationEmail => 'Email';

  @override
  String get invite_participant_dialog_textFieldValidator =>
      'Please enter an email';

  @override
  String get invite_participant_dialog_cancelBtn => 'Cancel';

  @override
  String get invite_participant_dialog_inviteBtn => 'Invite';

  @override
  String get group_details_defaultErrorMessage => 'Error loading group';

  @override
  String get group_details_popupItemEditGroup => 'Edit group';

  @override
  String get group_details_popupItemInviteParticipant => 'Invite participant';

  @override
  String get group_details_popupItemLeaveGroup => 'Leave group';

  @override
  String get group_details_popupItemDeleteGroup => 'Delete group';

  @override
  String get group_details_bottomNavItemParticipants => 'Participants';

  @override
  String get group_details_bottomNavItemTasks => 'Tasks';

  @override
  String get group_details_leaveGroupTitle => 'Leave group?';

  @override
  String get group_details_leaveGroupBtn => 'Leave';

  @override
  String get group_details_cancelBtn => 'Cancel';

  @override
  String get group_details_deleteGroupTitle => 'Delete group?';

  @override
  String get group_details_deleteGroupContent =>
      'Group, participants and tasks will be deleted.';

  @override
  String get group_details_deleteGroupBtn => 'Delete';

  @override
  String get group_details_emptyParticipantsTitle =>
      'Participants not yet synchronized';

  @override
  String get group_details_titleWhenNoPartisipant => 'Participants';

  @override
  String get group_details_ifParticipantYou => 'You';

  @override
  String get group_details_taskBtnSegmentAll => 'All';

  @override
  String get group_details_taskBtnSegmentAccessible => 'Accessible';

  @override
  String get group_details_taskBtnSegmentMy => 'My';

  @override
  String get group_details_taskListEmptyTitle => 'No tasks';

  @override
  String get group_details_taskFree => 'Free';

  @override
  String group_details_taskInWork(Object participant) {
    return 'In work by \"$participant\"';
  }

  @override
  String get group_task_details_defaultErrorMessage => 'Error updating task';

  @override
  String get group_task_details_descriptionTitle => 'Description';

  @override
  String get group_task_details_deadlineTitle => 'Deadline:';

  @override
  String get group_task_details_subtasksTitle => 'Subtasks';

  @override
  String get group_task_details_takeTaskBtn => 'Take the task';

  @override
  String get group_task_details_releaseTask => 'Release the task';

  @override
  String group_task_details_taskInWork(Object participant) {
    return 'In work by \"$participant\"';
  }

  @override
  String get group_task_details_taskFree => 'Free';

  @override
  String get groups_toolbarTitle => 'Working Groups';

  @override
  String get groups_defaultErrorMessage => 'Error loading groups';

  @override
  String get groups_emptyGroupListTitle => 'No working groups yet';

  @override
  String get groups_emptyGroupListDescription =>
      'Create a group to start collaborating on tasks.';

  @override
  String get group_details_leaveRejectedWithActiveTasks =>
      'You cannot leave the group while you have active assigned tasks.';

  @override
  String get direct_chat_toolbarTitle => 'Chat';

  @override
  String get direct_chat_senderNameDefaultTitle => 'Unknown User';

  @override
  String get direct_chat_hintTextInputMessage => 'Type a message...';

  @override
  String get direct_chat_emptyMessagesTitle => 'No messages yet';

  @override
  String get direct_chat_deleteMessageConfirmationTitle => 'Delete message?';

  @override
  String get direct_chat_deleteMessageConfirmBtn => 'Delete';

  @override
  String get direct_chat_deleteMessageCancelBtn => 'Cancel';
}
