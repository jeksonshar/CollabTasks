import 'dart:async';

import 'package:collab_tasks/core/text/text_utils.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';
import 'package:collab_tasks/features/chats/ui/screens/chat_screen.dart';
import 'package:collab_tasks/features/chats/ui/screens/group_chat_screen.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_state.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/confirmation_dialogs/confirm_delete_group.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/confirmation_dialogs/confirm_leave_group.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/show_dialogs/show_add_working_group_dialog.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/show_dialogs/show_edit_working_group_dialog.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/show_dialogs/show_invite_participant_to_group_dialog.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/widgets/participants_tab.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/widgets/tasks_tab.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _GroupAction { edit, invite, chat, leave, delete }

class WorkingGroupDetailsScreen extends StatefulWidget {
  const WorkingGroupDetailsScreen({super.key, required this.group});

  final WorkingGroup group;

  @override
  State<WorkingGroupDetailsScreen> createState() => _WorkingGroupDetailsScreenState();
}

class _WorkingGroupDetailsScreenState extends State<WorkingGroupDetailsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<GroupDetailsBloc>(param1: widget.group.id)..add(const GroupDetailsStarted()),
      child: BlocConsumer<GroupDetailsBloc, GroupDetailsState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == GroupDetailsStatus.deleted ||
              state.status == GroupDetailsStatus.left) {
            Navigator.of(context).pop();
          }
          if (state.status == GroupDetailsStatus.leaveRejectedWithActiveTasks) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.group_details_leaveRejectedWithActiveTasks,
                  ),
                ),
              );
          }
          if (state.status == GroupDetailsStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final isParticipant = state.isCurrentUserParticipant;
          final group = state.group ?? widget.group;
          final activeTab = isParticipant ? _tabIndex : 0;
          final localization = AppLocalizations.of(context)!;

          // Обработка состояний загрузки/ошибки на уровне всего экрана
          if (state.status == GroupDetailsStatus.loading ||
              state.status == GroupDetailsStatus.saving) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (state.status == GroupDetailsStatus.error && state.group == null) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.group.title)),
              body: Center(
                child: Text(state.errorMessage ?? localization.group_details_defaultErrorMessage),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(group.title),
                  if (group.description.trim().isNotEmpty)
                    Text(
                      group.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              centerTitle: false,
              actions: [
                if (isParticipant)
                  PopupMenuButton<_GroupAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) => _handleGroupAction(context, action, group),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _GroupAction.edit,
                        child: Text(localization.group_details_popupItemEditGroup),
                      ),
                      PopupMenuItem(
                        value: _GroupAction.invite,
                        child: Text(localization.group_details_popupItemInviteParticipant),
                      ),
                      PopupMenuItem(
                        value: _GroupAction.chat,
                        child: Text(localization.direct_chat_toolbarTitle),
                      ),
                      PopupMenuItem(
                        value: _GroupAction.leave,
                        child: Text(localization.group_details_popupItemLeaveGroup),
                      ),
                      PopupMenuItem(
                        value: _GroupAction.delete,
                        child: Text(localization.group_details_popupItemDeleteGroup),
                      ),
                    ],
                  ),
              ],
            ),
            body: IndexedStack(
              index: activeTab,
              children: [
                ParticipantsTab(
                  state: state,
                  isParticipant: isParticipant,
                  onRefresh: () => _handleRefresh(context),
                  onParticipantTap: (participantId) async {
                    final chatId = await getIt<ChatRepository>().getOrCreateDirectChat(
                      participantId.substringAfterLast(':'),
                    );
                    final opponent = await getIt<WorkingGroupsRepository>().getParticipantById(
                      group.id,
                      participantId,
                    );
                    if (context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatScreen(chatId: chatId, opponentName: opponent.name),
                        ),
                      );
                    }
                  },
                ),
                TasksTab(state: state, onRefresh: () => _handleRefresh(context)),
              ],
            ),
            floatingActionButton: (isParticipant && activeTab == 1)
                ? FloatingActionButton(
                    onPressed: () => showAddGroupDialog(context),
                    child: const Icon(Icons.add_task),
                  )
                : null,
            bottomNavigationBar: isParticipant
                ? BottomNavigationBar(
                    currentIndex: activeTab,
                    onTap: (index) => setState(() => _tabIndex = index),
                    selectedItemColor: Colors.indigo,
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.people),
                        label: localization.group_details_bottomNavItemParticipants,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.task_alt),
                        label: localization.group_details_bottomNavItemTasks,
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  Future<void> _openChatScreen(BuildContext context, String groupId, String? groupName) async {
    if (context.mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => GroupChatScreen(groupId: groupId)));
    }
  }

  Future<void> _handleGroupAction(
    BuildContext context,
    _GroupAction action,
    WorkingGroup group,
  ) async {
    switch (action) {
      case _GroupAction.edit:
        await showEditGroupDialog(context, group);
      case _GroupAction.invite:
        await showInviteDialog(context);
      case _GroupAction.chat:
        await _openChatScreen(context, group.id, group.title);
      case _GroupAction.leave:
        await confirmLeaveGroup(context);
      case _GroupAction.delete:
        await confirmDeleteGroup(context);
    }
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final completer = Completer<void>();
    context.read<GroupDetailsBloc>().add(GroupDetailsRefreshed(completer: completer));
    await completer.future;
  }
}
