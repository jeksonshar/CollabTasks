import 'package:get_it/get_it.dart';

import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/use_cases/add_task_use_case.dart';
import '../../domain/use_cases/delete_task_use_case.dart';
import '../../domain/use_cases/get_tasks_use_case.dart';
import '../../ui/view_models/task_view_model.dart';
import '../data/local/db/app_database.dart';
import '../domain/use_cases/update_task_use_case.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  getIt.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(getIt<AppDatabase>()));

  getIt.registerLazySingleton(() => GetTasksUseCase(getIt()));
  getIt.registerLazySingleton(() => AddTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteTaskUseCase(getIt()));

  getIt.registerFactory(
    () => TaskViewModel(
      getTasksUseCase: getIt(),
      addTaskUseCase: getIt(),
      updateTaskUseCase: getIt(),
      deleteTaskUseCase: getIt(),
    ),
  );
}
