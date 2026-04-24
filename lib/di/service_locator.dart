import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datastore/app_settings_datastore.dart';
import '../../data/repositories/app_settings_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/use_cases/add_task_use_case.dart';
import '../../domain/use_cases/delete_task_use_case.dart';
import '../../domain/use_cases/get_saved_language_use_case.dart';
import '../../domain/use_cases/get_task_view_preferences_use_case.dart';
import '../../domain/use_cases/get_tasks_use_case.dart';
import '../../domain/use_cases/set_saved_language_use_case.dart';
import '../../domain/use_cases/set_task_view_preferences_use_case.dart';
import '../data/local/db/app_database.dart';
import '../domain/use_cases/update_task_use_case.dart';
import '../ui/blocs/locale_cubit/locale_cubit.dart';
import '../ui/blocs/task_bloc/task_bloc.dart';

final getIt = GetIt.instance;

void setupLocator(SharedPreferences sharedPreferences) {
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<AppSettingsDatastore>(() => AppSettingsDatastore(getIt()));
  getIt.registerLazySingleton<AppSettingsRepository>(() => AppSettingsRepositoryImpl(getIt()));

  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(getIt<AppDatabase>()));

  getIt.registerLazySingleton(() => GetTasksUseCase(getIt()));
  getIt.registerLazySingleton(() => AddTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => GetSavedLanguageUseCase(getIt()));
  getIt.registerLazySingleton(() => SetSavedLanguageUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTaskViewPreferencesUseCase(getIt()));
  getIt.registerLazySingleton(() => SetTaskViewPreferencesUseCase(getIt()));

  getIt.registerFactory(
    () => LocaleCubit(getSavedLanguageUseCase: getIt(), setSavedLanguageUseCase: getIt()),
  );

  getIt.registerFactory(
    () => TaskBloc(
      getTasksUseCase: getIt(),
      addTaskUseCase: getIt(),
      updateTaskUseCase: getIt(),
      deleteTaskUseCase: getIt(),
      getTaskViewPreferencesUseCase: getIt(),
      setTaskViewPreferencesUseCase: getIt(),
    ),
  );
}
