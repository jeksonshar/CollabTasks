import 'package:collab_tasks/features/working_groups/domain/models/group_task_filter.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_state.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/widgets/group_task_tile.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key, required this.state, required this.onRefresh});

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
                      return GroupTaskTile(
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
