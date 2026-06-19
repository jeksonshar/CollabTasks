import 'dart:convert';

import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_groups/working_groups_state.dart';
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
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final bloc = context.read<WorkingGroupsBloc>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новая рабочая группа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Название'),
              autofocus: true,
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    if (result == true && titleController.text.trim().isNotEmpty) {
      bloc.add(
        WorkingGroupCreated(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
        ),
      );
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
        leading: _GroupAvatar(avatarUrl: group.avatarUrl),
        title: Text(group.title),
        subtitle: group.description.isEmpty ? null : Text(group.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => WorkingGroupDetailsScreen(group: group)));
        },
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final value = avatarUrl;
    if (value != null && value.isNotEmpty) {
      if (value.startsWith('data:image/')) {
        final commaIndex = value.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(value.substring(commaIndex + 1));
          return CircleAvatar(backgroundImage: MemoryImage(bytes));
        }
      }
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return CircleAvatar(backgroundImage: NetworkImage(value));
      }
    }
    return const CircleAvatar(child: Icon(Icons.groups));
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
