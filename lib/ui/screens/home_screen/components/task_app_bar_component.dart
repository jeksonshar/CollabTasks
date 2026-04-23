import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/task_sort_direction.dart';
import '../../../../core/enums/task_sort_type.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blocs/task_bloc/task_bloc.dart';
import '../../../blocs/task_bloc/task_event.dart';
import '../../../blocs/task_bloc/task_state.dart';

class TasksAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TasksAppBar({super.key});

  @override
  State<TasksAppBar> createState() => _TasksAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TasksAppBarState extends State<TasksAppBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<TaskBloc>().add(const SearchChanged(''));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: localization.titlePlaceholder,
                border: InputBorder.none,
              ),
              onChanged: (value) {
                context.read<TaskBloc>().add(SearchChanged(value));
              },
            )
          : Text(localization.my_tasks),
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      actions: [
        IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: _toggleSearch),
        BlocBuilder<TaskBloc, TaskState>(
          buildWhen: (previous, current) => previous.filterType != current.filterType,
          builder: (context, state) {
            return _FilterMenu(filterType: state.filterType, localization: localization);
          },
        ),
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
}

class _FilterMenu extends StatelessWidget {
  final TaskFilterType filterType;
  final AppLocalizations localization;

  const _FilterMenu({required this.filterType, required this.localization});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskFilterType>(
      icon: Icon(
        filterType != TaskFilterType.all ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
        // color: filterType != TaskFilterType.all ? Theme.of(context).colorScheme.primary : null,
        color: filterType != TaskFilterType.all ? Colors.indigo : null,
      ),
      initialValue: filterType,
      onSelected: (type) {
        context.read<TaskBloc>().add(FilterChanged(type));
      },
      itemBuilder: (context) => TaskFilterType.values.map((type) {
        final isSelected = filterType == type;
        return PopupMenuItem(
          value: type,
          child: Row(
            children: [
              Expanded(child: Text(type.label(localization))),
              if (isSelected) const Icon(Icons.check, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }
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
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<TaskSortType>(
        icon: const Icon(Icons.sort),
        initialValue: sortType,
        onSelected: (type) {
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
