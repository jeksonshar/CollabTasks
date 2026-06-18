import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/tasks/ui/dialogs/task_dialog/task_dialog.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task_filter.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_details/group_details_state.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/group_task_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(widget.group.title), centerTitle: false),
          body: BlocBuilder<GroupDetailsBloc, GroupDetailsState>(
            builder: (context, state) {
              if (state.status == GroupDetailsStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == GroupDetailsStatus.error) {
                return Center(child: Text(state.errorMessage ?? 'Ошибка загрузки группы'));
              }
              return _tabIndex == 0 ? _ParticipantsTab(state: state) : _TasksTab(state: state);
            },
          ),
          floatingActionButton: _tabIndex == 1
              ? FloatingActionButton(
                  onPressed: () => _showAddTaskDialog(context),
                  child: const Icon(Icons.add_task),
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tabIndex,
            onTap: (index) => setState(() => _tabIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Участники'),
              BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Задачи'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final bloc = context.read<GroupDetailsBloc>();
    final draft = await showDialog(context: context, builder: (_) => const TaskDialog());
    if (draft != null) {
      bloc.add(GroupTaskAdded(draft));
    }
  }
}

class _ParticipantsTab extends StatelessWidget {
  const _ParticipantsTab({required this.state});

  final GroupDetailsState state;

  @override
  Widget build(BuildContext context) {
    if (state.participants.isEmpty) {
      return const Center(child: Text('Участники еще не синхронизированы'));
    }
    return ListView.builder(
      itemCount: state.participants.length,
      itemBuilder: (context, index) {
        final participant = state.participants[index];
        return ListTile(
          leading: _ParticipantAvatar(participant: participant),
          title: Text(participant.name),
          subtitle: participant.userId == state.currentUserId ? const Text('Вы') : null,
        );
      },
    );
  }
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
              builder: (_) => GroupTaskDetailsScreen(
                task: task,
                assignee: assignee,
                currentUserId: currentUserId,
                participants: participants,
              ),
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
