import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_state.dart';
import 'package:collab_tasks/features/working_groups/ui/dialogs/create_group_dialog.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/working_group_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkingGroupsScreen extends StatelessWidget {
  const WorkingGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WorkingGroupsBloc>()..add(const WorkingGroupsStarted()),
      child: const _WorkingGroupsView(),
    );
  }
}

class _WorkingGroupsView extends StatelessWidget {
  const _WorkingGroupsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рабочие группы'), centerTitle: false),
      body: BlocBuilder<WorkingGroupsBloc, WorkingGroupsState>(
        builder: (context, state) {
          return switch (state.status) {
            WorkingGroupsStatus.loading => const Center(child: CircularProgressIndicator()),
            WorkingGroupsStatus.error => Center(
              child: Text(state.errorMessage ?? 'Ошибка загрузки групп'),
            ),
            WorkingGroupsStatus.loaded =>
              state.groups.isEmpty
                  ? const _EmptyGroups()
                  : ListView.builder(
                      itemCount: state.groups.length,
                      itemBuilder: (context, index) =>
                          _WorkingGroupTile(group: state.groups[index]),
                    ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final bloc = context.read<WorkingGroupsBloc>();

    final result = await showDialog<CreateGroupResult>(
      context: context,
      builder: (_) => const CreateGroupDialog(),
    );

    // Защита: проверяем, что данные получены, и что пользователь не закрыл экран во время ввода
    if (result != null && context.mounted) {
      bloc.add(WorkingGroupCreated(title: result.title, description: result.description));
    }
  }
}

class _WorkingGroupTile extends StatelessWidget {
  const _WorkingGroupTile({required this.group});

  final WorkingGroup group;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: _GroupAvatar(source: group.avatarSource),
        title: Text(group.title),
        subtitle: group.description.isEmpty ? null : Text(group.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Заменить на декларативный роутинг согласно AGENTS.md, когда будет настроишь GoRouter
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => WorkingGroupDetailsScreen(group: group)));
        },
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.source});

  final GroupAvatarSource source;

  @override
  Widget build(BuildContext context) {
    return switch (source) {
      NetworkAvatar(:final url) => CircleAvatar(backgroundImage: NetworkImage(url)),
      MemoryAvatar(:final bytes) => CircleAvatar(backgroundImage: MemoryImage(bytes)),
      DefaultAvatar() => const CircleAvatar(child: Icon(Icons.groups)),
    };
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Рабочих групп пока нет',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Создайте группу, чтобы вести совместные задачи.'),
        ],
      ),
    );
  }
}
