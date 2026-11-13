# Feature: Working Groups

- **Goal:** Provide isolated group task collaboration with local Drift storage, remote Firebase/AWS sync, realtime
  updates, and explicit task
  assignment.
- **UseCases:** GetWorkingGroupsUseCase, GetWorkingGroupUseCase, GetGroupTasksUseCase, ClaimGroupTaskUseCase,
  ReleaseGroupTaskUseCase,
  CreateWorkingGroupUseCase, UpdateWorkingGroupUseCase, DeleteWorkingGroupUseCase, LeaveWorkingGroupUseCase,
  InviteGroupParticipantUseCase, AddGroupTaskUseCase, UpdateGroupTaskUseCase.
- **State:** WorkingGroupsBloc loads group list; GroupDetailsBloc combines group/participant/task streams, filters tasks
  by
  all/available/mine, and handles group edit/delete/invite actions; GroupTaskDetailsBloc handles claim/release/update
  actions.
- **API Endpoints:** Firebase uses `workingGroups/{groupId}/participants` and `workingGroups/{groupId}/tasks` snapshots.
  AWS uses Amplify GraphQL
  queries/mutations/subscriptions from `AwsWorkingGroupsGraphqlDocuments`.
- **Invites:** Email invites add normalized emails to group visibility metadata (`participantEmails`) and create a
  pending participant entry for
  local display. Backends must expose matching user-email visibility for invited users to see the group after sign-in.
- **Leave validation:** LeaveWorkingGroupUseCase checks active, non-completed assigned group tasks for the current user
  through
  WorkingGroupsRepository before calling `leaveGroup`. If such tasks exist, it throws `HasActiveTasksFailure`;
  GroupDetailsBloc maps it to
  `leaveRejectedWithActiveTasks`, and the UI shows a localized SnackBar.
- **Leave propagation:** Firebase `leaveGroup` atomically removes the user's UID/email aliases from the group's
  membership metadata and deletes
  their participant documents. The remote operation must succeed before local membership is removed; failures are
  returned to GroupDetailsBloc.
  Full remote participant snapshots reconcile Drift by deleting local rows absent from the snapshot, so other devices
  stop showing the departed
  member and group calls/messages no longer use that cached roster. Participant self-healing is deduplicated and
  suspended during Leave; Leave waits
  for an already-running self-heal before removing remote membership, preventing a late upsert from restoring the
  member. Legacy `participantIds`
  values are also removed because the group-message Cloud Function can use that field as its recipient list.
- **Group call roster:** Before an audio/video group call starts, GroupChatBloc refreshes the group and roster from
  Firebase. The WebSocket chat
  metadata uses the synchronized local participant roster as authoritative when available, replacing stale server-side
  participant emails rather
  than merging departed users back into the call recipient list.
- **Participant Actions:** Each participant item (except the current user) provides a popup menu
  (`PopupMenuButton<ParticipantAction>`) with the direct-chat action. Audio/video call actions are currently disabled in
  this menu; call initiation is handled from chat. Tapping the item directly continues to open direct chat.
- **Opening a participant chat:** `GroupDetailsBloc` owns the in-progress state so updates from its group streams cannot
  leave the loading overlay stale. Before sending `get_or_create_direct_chat`, the WebSocket data source polls the chat
  server's existing `/health` endpoint for up to two minutes; this wakes a sleeping Render service and sends the chat
  request only after the server is ready. The screen navigates when the Bloc emits `pendingDirectChat`, and clears the
  overlay on either success or error.

