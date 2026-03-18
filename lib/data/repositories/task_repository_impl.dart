import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  static const _tasksKey = 'tasks_list';

  @override
  Future<void> addTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_tasksKey) ?? [];
    list.add(Task(id: task.id, text: task.text).toJson());
    await prefs.setStringList(_tasksKey, list);
  }

  @override
  Future<void> updateTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_tasksKey) ?? [];

    final index = list.indexWhere((item) {
      final decoded = Task.fromJson(item);
      return decoded.id == task.id;
    });

    if (index == -1) return;

    list[index] = task.toJson();
    await prefs.setStringList(_tasksKey, list);
  }

  @override
  Future<void> deleteTask(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_tasksKey) ?? [];
    list.removeWhere((jsonStr) {
      try {
        final model = Task.fromJson(jsonStr);
        return model.id == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_tasksKey, list);
  }

  @override
  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_tasksKey) ?? [];
    return list.map((j) => Task.fromJson(j)).toList();
  }
}
