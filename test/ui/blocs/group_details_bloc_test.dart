import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/add_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/delete_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_participants_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_tasks_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/invite_group_participant_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/leave_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/sync_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/update_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWorkingGroupUseCase extends Mock implements GetWorkingGroupUseCase {}
class MockGetGroupTasksUseCase extends Mock implements GetGroupTasksUseCase {}
class MockGetGroupParticipantsUseCase extends Mock implements GetGroupParticipantsUseCase {}
class MockAddGroupTaskUseCase extends Mock implements AddGroupTaskUseCase {}
class MockUpdateWorkingGroupUseCase extends Mock implements UpdateWorkingGroupUseCase {}
class MockDeleteWorkingGroupUseCase extends Mock implements DeleteWorkingGroupUseCase {}
class MockInviteGroupParticipantUseCase extends Mock implements InviteGroupParticipantUseCase {}
class MockLeaveWorkingGroupUseCase extends Mock implements LeaveWorkingGroupUseCase {}
class MockWatchAuthStateUseCase extends Mock implements WatchAuthStateUseCase {}
class MockSyncWorkingGroupUseCase extends Mock implements SyncWorkingGroupUseCase {}

void main() {
  late GroupDetailsBloc bloc;
  late MockGetWorkingGroupUseCase mockGetWorkingGroupUseCase;
  late MockGetGroupTasksUseCase mockGetGroupTasksUseCase;
  late MockGetGroupParticipantsUseCase mockGetGroupParticipantsUseCase;
  late MockAddGroupTaskUseCase mockAddGroupTaskUseCase;
  late MockUpdateWorkingGroupUseCase mockUpdateWorkingGroupUseCase;
  late MockDeleteWorkingGroupUseCase mockDeleteWorkingGroupUseCase;
  late MockInviteGroupParticipantUseCase mockInviteGroupParticipantUseCase;
  late MockLeaveWorkingGroupUseCase mockLeaveWorkingGroupUseCase;
  late MockWatchAuthStateUseCase mockWatchAuthStateUseCase;
  late MockSyncWorkingGroupUseCase mockSyncWorkingGroupUseCase;

  const groupId = 'group-1';

  setUp(() {
    mockGetWorkingGroupUseCase = MockGetWorkingGroupUseCase();
    mockGetGroupTasksUseCase = MockGetGroupTasksUseCase();
    mockGetGroupParticipantsUseCase = MockGetGroupParticipantsUseCase();
    mockAddGroupTaskUseCase = MockAddGroupTaskUseCase();
    mockUpdateWorkingGroupUseCase = MockUpdateWorkingGroupUseCase();
    mockDeleteWorkingGroupUseCase = MockDeleteWorkingGroupUseCase();
    mockInviteGroupParticipantUseCase = MockInviteGroupParticipantUseCase();
    mockLeaveWorkingGroupUseCase = MockLeaveWorkingGroupUseCase();
    mockWatchAuthStateUseCase = MockWatchAuthStateUseCase();
    mockSyncWorkingGroupUseCase = MockSyncWorkingGroupUseCase();

    bloc = GroupDetailsBloc(
      groupId: groupId,
      getWorkingGroupUseCase: mockGetWorkingGroupUseCase,
      getGroupTasksUseCase: mockGetGroupTasksUseCase,
      getGroupParticipantsUseCase: mockGetGroupParticipantsUseCase,
      addGroupTaskUseCase: mockAddGroupTaskUseCase,
      updateWorkingGroupUseCase: mockUpdateWorkingGroupUseCase,
      deleteWorkingGroupUseCase: mockDeleteWorkingGroupUseCase,
      inviteGroupParticipantUseCase: mockInviteGroupParticipantUseCase,
      leaveWorkingGroupUseCase: mockLeaveWorkingGroupUseCase,
      watchAuthStateUseCase: mockWatchAuthStateUseCase,
      syncWorkingGroupUseCase: mockSyncWorkingGroupUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('GroupDetailsBloc - GroupDetailsRefreshed', () {
    blocTest<GroupDetailsBloc, GroupDetailsState>(
      'should call syncWorkingGroupUseCase and complete the completer',
      build: () {
        when(() => mockSyncWorkingGroupUseCase(groupId)).thenAnswer((_) async => {});
        return bloc;
      },
      act: (bloc) async {
        final completer = Completer<void>();
        bloc.add(GroupDetailsRefreshed(completer: completer));
        await completer.future;
      },
      verify: (_) {
        verify(() => mockSyncWorkingGroupUseCase(groupId)).called(1);
      },
    );
  });
}
