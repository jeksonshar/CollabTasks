import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/models/has_active_tasks_failure.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/leave_working_group_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkingGroupsRepository extends Mock implements WorkingGroupsRepository {}

class MockWatchAuthStateUseCase extends Mock implements WatchAuthStateUseCase {}

void main() {
  late MockWorkingGroupsRepository repository;
  late MockWatchAuthStateUseCase watchAuthStateUseCase;
  late LeaveWorkingGroupUseCase useCase;

  const user = AuthUser(id: 'user-1', email: 'user@example.com', isEmailVerified: true);

  setUp(() {
    repository = MockWorkingGroupsRepository();
    watchAuthStateUseCase = MockWatchAuthStateUseCase();
    useCase = LeaveWorkingGroupUseCase(repository, watchAuthStateUseCase);

    when(() => watchAuthStateUseCase()).thenAnswer((_) => Stream.value(user));
  });

  test('throws HasActiveTasksFailure when current user has active assigned tasks', () async {
    when(
      () => repository.hasActiveAssignedTasks(
        groupId: 'group-1',
        userId: user.id,
        userEmail: user.email,
      ),
    ).thenAnswer((_) async => true);

    await expectLater(useCase('group-1'), throwsA(isA<HasActiveTasksFailure>()));

    verifyNever(() => repository.leaveGroup(any()));
  });

  test('leaves group when current user has no active assigned tasks', () async {
    when(
      () => repository.hasActiveAssignedTasks(
        groupId: 'group-1',
        userId: user.id,
        userEmail: user.email,
      ),
    ).thenAnswer((_) async => false);
    when(() => repository.leaveGroup('group-1')).thenAnswer((_) async {});

    await useCase('group-1');

    verify(() => repository.leaveGroup('group-1')).called(1);
  });
}
