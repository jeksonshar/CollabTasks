import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/task_error_type.dart';
import '../../../core/enums/task_sort_direction.dart';
import '../../../core/enums/task_sort_type.dart';
import '../../../domain/models/task.dart';
import '../../../domain/use_cases/add_task_use_case.dart';
import '../../../domain/use_cases/delete_task_use_case.dart';
import '../../../domain/use_cases/get_tasks_use_case.dart';
import '../../../domain/use_cases/update_task_use_case.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final AddTaskUseCase addTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;

  TaskBloc({
    required this.getTasksUseCase,
    required this.addTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
  }) : super(const TaskState()) {
    // Listen to the flow of events and transform them into states
    on<LoadTasksStarted>(_onLoadTasks);
    on<TaskAdded>(_onAddTask);
    on<TaskUpdated>(_onUpdateTask);
    on<TaskDeleted>(_onDeleteTask);
    on<SortChanged>(_onSortChanged);
    on<FilterChanged>((event, emit) => emit(state.copyWith(filterType: event.filterType)));
    on<TaskPinToggled>(_onToggleTaskPin);
    on<ErrorCleared>((event, emit) => emit(state.copyWith(errorType: null)));
    on<ActionCleared>(
          (event, emit) =>
          emit(state.copyWith(lastAction: TaskAction.none, lastActionTaskTitle: null)),
    );
  }

  Future<void> _onLoadTasks(LoadTasksStarted event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.loading));
    try {
      final tasks = await getTasksUseCase();
      emit(
        state.copyWith(
          status: TaskStatus.success,
          tasks: _sortTasks(tasks, state.sortType, state.sortDirection),
        ),
      );
      debugPrint('TaskBloc.loadTasks SUCCESS: ${state.tasks}');
    } catch (e, s) {
      debugPrint('TaskBloc.loadTasks ERROR: $e\n$s');
      emit(state.copyWith(status: TaskStatus.failure, errorType: TaskErrorType.load));
    }
  }

  Future<void> _onAddTask(TaskAdded event, Emitter<TaskState> emit) async {
    var uuid = const Uuid();
    final task = Task(
      id: uuid.v4(),
      createdAt: DateTime.now(),
      title: event.draft.title,
      text: event.draft.textJson,
      priority: event.draft.priority,
      attachments: event.draft.attachments,
      isCompleted: event.draft.isCompleted,
      deadline: event.draft.deadline,
    );

    try {
      await addTaskUseCase(task);

      final taskTitle = event.draft.title;
      final newTasks = [...state.tasks, task];
      emit(
        state.copyWith(
          tasks: _sortTasks(newTasks, state.sortType, state.sortDirection),
          lastAction: TaskAction.add,
          lastActionTaskTitle: taskTitle,
        ),
      );
    } catch (_) {
      emit(state.copyWith(errorType: TaskErrorType.add));
    }
  }

  Future<void> _onUpdateTask(TaskUpdated event, Emitter<TaskState> emit) async {
    final oldTask = state.tasks.firstWhere((t) => t.id == event.id);
    final task = Task(
      id: event.id,
      createdAt: event.createdAt,
      title: event.draft.title,
      text: event.draft.textJson,
      priority: event.draft.priority,
      attachments: event.draft.attachments,
      isCompleted: event.draft.isCompleted,
      deadline: event.draft.deadline,
      isPinned: oldTask.isPinned,
    );

    try {
      await updateTaskUseCase(task);
      final taskTitle = event.draft.title; // Use the new title from draft

      final index = state.tasks.indexWhere((t) => t.id == event.id);
      if (index == -1) return;

      final newTasks = [...state.tasks];
      newTasks[index] = task;

      emit(
        state.copyWith(
          tasks: _sortTasks(newTasks, state.sortType, state.sortDirection),
          lastAction: TaskAction.update,
          lastActionTaskTitle: taskTitle,
        ),
      );
    } catch (e, s) {
      debugPrint('TaskViewModel.updateTask ERROR: $e\n$s');
      emit(state.copyWith(errorType: TaskErrorType.update));
    }
  }

  Future<void> _onDeleteTask(TaskDeleted event, Emitter<TaskState> emit) async {
    try {
      await deleteTaskUseCase(event.id);
      final taskTitle = state.tasks
          .firstWhere((t) => t.id == event.id)
          .title;

      emit(
        state.copyWith(
          tasks: state.tasks.where((task) => task.id != event.id).toList(),
          lastAction: TaskAction.delete,
          lastActionTaskTitle: taskTitle,
        ),
      );
    } catch (e, s) {
      debugPrint('TaskViewModel.deleteTask ERROR: $e\n$s');
      emit(state.copyWith(errorType: TaskErrorType.delete));
    }
  }

  Future<void> _onToggleTaskPin(TaskPinToggled event, Emitter<TaskState> emit) async {
    final index = state.tasks.indexWhere((t) => t.id == event.id);
    if (index == -1) return;

    final task = state.tasks[index];
    final updatedTask = task.copyWith(isPinned: !task.isPinned);

    try {
      await updateTaskUseCase(updatedTask);

      final newTasks = [...state.tasks];
      newTasks[index] = updatedTask;

      emit(state.copyWith(tasks: _sortTasks(newTasks, state.sortType, state.sortDirection)));
    } catch (e, s) {
      debugPrint('TaskBloc.toggleTaskPin ERROR: $e\n$s');
      emit(state.copyWith(errorType: TaskErrorType.update));
    }
  }

  void _onSortChanged(SortChanged event, Emitter<TaskState> emit) {
    TaskSortDirection newDirection = state.sortDirection;
    if (state.sortType == event.sortType) {
      newDirection = state.sortDirection.isAscending
          ? TaskSortDirection.bottomToTop
          : TaskSortDirection.topToBottom;
    } else {
      newDirection = TaskSortDirection.topToBottom;
    }

    emit(
      state.copyWith(
        sortType: event.sortType,
        sortDirection: newDirection,
        tasks: _sortTasks(state.tasks, event.sortType, newDirection),
        lastAction: TaskAction.none,
        lastActionTaskTitle: null,
      ),
    );
  }

  List<Task> _sortTasks(List<Task> tasks, TaskSortType type, TaskSortDirection dir) {
    final pinned = tasks.where((t) => t.isPinned).toList();
    final others = tasks.where((t) => !t.isPinned).toList();

    int compare<T extends Comparable>(T a, T b) {
      return dir.isAscending ? b.compareTo(a) : a.compareTo(b);
    }

    void sortList(List<Task> list) {
      switch (type) {
        case TaskSortType.byDateCreated:
          list.sort((a, b) => compare(a.createdAt, b.createdAt));
        case TaskSortType.byPriority:
          list.sort((a, b) => compare(a.priority, b.priority));
        case TaskSortType.byTitle:
          list.sort((a, b) => compare(a.title, b.title));
      }
    }

    sortList(pinned);
    sortList(others);

    return [...pinned, ...others];
  }
}
