import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/task_sort_direction.dart';
import '../../../../core/enums/task_sort_type.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blocs/task_bloc/task_bloc.dart';
import '../../../blocs/task_bloc/task_event.dart';
import '../../../blocs/task_bloc/task_state.dart';

class TasksAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TasksAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(localization.my_tasks),
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      actions: [
        // Используем BlocBuilder для изоляции перерисовок
        BlocBuilder<TaskBloc, TaskState>(
          buildWhen: (previous, current) =>
              previous.sortType != current.sortType ||
              previous.sortDirection != current.sortDirection,
          builder: (context, state) {
            return _SortMenu(
              sortType: state.sortType,
              sortDirection: state.sortDirection,
              localization: localization,
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SortMenu extends StatelessWidget {
  final TaskSortType sortType;
  final TaskSortDirection sortDirection;
  final AppLocalizations localization;

  const _SortMenu({
    required this.sortType,
    required this.sortDirection,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<TaskSortType>(
        icon: const Icon(Icons.sort),
        initialValue: sortType,
        onSelected: (type) {
          // Вызываем ивент через контекст
          context.read<TaskBloc>().add(SortChanged(type));
        },
        itemBuilder: (context) => TaskSortType.values.map((type) {
          final isSelected = sortType == type;
          return PopupMenuItem(
            value: type,
            child: Row(
              children: [
                Expanded(child: Text(type.label(localization))),
                const SizedBox(width: 12),
                Icon(isSelected ? sortDirection.icon : Icons.arrow_downward, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
