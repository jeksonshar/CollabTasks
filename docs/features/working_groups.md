# Feature: Working Groups

- **Goal:** Provide isolated group task collaboration with local Drift storage, remote Firebase/AWS sync, realtime updates, and explicit task
  assignment.
- **UseCases:** GetWorkingGroupsUseCase, GetWorkingGroupUseCase, GetGroupTasksUseCase, ClaimGroupTaskUseCase, ReleaseGroupTaskUseCase,
  CreateWorkingGroupUseCase, UpdateWorkingGroupUseCase, DeleteWorkingGroupUseCase, LeaveWorkingGroupUseCase,
  InviteGroupParticipantUseCase, AddGroupTaskUseCase, UpdateGroupTaskUseCase.
- **State:** WorkingGroupsBloc loads group list; GroupDetailsBloc combines group/participant/task streams, filters tasks by
  all/available/mine, and handles group edit/delete/invite actions; GroupTaskDetailsBloc handles claim/release/update actions.
- **API Endpoints:** Firebase uses `workingGroups/{groupId}/participants` and `workingGroups/{groupId}/tasks` snapshots. AWS uses Amplify GraphQL
  queries/mutations/subscriptions from `AwsWorkingGroupsGraphqlDocuments`.
- **Invites:** Email invites add normalized emails to group visibility metadata (`participantEmails`) and create a pending participant entry for
  local display. Backends must expose matching user-email visibility for invited users to see the group after sign-in.
- **Leave validation:** LeaveWorkingGroupUseCase checks active, non-completed assigned group tasks for the current user through
  WorkingGroupsRepository before calling `leaveGroup`. If such tasks exist, it throws `HasActiveTasksFailure`; GroupDetailsBloc maps it to
  `leaveRejectedWithActiveTasks`, and the UI shows a localized SnackBar.
