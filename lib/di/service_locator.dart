import 'package:get_it/get_it.dart';

import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/use_cases/add_task_use_case.dart';
import '../../domain/use_cases/delete_task_use_case.dart';
import '../../domain/use_cases/get_tasks_use_case.dart';
import '../../ui/view_models/task_view_model.dart';
import '../domain/use_cases/update_task_use_case.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // Data / repositories
  getIt.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl());

  // Use cases
  getIt.registerLazySingleton(() => GetTasksUseCase(getIt()));
  getIt.registerLazySingleton(() => AddTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteTaskUseCase(getIt()));

  // ViewModel (factory so each consumer can have its own if needed)
  getIt.registerFactory(
    () => TaskViewModel(
      getTasksUseCase: getIt(),
      addTaskUseCase: getIt(),
      updateTaskUseCase: getIt(),
      deleteTaskUseCase: getIt(),
    ),
  );
}
