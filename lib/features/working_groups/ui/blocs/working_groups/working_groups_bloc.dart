import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/create_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_groups_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkingGroupsBloc extends Bloc<WorkingGroupsEvent, WorkingGroupsState> {
  WorkingGroupsBloc({
    required GetWorkingGroupsUseCase getWorkingGroupsUseCase,
    required CreateWorkingGroupUseCase createWorkingGroupUseCase,
  }) : _getWorkingGroupsUseCase = getWorkingGroupsUseCase,
       _createWorkingGroupUseCase = createWorkingGroupUseCase,
       super(const WorkingGroupsState()) {
    on<WorkingGroupsStarted>(_onStarted);
    on<WorkingGroupCreated>(_onCreated);
  }

  final GetWorkingGroupsUseCase _getWorkingGroupsUseCase;
  final CreateWorkingGroupUseCase _createWorkingGroupUseCase;

  Future<void> _onStarted(WorkingGroupsStarted event, Emitter<WorkingGroupsState> emit) async {
    emit(state.copyWith(status: WorkingGroupsStatus.loading));
    await emit.forEach<List<WorkingGroup>>(
      _getWorkingGroupsUseCase(),
      onData: (groups) => state.copyWith(status: WorkingGroupsStatus.loaded, groups: groups),
      onError: (error, _) =>
          state.copyWith(status: WorkingGroupsStatus.error, errorMessage: error.toString()),
    );
  }

  Future<void> _onCreated(WorkingGroupCreated event, Emitter<WorkingGroupsState> emit) async {
    try {
      await _createWorkingGroupUseCase(title: event.title, description: event.description);
    } catch (error) {
      emit(state.copyWith(status: WorkingGroupsStatus.error, errorMessage: error.toString()));
    }
  }
}
