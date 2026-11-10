import 'dart:async';

import 'package:collab_tasks/features/tasks/data/widgets/task_widget_bridge.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_event.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/task_bloc/task_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Keeps the Android widget cache in sync and routes widget taps into TaskBloc.
class TaskWidgetBlocListener extends StatefulWidget {
  const TaskWidgetBlocListener({required this.child, super.key});

  final Widget child;

  @override
  State<TaskWidgetBlocListener> createState() => _TaskWidgetBlocListenerState();
}

class _TaskWidgetBlocListenerState extends State<TaskWidgetBlocListener> {
  StreamSubscription<WidgetNavigationRequest>? _navigationSubscription;

  @override
  void initState() {
    super.initState();
    _navigationSubscription = TaskWidgetBridge.navigationRequests.listen(_handleNavigation);
    unawaited(TaskWidgetBridge.updateTasks(context.read<TaskBloc>().state.tasks));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final navigation = await TaskWidgetBridge.takeInitialNavigation();
        if (mounted && navigation != null) _handleNavigation(navigation);
      } on PlatformException {
        // Keep the app usable if native widget startup data is unavailable.
      }
    });
  }

  void _handleNavigation(WidgetNavigationRequest navigation) {
    if (!mounted) return;
    if (navigation.openHome) {
      context.read<TaskBloc>().add(const WidgetHomeOpened());
    } else if (navigation.refreshTasks) {
      context.read<TaskBloc>().add(const TasksRefreshRequested());
    } else if (navigation.taskId != null) {
      context.read<TaskBloc>().add(NotificationTaskOpened(navigation.taskId!));
    }
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listenWhen: (previous, current) => previous.tasks != current.tasks,
      listener: (_, state) => unawaited(TaskWidgetBridge.updateTasks(state.tasks)),
      child: widget.child,
    );
  }
}
