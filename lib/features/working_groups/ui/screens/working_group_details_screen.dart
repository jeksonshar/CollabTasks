import 'dart:async';

import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/tasks/ui/dialogs/task_dialog/task_dialog.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task_filter.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_state.dart';
import 'package:collab_tasks/features/working_groups/ui/dialogs/edit_group_dialog.dart';
import 'package:collab_tasks/features/working_groups/ui/dialogs/invite_participant_dialog.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/working_group_task_details_screen.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _GroupAction { edit, invite, leave, delete }

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
            body: activeTab == 0
                ? _ParticipantsTab(
                    state: state,
                    isParticipant: isParticipant,
                    onRefresh: () => _handleRefresh(context),
                  )
                : _TasksTab(state: state, onRefresh: () => _handleRefresh(context)),
            floatingActionButton: (isParticipant && activeTab == 1)
                ? FloatingActionButton(
                    onPressed: () => _showAddTaskDialog(context),
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

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final bloc = context.read<GroupDetailsBloc>();
    final draft = await showDialog(context: context, builder: (_) => const TaskDialog());
    if (draft != null && context.mounted) {
      bloc.add(GroupTaskAdded(draft));
    }
  }

  Future<void> _handleGroupAction(
    BuildContext context,
    _GroupAction action,
    WorkingGroup group,
  ) async {
    switch (action) {
      case _GroupAction.edit:
        await _showEditGroupDialog(context, group);
      case _GroupAction.invite:
        await _showInviteDialog(context);
      case _GroupAction.leave:
        await _confirmLeaveGroup(context);
      case _GroupAction.delete:
        await _confirmDeleteGroup(context);
    }
  }

  Future<void> _showEditGroupDialog(BuildContext context, WorkingGroup group) async {
    final bloc = context.read<GroupDetailsBloc>();
    final result = await showDialog<EditGroupResult>(
      context: context,
      builder: (_) => EditGroupDialog(group: group),
    );

    if (result != null && context.mounted) {
      bloc.add(
        WorkingGroupUpdated(
          group.copyWith(
            title: result.title,
            description: result.description,
            avatarUrl: result.avatarUrl,
          ),
        ),
      );
    }
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    final bloc = context.read<GroupDetailsBloc>();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => const InviteParticipantDialog(),
    );

    if (email != null && context.mounted) {
      bloc.add(GroupParticipantInvited(email));
    }
  }

  Future<void> _confirmLeaveGroup(BuildContext context) async {
    final localization = AppLocalizations.of(context)!;
    final bloc = context.read<GroupDetailsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localization.group_details_leaveGroupTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localization.group_details_cancelBtn),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localization.group_details_leaveGroupBtn),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(const WorkingGroupLeft());
    }
  }

  Future<void> _confirmDeleteGroup(BuildContext context) async {
    final localization = AppLocalizations.of(context)!;
    final bloc = context.read<GroupDetailsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localization.group_details_deleteGroupTitle),
        content: Text(localization.group_details_deleteGroupContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localization.group_details_cancelBtn),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localization.group_details_deleteGroupBtn),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(const WorkingGroupDeleted());
    }
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final completer = Completer<void>();
    context.read<GroupDetailsBloc>().add(GroupDetailsRefreshed(completer: completer));
    await completer.future;
  }
}

// По-хорошему следующие виджеты табов (_ParticipantsTab, _TasksTab) тоже стоит вынести
// в отдельные файлы, если они продолжат расти, но пока оставлю здесь, очистив от внутреннего мусора.

class _ParticipantsTab extends StatelessWidget {
  const _ParticipantsTab({
    required this.state,
    required this.isParticipant,
    required this.onRefresh,
  });

  final GroupDetailsState state;
  final bool isParticipant;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final participants = _filterInvitedParticipants(state.displayParticipants);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (!isParticipant)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.only(left: 24, right: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localization.group_details_titleWhenNoPartisipant,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.indigo.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          if (participants.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(localization.group_details_emptyParticipantsTitle)),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final participant = participants[index];
                return ListTile(
                  leading: _ParticipantAvatar(participant: participant),
                  title: Text(participant.name),
                  subtitle: state.isCurrentUser(participant)
                      ? Text(localization.group_details_ifParticipantYou)
                      : null,
                );
              }, childCount: participants.length),
            ),
        ],
      ),
    );
  }
}

List<GroupParticipant> _filterInvitedParticipants(List<GroupParticipant> participants) {
  final Map<String, GroupParticipant> uniqueParticipants = {};

  for (final participant in participants) {
    // В качестве ключа берем userId (или name, если email сохранен там)
    final key = participant.name;
    final existing = uniqueParticipants[key];

    if (existing == null) {
      // Если такого пользователя еще нет в карте, просто добавляем его
      uniqueParticipants[key] = participant;
    } else {
      // Если пользователь уже есть, проверяем: у кого из них id содержит 'invite:'
      // перезаписываем элемент только если текущий имеет приоритетный 'invite:'
      // а у уже сохраненного его нет.
      if (participant.id.contains('invite:') && !existing.id.contains('invite:')) {
        uniqueParticipants[key] = participant;
      }
    }
  }

  return uniqueParticipants.values.toList();
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => oldDelegate.child != child;
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.state, required this.onRefresh});

  final GroupDetailsState state;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SegmentedButton<GroupTaskFilter>(
            segments: [
              ButtonSegment(
                value: GroupTaskFilter.all,
                label: Text(localization.group_details_taskBtnSegmentAll),
              ),
              ButtonSegment(
                value: GroupTaskFilter.available,
                label: Text(localization.group_details_taskBtnSegmentAccessible),
              ),
              ButtonSegment(
                value: GroupTaskFilter.mine,
                label: Text(localization.group_details_taskBtnSegmentMy),
              ),
            ],
            selected: {state.filter},
            onSelectionChanged: (selected) {
              context.read<GroupDetailsBloc>().add(GroupTaskFilterChanged(selected.first));
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: state.visibleTasks.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text(localization.group_details_taskListEmptyTitle)),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.visibleTasks.length,
                    itemBuilder: (context, index) {
                      final task = state.visibleTasks[index];
                      final assignee = state.participantById(task.assignedUserId);
                      debugPrint('Get tasks assignee = $assignee');
                      return _GroupTaskTile(
                        task: task,
                        assignee: assignee,
                        currentUserId: state.currentUserId,
                        participants: state.participants,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _GroupTaskTile extends StatelessWidget {
  const _GroupTaskTile({
    required this.task,
    required this.assignee,
    required this.currentUserId,
    required this.participants,
  });

  final GroupTask task;
  final GroupParticipant? assignee;
  final String? currentUserId;
  final List<GroupParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: assignee == null
            ? const CircleAvatar(child: Icon(Icons.lock_open))
            : _ParticipantAvatar(participant: assignee!),
        title: Text(task.title),
        subtitle: Text(
          assignee == null
              ? localization.group_details_taskFree
              : localization.group_details_taskInWork(assignee!.name),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkingGroupTaskDetailsScreen(task: task, participants: participants),
            ),
          );
        },
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.participant});

  final GroupParticipant participant;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = participant.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(avatarUrl));
    }
    return CircleAvatar(child: Text(participant.initials));
  }
}
