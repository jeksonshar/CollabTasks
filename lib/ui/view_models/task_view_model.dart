import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import '../../domain/use_cases/add_task_use_case.dart';
import '../../domain/use_cases/delete_task_use_case.dart';
import '../../domain/use_cases/get_tasks_use_case.dart';

class TaskViewModel extends ChangeNotifier {
  final GetTasksUseCase getTasksUseCase;
  final AddTaskUseCase addTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;

  TaskViewModel({
    required this.getTasksUseCase,
    required this.addTaskUseCase,
    required this.deleteTaskUseCase,
  });

  List<Task> tasks = [];
  bool isLoading = false;

  Future<void> loadTasks() async {
    debugPrint('TaskViewModel.loadTasks: start');
    isLoading = true;
    notifyListeners();

    try {
      // simulate a loading delay
      await Future.delayed(const Duration(seconds: 1));

      final loaded = await getTasksUseCase();
      // tasks = List<Task>.from(loaded); // if in TaskRepositoryImpl used TaskModel use it
      tasks = loaded;
      debugPrint('TaskViewModel.loadTasks: loaded ${tasks.length}');
    } catch(e, s) {
      debugPrint('TaskViewModel.loadTasks ERROR: $e\n$s');
      tasks = [];
    }

    isLoading = false;
    notifyListeners();
    debugPrint('TaskViewModel.loadTasks: end');
  }

  Future<void> addTask(String text) async {
    final task = Task(id: DateTime.now().toIso8601String(), text: text);
    debugPrint('TaskViewModel.addTask: start text="$text"');
    try {
      await addTaskUseCase(task);
      tasks.add(task);
      notifyListeners();
      debugPrint('TaskViewModel.addTask: done total=${tasks.length}');
    } catch(e,s) {
      debugPrint('TaskViewModel.addTask ERROR: $e\n$s');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await deleteTaskUseCase(id);
      tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch(e,s) {
      debugPrint('TaskViewModel.deleteTask ERROR: $e\n$s');
    }

  }
}
