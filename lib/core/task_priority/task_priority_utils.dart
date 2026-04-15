import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum TaskPriority {
  none(0),
  low(1),
  medium(2),
  high(3);

  final int value;

  const TaskPriority(this.value);

  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere((e) => e.value == value, orElse: () => TaskPriority.none);
  }
}

extension TaskPriorityX on TaskPriority {
  String label(AppLocalizations localization) {
    return switch (this) {
      TaskPriority.none => localization.taskPriorityNone,
      TaskPriority.low => localization.taskPriorityLow,
      TaskPriority.medium => localization.taskPriorityMedium,
      TaskPriority.high => localization.taskPriorityHigh,
    };
  }

  Color? get borderColor {
    return switch (this) {
      TaskPriority.none => null,
      TaskPriority.low => Colors.green,
      TaskPriority.medium => Colors.amber,
      TaskPriority.high => Colors.red,
    };
  }

  Color? get fillColor {
    return switch (this) {
      TaskPriority.none => null,
      TaskPriority.low => const Color(0x332E7D32),
      TaskPriority.medium => const Color(0x33FFB300),
      TaskPriority.high => const Color(0x33C62828),
    };
  }
}
