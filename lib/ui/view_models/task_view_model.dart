import 'package:flutter/material.dart';

import '../../core/enums/task_sort_direction.dart';
import '../../core/enums/task_sort_type.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_draft.dart';
import '../../domain/use_cases/add_task_use_case.dart';
import '../../domain/use_cases/delete_task_use_case.dart';
import '../../domain/use_cases/get_tasks_use_case.dart';
import '../../domain/use_cases/update_task_use_case.dart';

enum TaskErrorType { load, add, update, delete } // TODO in future use sealed class if it need

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
  TaskErrorType? _errorType;

  TaskSortType _sortType = TaskSortType.byDateCreated;
  TaskSortDirection _sortDirection = TaskSortDirection.topToBottom;

  List<Task> get tasks => List.unmodifiable(_tasks);

  bool get isLoading => _isLoading;

  TaskErrorType? get errorType => _errorType;

  TaskSortType get sortType => _sortType;

  TaskSortDirection get sortDirection => _sortDirection;

  Future<void> loadTasks() async {
    debugPrint('TaskViewModel.loadTasks: start');
    _setLoading(true);
    _setError(null);

    try {
      final loadedTasks = await getTasksUseCase();
      _tasks = _sortTasks(loadedTasks);
      notifyListeners();
    } catch (e, s) {
      debugPrint('TaskViewModel.loadTasks ERROR: $e\n$s');
      _tasks = <Task>[];
      _setError(TaskErrorType.load);
    } finally {
      _setLoading(false);
      debugPrint('TaskViewModel.loadTasks: end');
    }
  }

  void setSortType(TaskSortType value) {
    if (_sortType == value) {
      _sortDirection = _sortDirection == TaskSortDirection.topToBottom
          ? TaskSortDirection.bottomToTop
          : TaskSortDirection.topToBottom;
    } else {
      _sortType = value;
      _sortDirection = TaskSortDirection.topToBottom;
    }
    _tasks = _sortTasks(_tasks);
    notifyListeners();
  }

  Future<void> addTask(TaskDraft draft) async {
    final task = Task(
      id: DateTime.now().toIso8601String(),
      createdAt: DateTime.now(),
      title: draft.title,
      text: draft.textJson,
      priority: draft.priority,
      attachments: draft.attachments,
    );

    _setError(null);

    try {
      await addTaskUseCase(task);
      _tasks = _sortTasks([..._tasks, task]);
      notifyListeners();
    } catch (e, s) {
      debugPrint('TaskViewModel.addTask ERROR: $e\n$s');
      _setError(TaskErrorType.add);
      rethrow;
    }
  }

  Future<void> updateTask(String id, DateTime createdAt, TaskDraft draft) async {
    final task = Task(
      id: id,
      createdAt: createdAt,
      title: draft.title,
      text: draft.textJson,
      priority: draft.priority,
      attachments: draft.attachments,
    );

    _setError(null);

    try {
      await updateTaskUseCase(task);

      final index = _tasks.indexWhere((task) => task.id == id);
      if (index == -1) return;

      final newTasks = [..._tasks];
      newTasks[index] = task;
      _tasks = _sortTasks(newTasks);
      notifyListeners();
    } catch (e, s) {
      debugPrint('TaskViewModel.updateTask ERROR: $e\n$s');
      _setError(TaskErrorType.update);
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    _setError(null);

    try {
      await deleteTaskUseCase(id);
      _tasks = _tasks.where((task) => task.id != id).toList();
      notifyListeners();
    } catch (e, s) {
      debugPrint('TaskViewModel.deleteTask ERROR: $e\n$s');
      _setError(TaskErrorType.delete);
    }
  }

  void clearError() {
    _setError(null);
  }

  List<Task> _sortTasks(List<Task> tasks) {
    final sorted = [...tasks];

    int compare<T extends Comparable>(T a, T b) {
      final result = a.compareTo(b);
      return _sortDirection.isAscending ? -result : result;
    }

    switch (_sortType) {
      case TaskSortType.byDateCreated:
        sorted.sort((a, b) => compare(a.createdAt, b.createdAt));
        break;
      case TaskSortType.byPriority:
        sorted.sort((a, b) => compare(a.priority, b.priority));
        break;
      case TaskSortType.byTitle:
        sorted.sort((a, b) => compare(a.text, b.text));
        break;
    }

    return sorted;
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(TaskErrorType? value) {
    if (_errorType == value) return;
    _errorType = value;
    notifyListeners();
  }
}
