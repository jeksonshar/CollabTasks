import 'package:flutter/material.dart';

import '../../domain/models/task.dart';
import '../../domain/use_cases/add_task_use_case.dart';
import '../../domain/use_cases/delete_task_use_case.dart';
import '../../domain/use_cases/get_tasks_use_case.dart';
import '../../domain/use_cases/update_task_use_case.dart';
import '../dialogs/task_dialog.dart';

class TaskViewModel extends ChangeNotifier {
  final GetTasksUseCase getTasksUseCase;
  final AddTaskUseCase addTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;

  TaskViewModel({
    required this.getTasksUseCase,
    required this.addTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
  });

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Task> get tasks => List.unmodifiable(_tasks);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadTasks(String errorMessage) async {
    debugPrint('TaskViewModel.loadTasks: start');
    _setLoading(true);
    _setError(null);

    try {
      final loadedTasks = await getTasksUseCase();
      _tasks = loadedTasks;
    } catch (e, s) {
      debugPrint('TaskViewModel.loadTasks ERROR: $e\n$s');
      _tasks = [];
      _setError(errorMessage);
    } finally {
      _setLoading(false);
      debugPrint('TaskViewModel.loadTasks: end');
    }
  }

  Future<void> addTask(TaskDialogResult taskDialogResult, String errorMessage) async {
    final task = Task(
      id: DateTime.now().toIso8601String(),
      text: taskDialogResult.text,
      attachments: taskDialogResult.attachments,
    );

    _setError(null);

    try {
      await addTaskUseCase(task);
      _tasks = [..._tasks, task];
      notifyListeners();
    } catch (e, s) {
      debugPrint('TaskViewModel.addTask ERROR: $e\n$s');
      _setError(errorMessage);
      rethrow;
    }
  }

  Future<void> updateTask(String id, TaskDialogResult taskDialogResult, String errorMessage) async {
    final task = Task(
      id: id,
      text: taskDialogResult.text,
      attachments: taskDialogResult.attachments,
    );

    _setError(null);

    try {
      await updateTaskUseCase(task);

      final index = _tasks.indexWhere((task) => task.id == id);
      if (index == -1) return;

      final newTasks = [..._tasks];
      newTasks[index] = task;
      _tasks = newTasks;
      notifyListeners();
    } catch (e, s) {
      debugPrint('TaskViewModel.updateTask ERROR: $e\n$s');
      _setError(errorMessage);
      rethrow;
    }
  }

  Future<void> deleteTask(String id, String errorMessage) async {
    _setError(null);

    try {
      await deleteTaskUseCase(id);
      _tasks = _tasks.where((task) => task.id != id).toList();
      notifyListeners();
    } catch (e, s) {
      debugPrint('TaskViewModel.deleteTask ERROR: $e\n$s');
      _setError(errorMessage);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    if (_errorMessage == value) return;
    _errorMessage = value;
    notifyListeners();
  }
}
