import 'package:collab_tasks/core/notifications/notifications_manager.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_task_view_preferences_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_task_view_preferences_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/add_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/update_task_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/use_cases/watch_tasks_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchTasksUseCase extends Mock implements WatchTasksUseCase {}

class MockAddTaskUseCase extends Mock implements AddTaskUseCase {}

class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

class MockGetTaskViewPreferencesUseCase extends Mock implements GetTaskViewPreferencesUseCase {}

class MockSetTaskViewPreferencesUseCase extends Mock implements SetTaskViewPreferencesUseCase {}

class MockNotificationsManager extends Mock implements NotificationsManager {}
