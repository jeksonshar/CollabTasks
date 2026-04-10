import 'package:flutter/material.dart';

enum TaskSortDirection { topToBottom, bottomToTop }

extension TaskSortDirectionX on TaskSortDirection {
  bool get isAscending => this == TaskSortDirection.topToBottom;

  IconData get icon => switch (this) {
    TaskSortDirection.topToBottom => Icons.arrow_downward,
    TaskSortDirection.bottomToTop => Icons.arrow_upward,
  };
}
