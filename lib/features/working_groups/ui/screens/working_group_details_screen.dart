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

          // Обработка состояний загрузки/ошибки на уровне всего экрана
          if (state.status == GroupDetailsStatus.loading ||
              state.status == GroupDetailsStatus.saving) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (state.status == GroupDetailsStatus.error && state.group == null) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.group.title)),
              body: Center(child: Text(state.errorMessage ?? 'Ошибка загрузки группы')),
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
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: _GroupAction.edit, child: Text('Редактировать группу')),
                      PopupMenuItem(
                        value: _GroupAction.invite,
                        child: Text('Пригласить участника'),
                      ),
                      PopupMenuItem(value: _GroupAction.leave, child: Text('Покинуть группу')),
                      PopupMenuItem(value: _GroupAction.delete, child: Text('Удалить группу')),
                    ],
                  ),
              ],
            ),
            body: activeTab == 0
                ? _ParticipantsTab(state: state, isParticipant: isParticipant)
                : _TasksTab(state: state),
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
                    items: const [
                      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Участники'),
                      BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Задачи'),
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
    final bloc = context.read<GroupDetailsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Покинуть группу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(const WorkingGroupLeft());
    }
  }

  Future<void> _confirmDeleteGroup(BuildContext context) async {
    final bloc = context.read<GroupDetailsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить группу?'),
        content: const Text('Группа, участники и задачи будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(const WorkingGroupDeleted());
    }
  }
}

// По-хорошему следующие виджеты табов (_ParticipantsTab, _TasksTab) тоже стоит вынести
// в отдельные файлы, если они продолжат расти, но пока оставлю здесь, очистив от внутреннего мусора.

class _ParticipantsTab extends StatelessWidget {
  const _ParticipantsTab({required this.state, required this.isParticipant});

  final GroupDetailsState state;
  final bool isParticipant;

  @override
  Widget build(BuildContext context) {
    final participants = state.displayParticipants;
    if (participants.isEmpty) {
      return const Center(child: Text('Участники еще не синхронизированы'));
    }

    return CustomScrollView(
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
                  'Участники',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.indigo.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final participant = participants[index];
            return ListTile(
              leading: _ParticipantAvatar(participant: participant),
              title: Text(participant.name),
              subtitle: state.isCurrentUser(participant) ? const Text('Вы') : null,
            );
          }, childCount: participants.length),
        ),
      ],
    );
  }
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
  const _TasksTab({required this.state});

  final GroupDetailsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SegmentedButton<GroupTaskFilter>(
            segments: const [
              ButtonSegment(value: GroupTaskFilter.all, label: Text('Все')),
              ButtonSegment(value: GroupTaskFilter.available, label: Text('Доступные')),
              ButtonSegment(value: GroupTaskFilter.mine, label: Text('Мои')),
            ],
            selected: {state.filter},
            onSelectionChanged: (selected) {
              context.read<GroupDetailsBloc>().add(GroupTaskFilterChanged(selected.first));
            },
          ),
        ),
        Expanded(
          child: state.visibleTasks.isEmpty
              ? const Center(child: Text('Задач нет'))
              : ListView.builder(
                  itemCount: state.visibleTasks.length,
                  itemBuilder: (context, index) {
                    final task = state.visibleTasks[index];
                    final assignee = state.participantById(task.assignedUserId);
                    return _GroupTaskTile(
                      task: task,
                      assignee: assignee,
                      currentUserId: state.currentUserId,
                      participants: state.participants,
                    );
                  },
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: assignee == null
            ? const CircleAvatar(child: Icon(Icons.lock_open))
            : _ParticipantAvatar(participant: assignee!),
        title: Text(task.title),
        subtitle: Text(assignee == null ? 'Свободно' : 'В работе у ${assignee!.name}'),
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
