import 'package:collab_tasks/features/calls/data/remote/agora/agora_uid_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AgoraUidMapper mapper;

  setUp(() {
    mapper = AgoraUidMapper();
  });

  group('AgoraUidMapper tests', () {
    test('converts string userId to positive 32-bit int and resolves back', () {
      final uid = mapper.toAgoraUid('user-alice-123');

      expect(uid, isPositive);
      expect(mapper.toUserId(uid), 'user-alice-123');
    });

    test('returns consistent uid for same string userId', () {
      final uid1 = mapper.toAgoraUid('user-bob-456');
      final uid2 = mapper.toAgoraUid('user-bob-456');

      expect(uid1, uid2);
    });

    test('manual registration maps userId and uid bidirectionally', () {
      mapper.register('user-carol-789', 9999);

      expect(mapper.toUserId(9999), 'user-carol-789');
      expect(mapper.toAgoraUid('user-carol-789'), 9999);
    });

    test('clear removes all mappings', () {
      final uid = mapper.toAgoraUid('user-david');
      expect(mapper.toUserId(uid), 'user-david');

      mapper.clear();

      expect(mapper.toUserId(uid), isNull);
    });
  });
}
