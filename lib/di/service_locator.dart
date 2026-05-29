import 'package:collab_tasks/core/notifications/notifications_manager.dart';
import 'package:collab_tasks/core/utils/auth_utils.dart';
// will use aws_auth_repository_impl or firebase_auth_repository_impl + firebase_auth + google_sign_in depending authBackend chose
import 'package:collab_tasks/features/auth/data/repositories/aws_auth_repository_impl.dart';
import 'package:collab_tasks/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/usecases/confirm_reset_password_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/confirm_sign_up_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/log_out_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/login_with_email_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/register_with_email_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/resend_sign_up_code_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/features/settings/data/datastore/app_settings_datastore.dart';
import 'package:collab_tasks/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_saved_language_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_task_view_preferences_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_saved_language_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_task_view_preferences_use_case.dart';
import 'package:collab_tasks/features/settings/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/features/tasks/data/local/db/app_database.dart';
import 'package:collab_tasks/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/add_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/cancel_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/consume_initial_notification_payload_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/get_notification_tap_stream_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/schedule_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/sync_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/update_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/watch_tasks_use_case.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Import for @visibleForTesting
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

void setupLocator(SharedPreferences sharedPreferences) {
  // Hot restart can re-run setup with a stale container.
  if (getIt.isRegistered<SharedPreferences>()) {
    getIt.reset();
  }

  getIt
    ..registerLazySingleton<SharedPreferences>(() => sharedPreferences)
    ..registerLazySingleton<NotificationsManager>(() => NotificationsManager())
    ..registerLazySingleton<TaskNotificationService>(() => getIt<NotificationsManager>())
    ..registerLazySingleton<AppSettingsDatastore>(() => AppSettingsDatastore(getIt()))
    ..registerLazySingleton<AppSettingsRepository>(() => AppSettingsRepositoryImpl(getIt()))
    ..registerLazySingleton<AppDatabase>(() => AppDatabase())
    ..registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(getIt<AppDatabase>()))
    ..registerLazySingleton(() => WatchTasksUseCase(getIt()))
    ..registerLazySingleton(() => AddTaskUseCase(getIt()))
    ..registerLazySingleton(() => UpdateTaskUseCase(getIt()))
    ..registerLazySingleton(() => DeleteTaskUseCase(getIt()))
    ..registerLazySingleton(() => GetSavedLanguageUseCase(getIt()))
    ..registerLazySingleton(() => SetSavedLanguageUseCase(getIt()))
    ..registerLazySingleton(() => GetTaskViewPreferencesUseCase(getIt()))
    ..registerLazySingleton(() => SetTaskViewPreferencesUseCase(getIt()))
    ..registerLazySingleton(() => ScheduleTaskNotificationsUseCase(getIt()))
    ..registerLazySingleton(() => CancelTaskNotificationsUseCase(getIt()))
    ..registerLazySingleton(() => SyncTaskNotificationsUseCase(getIt()))
    ..registerLazySingleton(() => GetNotificationTapStreamUseCase(getIt()))
    ..registerLazySingleton(() => ConsumeInitialNotificationPayloadUseCase(getIt()))
    ..registerLazySingleton<AuthRepository>(() {
      switch (authBackend) {
        case AuthBackend.firebase:
          return FirebaseAuthRepositoryImpl(
            firebaseAuth: getIt<FirebaseAuth>(),
            googleSignIn: getIt<GoogleSignIn>(),
            requireEmailVerifiedForEmailLogin: true,
          );
        case AuthBackend.aws:
          return AwsAuthRepositoryImpl();
      }
    })
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance)
    ..registerLazySingleton(() => RegisterWithEmailUseCase(getIt()))
    ..registerLazySingleton(() => LoginWithEmailUseCase(getIt()))
    ..registerLazySingleton(() => SignInWithGoogleUseCase(getIt()))
    ..registerLazySingleton(() => ResetPasswordUseCase(getIt()))
    ..registerLazySingleton(() => ConfirmSignUpUseCase(getIt()))
    ..registerLazySingleton(() => ConfirmResetPasswordUseCase(getIt()))
    ..registerLazySingleton(() => ResendSignUpCodeUseCase(getIt()))
    ..registerLazySingleton(() => LogOutUseCase(getIt()))
    ..registerLazySingleton(() => WatchAuthStateUseCase(getIt()))
    ..registerFactory(
      () => LocaleCubit(getSavedLanguageUseCase: getIt(), setSavedLanguageUseCase: getIt()),
    )
    ..registerFactory(
      () => AuthBloc(
        registerWithEmailUseCase: getIt(),
        loginWithEmailUseCase: getIt(),
        signInWithGoogleUseCase: getIt(),
        resetPasswordUseCase: getIt(),
        confirmSignUpUseCase: getIt(),
        confirmResetPasswordUseCase: getIt(),
        resendSignUpCodeUseCase: getIt(),
        logOutUseCase: getIt(),
        watchAuthStateUseCase: getIt(),
      ),
    )
    ..registerFactory(() => ConfirmationDialogBloc())
    ..registerFactoryParam<TaskBloc, String, String>(
      (notificationReminderTitle, notificationDeadlineTitle) => TaskBloc(
        watchTasksUseCase: getIt(),
        addTaskUseCase: getIt(),
        updateTaskUseCase: getIt(),
        deleteTaskUseCase: getIt(),
        getTaskViewPreferencesUseCase: getIt(),
        setTaskViewPreferencesUseCase: getIt(),
        scheduleTaskNotificationsUseCase: getIt(),
        cancelTaskNotificationsUseCase: getIt(),
        syncTaskNotificationsUseCase: getIt(),
        getNotificationTapStreamUseCase: getIt(),
        consumeInitialNotificationPayloadUseCase: getIt(),
        notificationReminderTitle: notificationReminderTitle,
        notificationDeadlineTitle: notificationDeadlineTitle,
      ),
    );
}

// Helper to reset GetIt for testing purposes
@visibleForTesting
void resetLocator() {
  getIt.reset();
}
