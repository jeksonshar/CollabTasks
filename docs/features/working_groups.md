# Feature: Working Groups

- **Goal:** Provide isolated group task collaboration with local Drift storage, remote Firebase/AWS sync, realtime updates, and explicit task
  assignment.
- **UseCases:** GetWorkingGroupsUseCase, GetGroupTasksUseCase, ClaimGroupTaskUseCase, ReleaseGroupTaskUseCase, CreateWorkingGroupUseCase,
  AddGroupTaskUseCase, UpdateGroupTaskUseCase.
- **State:** WorkingGroupsBloc loads group list; GroupDetailsBloc combines participant/task streams and filters tasks by all/available/mine;
  GroupTaskDetailsBloc handles claim/release/update actions.
- **API Endpoints:** Firebase uses `workingGroups/{groupId}/participants` and `workingGroups/{groupId}/tasks` snapshots. AWS uses Amplify GraphQL
  queries/mutations/subscriptions from `AwsWorkingGroupsGraphqlDocuments`.
