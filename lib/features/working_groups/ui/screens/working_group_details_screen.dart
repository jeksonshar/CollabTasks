import 'dart:async';

import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/ui/screens/chat_screen.dart';
import 'package:collab_tasks/features/chats/ui/screens/group_chat_screen.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
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
      // BLoC создаётся через DI-фабрику — getIt вызывается здесь единственный раз,
      // в create-колбэке, который выполняется вне build-дерева и не нарушает
      // принцип «нет бизнес-логики в UI»: это чистая сборка зависимостей.
      create: (_) =>
          getIt<GroupDetailsBloc>(param1: widget.group.id)..add(const GroupDetailsStarted()),
      child: BlocConsumer<GroupDetailsBloc, GroupDetailsState>(
        listener: _onStateChanged,
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.pendingDirectChat != current.pendingDirectChat ||
            previous.isConnectingToChat != current.isConnectingToChat,
        builder: _buildContent,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Listener
  // ---------------------------------------------------------------------------

  Future<void> _onStateChanged(BuildContext context, GroupDetailsState state) async {
    // Навигация: вернуться назад после удаления или выхода из группы
    if (state.status == GroupDetailsStatus.deleted || state.status == GroupDetailsStatus.left) {
      Navigator.of(context).pop();
      return;
    }

    // Уведомление: нельзя выйти, есть активные задачи
    if (state.status == GroupDetailsStatus.leaveRejectedWithActiveTasks) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.group_details_leaveRejectedWithActiveTasks),
          ),
        );
      return;
    }

    // Уведомление: общая ошибка
    if (state.status == GroupDetailsStatus.error && state.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      return;
    }

    // Навигация: открыть личный чат с участником
    final pending = state.pendingDirectChat;
    if (pending != null) {
      // Сбрасываем флаг ДО навигации, чтобы повторная перестройка не открыла чат снова
      context.read<GroupDetailsBloc>().add(const GroupDirectChatConsumed());
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(chatId: pending.chatId, opponentName: pending.opponentName),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Builder
  // ---------------------------------------------------------------------------

  Widget _buildContent(BuildContext context, GroupDetailsState state) {
    final isParticipant = state.isCurrentUserParticipant;
    final group = state.group ?? widget.group;
    final activeTab = isParticipant ? _tabIndex : 0;
    final localization = AppLocalizations.of(context)!;

    if (state.status == GroupDetailsStatus.loading || state.status == GroupDetailsStatus.saving) {
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
      body: Stack(
        children: [
          IndexedStack(
            index: activeTab,
            children: [
              ParticipantsTab(
                state: state,
                isParticipant: isParticipant,
                onRefresh: () => _handleRefresh(context),
                // Вся бизнес-логика (getOrCreate чат + getParticipant) делегирована BLoC
                onParticipantTap: (participantId) {
                  context.read<GroupDetailsBloc>().add(
                    GroupParticipantChatOpened(
                      groupId: group.id,
                      participantCompositeId: participantId,
                    ),
                  );
                },
              ),
              TasksTab(state: state, onRefresh: () => _handleRefresh(context)),
            ],
          ),
          if (state.isConnectingToChat) _buildConnectingOverlay(context, localization),
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
  }

  /// Полноэкранный оверлей-лоадер, отображаемый во время холодного старта
  /// WebSocket-сервера (Render free tier может запускаться до 60 секунд).
  Widget _buildConnectingOverlay(BuildContext context, AppLocalizations localization) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black45,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    localization.chat_connectingToServer,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
