import 'dart:convert';

import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task serialization', () {
    test('serializes DateTime fields as ISO strings and restores them from JSON', () {
      final createdAt = DateTime.utc(2026, 5, 30, 12, 34, 56);
      final deadline = DateTime.utc(2026, 5, 31, 9, 15);
      final task = Task(
        id: 'task-1',
        createdAt: createdAt,
        title: 'Serialized task',
        description: 'Description',
        deadline: deadline,
      );

      final map = task.toMap();

      expect(map['createdAt'], createdAt.toIso8601String());
      expect(map['deadline'], deadline.toIso8601String());
      expect(jsonEncode(map), isA<String>());

      final restored = Task.fromJson(jsonEncode(map));

      expect(restored.createdAt, createdAt);
      expect(restored.deadline, deadline);
    });
  });
}
