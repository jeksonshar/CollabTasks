import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:equatable/equatable.dart';

enum WorkingGroupsStatus { loading, loaded, error }

class WorkingGroupsState extends Equatable {
  const WorkingGroupsState({
    this.status = WorkingGroupsStatus.loading,
    this.groups = const [],
    this.errorMessage,
  });

  final WorkingGroupsStatus status;
  final List<WorkingGroup> groups;
  final String? errorMessage;

  WorkingGroupsState copyWith({
    WorkingGroupsStatus? status,
    List<WorkingGroup>? groups,
    String? errorMessage,
  }) {
    return WorkingGroupsState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, groups, errorMessage];
}
