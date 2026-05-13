import 'package:collab_tasks/core/notifications/notifications_manager.dart';
import 'package:collab_tasks/data/datastore/app_settings_datastore.dart';
import 'package:collab_tasks/data/local/db/app_database.dart';
import 'package:collab_tasks/data/repositories/app_settings_repository_impl.dart';
import 'package:collab_tasks/data/repositories/task_repository_impl.dart';
import 'package:collab_tasks/domain/repositories/app_settings_repository.dart';
import 'package:collab_tasks/domain/repositories/task_repository.dart';
import 'package:collab_tasks/domain/use_cases/add_task_use_case.dart';
import 'package:collab_tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:collab_tasks/domain/use_cases/get_saved_language_use_case.dart';
import 'package:collab_tasks/domain/use_cases/get_task_view_preferences_use_case.dart';
import 'package:collab_tasks/domain/use_cases/set_saved_language_use_case.dart';
import 'package:collab_tasks/domain/use_cases/set_task_view_preferences_use_case.dart';
import 'package:collab_tasks/domain/use_cases/update_task_use_case.dart';
import 'package:collab_tasks/domain/use_cases/watch_tasks_use_case.dart';
import 'package:collab_tasks/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_bloc.dart';
import 'package:collab_tasks/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:flutter/foundation.dart'; // Import for @visibleForTesting
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

void setupLocator(SharedPreferences sharedPreferences) {
  getIt
    ..registerLazySingleton<SharedPreferences>(() => sharedPreferences)
    ..registerLazySingleton<NotificationsManager>(() => NotificationsManager())
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
    ..registerFactory(
      () => LocaleCubit(getSavedLanguageUseCase: getIt(), setSavedLanguageUseCase: getIt()),
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
        notificationsManager: getIt(),
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
