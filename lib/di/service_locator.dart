import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/core/utils/auth_utils.dart';
// will use aws_auth_repository_impl or firebase_auth_repository_impl + firebase_auth + google_sign_in depending authBackend chose
import 'package:collab_tasks/features/auth/data/repositories/aws_auth_repository_impl.dart';
import 'package:collab_tasks/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/repositories/cognito_auth_repository.dart';
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
import 'package:collab_tasks/features/chats/data/remote/chat_remote_data_source.dart';
import 'package:collab_tasks/features/chats/data/remote/firebase_chat_remote_data_source.dart';
import 'package:collab_tasks/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/get_chat_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/send_message_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/watch_messages_use_case.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_bloc.dart';
import 'package:collab_tasks/features/settings/data/datastore/app_settings_datastore.dart';
import 'package:collab_tasks/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_saved_language_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_task_view_preferences_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_theme_preference_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_saved_language_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_task_view_preferences_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_theme_preference_use_case.dart';
import 'package:collab_tasks/features/settings/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_bloc.dart';
import 'package:collab_tasks/features/tasks/data/local/db/app_database.dart';
import 'package:collab_tasks/features/tasks/data/local/tasks_local_data_source.dart';
import 'package:collab_tasks/features/tasks/data/notifications/task_notifications_manager.dart';
import 'package:collab_tasks/features/tasks/data/remote/aws_remote_data_source.dart';
import 'package:collab_tasks/features/tasks/data/remote/firebase_remote_data_source.dart';
import 'package:collab_tasks/features/tasks/data/remote/tasks_remote_data_source.dart';
import 'package:collab_tasks/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:collab_tasks/features/tasks/data/services/localized_task_notification_titles_provider.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_titles_provider.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/add_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/cancel_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/consume_initial_notification_payload_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/filter_and_sort_tasks_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/get_notification_tap_stream_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/schedule_task_notifications_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/sync_tasks_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/update_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/watch_tasks_use_case.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/features/working_groups/data/local/working_groups_local_data_source.dart';
import 'package:collab_tasks/features/working_groups/data/remote/aws_working_groups_remote_data_source.dart';
import 'package:collab_tasks/features/working_groups/data/remote/firebase_working_groups_remote_data_source.dart';
import 'package:collab_tasks/features/working_groups/data/remote/working_groups_remote_data_source.dart';
import 'package:collab_tasks/features/working_groups/data/repositories/working_groups_repository_impl.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/add_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/claim_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/create_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/delete_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_participants_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_tasks_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_groups_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/invite_group_participant_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/leave_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/release_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/sync_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/sync_working_groups_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/update_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/update_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Import for @visibleForTesting
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/chat_notification_service.dart';

final getIt = GetIt.instance;

void setupLocator(SharedPreferences sharedPreferences) {
  // Hot restart can re-run setup with a stale container.
  if (getIt.isRegistered<SharedPreferences>()) {
    getIt.reset();
  }

  getIt
    ..registerLazySingleton<SharedPreferences>(() => sharedPreferences)
    ..registerLazySingleton<AppSettingsDatastore>(() => AppSettingsDatastore(getIt()))
    ..registerLazySingleton<AppSettingsRepository>(() => AppSettingsRepositoryImpl(getIt()))
    ..registerLazySingleton<TaskNotificationTitlesProvider>(
      () => LocalizedTaskNotificationTitlesProvider(getIt()),
    )
    ..registerLazySingleton<TaskNotificationsManager>(
      () => TaskNotificationsManager(titleProvider: getIt()),
    )
    ..registerLazySingleton<TaskNotificationService>(() => getIt<TaskNotificationsManager>())
    ..registerLazySingleton<AppDatabase>(() => AppDatabase())
    ..registerLazySingleton<TasksLocalDataSource>(() => DriftTasksLocalDataSource(getIt()))
    ..registerLazySingleton<WorkingGroupsLocalDataSource>(
      () => DriftWorkingGroupsLocalDataSource(getIt()),
    )
    ..registerLazySingleton<TasksRemoteDataSource>(
      () => switch (storageBackend) {
        StorageBackend.aws => const AWSRemoteDataSource(),
        StorageBackend.firebase => FirebaseRemoteDataSource(
          firestore: getIt<FirebaseFirestore>(),
          storage: getIt<FirebaseStorage>(),
          auth: getIt<FirebaseAuth>(),
        ),
      },
    )
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => switch (chatBackend) {
        // TODO change when WebSocketChatRemoteDataSource will create
        ChatBackend.webSocket => FirebaseChatRemoteDataSource(
          firestore: getIt<FirebaseFirestore>(),
        ),
        ChatBackend.firebase => FirebaseChatRemoteDataSource(firestore: getIt<FirebaseFirestore>()),
      },
    )
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: getIt<ChatRemoteDataSource>()),
    )
    ..registerLazySingleton<WorkingGroupsRemoteDataSource>(
      () => switch (authBackend) {
        AuthBackend.aws => const AWSWorkingGroupsRemoteDataSource(),
        AuthBackend.firebase => FirebaseWorkingGroupsRemoteDataSource(
          firestore: getIt<FirebaseFirestore>(),
        ),
      },
    )
    ..registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(
        localDataSource: getIt(),
        remoteDataSource: getIt(),
        authRepository: getIt(),
        notificationService: getIt(),
      ),
    )
    ..registerLazySingleton<WorkingGroupsRepository>(
      () => WorkingGroupsRepositoryImpl(
        localDataSource: getIt(),
        remoteDataSource: getIt(),
        authRepository: getIt(),
      ),
    )
    ..registerLazySingleton(() => WatchTasksUseCase(getIt()))
    ..registerLazySingleton(() => AddTaskUseCase(getIt()))
    ..registerLazySingleton(() => SyncTasksUseCase(getIt()))
    ..registerLazySingleton(() => UpdateTaskUseCase(getIt()))
    ..registerLazySingleton(() => DeleteTaskUseCase(getIt()))
    ..registerLazySingleton(() => const FilterAndSortTasksUseCase())
    ..registerLazySingleton(() => GetSavedLanguageUseCase(getIt()))
    ..registerLazySingleton(() => SetSavedLanguageUseCase(getIt()))
    ..registerLazySingleton(() => GetThemePreferenceUseCase(getIt()))
    ..registerLazySingleton(() => SetThemePreferenceUseCase(getIt()))
    ..registerLazySingleton(() => GetTaskViewPreferencesUseCase(getIt()))
    ..registerLazySingleton(() => SetTaskViewPreferencesUseCase(getIt()))
    ..registerLazySingleton(() => ScheduleTaskNotificationsUseCase(getIt()))
    ..registerLazySingleton(() => CancelTaskNotificationsUseCase(getIt()))
    ..registerLazySingleton(() => GetNotificationTapStreamUseCase(getIt()))
    ..registerLazySingleton(() => ConsumeInitialNotificationPayloadUseCase(getIt()))
    ..registerLazySingleton(() => GetWorkingGroupsUseCase(getIt()))
    ..registerLazySingleton(() => GetWorkingGroupUseCase(getIt()))
    ..registerLazySingleton(() => GetGroupTasksUseCase(getIt()))
    ..registerLazySingleton(() => GetGroupParticipantsUseCase(getIt()))
    ..registerLazySingleton(() => CreateWorkingGroupUseCase(getIt()))
    ..registerLazySingleton(() => UpdateWorkingGroupUseCase(getIt()))
    ..registerLazySingleton(() => DeleteWorkingGroupUseCase(getIt()))
    ..registerLazySingleton(() => InviteGroupParticipantUseCase(getIt()))
    ..registerLazySingleton(() => LeaveWorkingGroupUseCase(getIt(), getIt()))
    ..registerLazySingleton(() => AddGroupTaskUseCase(getIt()))
    ..registerLazySingleton(() => UpdateGroupTaskUseCase(getIt()))
    ..registerLazySingleton(() => ClaimGroupTaskUseCase(getIt()))
    ..registerLazySingleton(() => ReleaseGroupTaskUseCase(getIt()))
    ..registerLazySingleton(() => SyncWorkingGroupsUseCase(getIt()))
    ..registerLazySingleton(() => SyncWorkingGroupUseCase(getIt()))
    ..registerLazySingleton(() => WatchMessagesUseCase(getIt<ChatRepository>()))
    ..registerLazySingleton(() => SendMessageUseCase(getIt<ChatRepository>()))
    ..registerLazySingleton(() => GetChatUseCase(getIt<ChatRepository>()))
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance)
    ..registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  if (authBackend == AuthBackend.aws) {
    getIt
      ..registerLazySingleton<AwsAuthRepositoryImpl>(
        () => AwsAuthRepositoryImpl(requireEmailVerifiedForEmailLogin: true),
      )
      ..registerLazySingleton<AuthRepository>(() => getIt<AwsAuthRepositoryImpl>())
      ..registerLazySingleton<CognitoAuthRepository>(() => getIt<AwsAuthRepositoryImpl>());
  } else {
    getIt
      ..registerLazySingleton<AuthRepository>(
        () => FirebaseAuthRepositoryImpl(
          firebaseAuth: getIt<FirebaseAuth>(),
          googleSignIn: getIt<GoogleSignIn>(),
          requireEmailVerifiedForEmailLogin: true,
        ),
      )
      ..registerLazySingleton<ChatNotificationService>(
        () => ChatNotificationService(firestore: getIt<FirebaseFirestore>()),
      );
  }

  getIt
    ..registerLazySingleton(() => RegisterWithEmailUseCase(getIt()))
    ..registerLazySingleton(() => LoginWithEmailUseCase(getIt()))
    ..registerLazySingleton(() => SignInWithGoogleUseCase(getIt()))
    ..registerLazySingleton(() => ResetPasswordUseCase(getIt()))
    ..registerLazySingleton(
      () => ConfirmSignUpUseCase(
        getIt.isRegistered<CognitoAuthRepository>() ? getIt<CognitoAuthRepository>() : null,
      ),
    )
    ..registerLazySingleton(
      () => ConfirmResetPasswordUseCase(
        getIt.isRegistered<CognitoAuthRepository>() ? getIt<CognitoAuthRepository>() : null,
      ),
    )
    ..registerLazySingleton(
      () => ResendSignUpCodeUseCase(
        getIt.isRegistered<CognitoAuthRepository>() ? getIt<CognitoAuthRepository>() : null,
      ),
    )
    ..registerLazySingleton(() => LogOutUseCase(getIt()))
    ..registerLazySingleton(() => WatchAuthStateUseCase(getIt()))
    ..registerFactory(
      () => LocaleCubit(getSavedLanguageUseCase: getIt(), setSavedLanguageUseCase: getIt()),
    )
    ..registerFactory(
      () => ThemeBloc(getThemePreferenceUseCase: getIt(), setThemePreferenceUseCase: getIt()),
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
        notificationService: getIt(),
        workingGroupsRepository: getIt(),
        // Безопасный проброс: если сервис зарегистрирован в GetIt (при Firebase), он прилетит в Блок.
        // Если выбран AWS Amplify — передастся null.
        chatNotificationService: getIt.isRegistered<ChatNotificationService>()
            ? getIt<ChatNotificationService>()
            : null,
      ),
    )
    ..registerFactory(() => ConfirmationDialogBloc())
    ..registerFactory(
      () => WorkingGroupsBloc(
        getWorkingGroupsUseCase: getIt(),
        createWorkingGroupUseCase: getIt(),
        syncWorkingGroupsUseCase: getIt(),
      ),
    )
    ..registerFactoryParam<GroupDetailsBloc, String, void>(
      (groupId, _) => GroupDetailsBloc(
        groupId: groupId,
        getWorkingGroupUseCase: getIt(),
        getGroupTasksUseCase: getIt(),
        getGroupParticipantsUseCase: getIt(),
        addGroupTaskUseCase: getIt(),
        updateWorkingGroupUseCase: getIt(),
        deleteWorkingGroupUseCase: getIt(),
        inviteGroupParticipantUseCase: getIt(),
        leaveWorkingGroupUseCase: getIt(),
        watchAuthStateUseCase: getIt<WatchAuthStateUseCase>(),
        syncWorkingGroupUseCase: getIt(),
      ),
    )
    ..registerFactoryParam<GroupTaskDetailsBloc, GroupTask, void>(
      (task, _) => GroupTaskDetailsBloc(
        task: task,
        watchAuthStateUseCase: getIt(),
        claimGroupTaskUseCase: getIt(),
        releaseGroupTaskUseCase: getIt(),
        updateGroupTaskUseCase: getIt(),
      ),
    )
    ..registerFactory(
      () => TaskBloc(
        watchTasksUseCase: getIt(),
        addTaskUseCase: getIt(),
        updateTaskUseCase: getIt(),
        deleteTaskUseCase: getIt(),
        getTaskViewPreferencesUseCase: getIt(),
        setTaskViewPreferencesUseCase: getIt(),
        scheduleTaskNotificationsUseCase: getIt(),
        cancelTaskNotificationsUseCase: getIt(),
        getNotificationTapStreamUseCase: getIt(),
        consumeInitialNotificationPayloadUseCase: getIt(),
        syncTasksUseCase: getIt(),
      ),
    )
    ..registerFactory<ChatBloc>(
      () => ChatBloc(
        watchMessagesUseCase: getIt<WatchMessagesUseCase>(),
        sendMessageUseCase: getIt<SendMessageUseCase>(),
        getChatUseCase: getIt<GetChatUseCase>(),
      ),
    );
}

// Helper to reset GetIt for testing purposes
@visibleForTesting
void resetLocator() {
  getIt.reset();
}
