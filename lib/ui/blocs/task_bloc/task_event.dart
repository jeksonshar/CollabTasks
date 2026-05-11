import 'package:equatable/equatable.dart';

import '../../../core/enums/task_filter_type.dart';
import '../../../core/enums/task_sort_type.dart';
import '../../../domain/models/task_draft.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasksStarted extends TaskEvent {}

class TaskAdded extends TaskEvent {
  final TaskDraft draft;

  const TaskAdded(this.draft);
}

class TaskUpdated extends TaskEvent {
  final String id;
  final DateTime createdAt;
  final TaskDraft draft;

  const TaskUpdated(this.id, this.createdAt, this.draft);
}

class TaskDeleted extends TaskEvent {
  final String id;

  const TaskDeleted(this.id);
}

class SortChanged extends TaskEvent {
  final TaskSortType sortType;

  const SortChanged(this.sortType);
}

class FilterChanged extends TaskEvent {
  final TaskFilterType filterType;

  const FilterChanged(this.filterType);

  @override
  List<Object?> get props => [filterType];
}

class SearchChanged extends TaskEvent {
  final String query;

  const SearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ErrorCleared extends TaskEvent {}

class ActionCleared extends TaskEvent {
  const ActionCleared();
}

class TaskPinToggled extends TaskEvent {
  final String id;

  const TaskPinToggled(this.id);

  @override
  List<Object?> get props => [id];
}

class NotificationTaskOpened extends TaskEvent {
  final String taskId;

  const NotificationTaskOpened(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
