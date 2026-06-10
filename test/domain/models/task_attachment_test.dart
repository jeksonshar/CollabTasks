import 'dart:convert';
import 'dart:typed_data';

import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskAttachment', () {
    test('serializes web bytes as base64 and restores them', () {
      final attachment = TaskAttachment(
        id: 'file-1',
        name: 'notes.txt',
        extension: 'txt',
        sizeBytes: 3,
        bytes: Uint8List.fromList([65, 66, 67]),
      );

      final json = attachment.toJson();
      final restored = TaskAttachment.fromJson(json);

      expect(json['bytesBase64'], base64Encode([65, 66, 67]));
      expect(restored.id, 'file-1');
      expect(restored.name, 'notes.txt');
      expect(restored.extension, 'txt');
      expect(restored.sizeBytes, 3);
      expect(restored.bytes, [65, 66, 67]);
    });

    test('encodes and decodes attachment lists with local and remote metadata', () {
      const attachments = [
        TaskAttachment(
          id: 'local-file',
          name: 'local.txt',
          extension: 'txt',
          localPath: '/tmp/local.txt',
          sizeBytes: 12,
        ),
        TaskAttachment(
          id: 'remote-file',
          name: 'remote.pdf',
          extension: 'pdf',
          storageKey: 'users/user-1/tasks/task-1/files/remote.pdf',
          sizeBytes: 2048,
        ),
      ];

      final encoded = TaskAttachment.encodeList(attachments);
      final decoded = TaskAttachment.decodeList(encoded);

      expect(decoded, hasLength(2));
      expect(decoded.first.localPath, '/tmp/local.txt');
      expect(decoded.last.storageKey, 'users/user-1/tasks/task-1/files/remote.pdf');
      expect(decoded.last.isRemote, isTrue);
    });

    test('returns empty list for null or empty encoded attachment lists', () {
      expect(TaskAttachment.decodeList(null), isEmpty);
      expect(TaskAttachment.decodeList(''), isEmpty);
    });
  });
}
