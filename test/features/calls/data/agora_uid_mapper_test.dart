import 'package:collab_tasks/features/calls/data/remote/agora/agora_uid_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgoraUidMapper', () {
    test('uses a fixed SHA-256-derived UID for a canonical email', () {
      final mapper = AgoraUidMapper();

      expect(mapper.toAgoraUid('alice@example.com'), 2139985945);
      expect(mapper.toAgoraUid(' ALICE@EXAMPLE.COM '), 2139985945);
    });

    test('returns the same UID from separate mapper instances', () {
      final firstMapper = AgoraUidMapper();
      final secondMapper = AgoraUidMapper();

      expect(firstMapper.toAgoraUid('AbC123'), 1971624412);
      expect(secondMapper.toAgoraUid('AbC123'), 1971624412);
    });

    test('preserves case-sensitive Firebase UID identity', () {
      final mapper = AgoraUidMapper();

      expect(mapper.toAgoraUid('AbC123'), isNot(mapper.toAgoraUid('abc123')));
    });

    test('preserves an explicit user_UID fallback from Agora callbacks', () {
      final mapper = AgoraUidMapper();

      expect(mapper.toAgoraUid('user_123456'), 123456);
      expect(mapper.toUserId(123456), 'user_123456');
    });

    test('uses verified email and UID aliases for one canonical roster member', () {
      final mapper = AgoraUidMapper();
      final participants = mapper.mapCallParticipants(
        ['caller@example.com', 'invitee@example.com'],
        aliases: {'FirebaseUidCaseSensitive': 'invitee@example.com'},
      );

      expect(participants['invitee@example.com'], participants['FirebaseUidCaseSensitive']);
      expect(mapper.toUserId(participants['FirebaseUidCaseSensitive']!), 'invitee@example.com');
    });

    test('throws instead of resolving a call roster collision by insertion order', () {
      final mapper = AgoraUidMapper(digest: (_) => 42);

      expect(
        () => mapper.mapCallParticipants(['participant-a', 'participant-b']),
        throwsA(
          isA<AgoraUidCollisionException>()
              .having((error) => error.uid, 'uid', 42)
              .having((error) => error.firstIdentity, 'firstIdentity', isNotEmpty)
              .having((error) => error.secondIdentity, 'secondIdentity', isNotEmpty),
        ),
      );
    });

    test('restores and verifies call mapping provided in a session', () {
      final source = AgoraUidMapper();
      final participantMap = source.mapCallParticipants(
        ['caller@example.com', 'member@example.com'],
        aliases: {'member-uid': 'member@example.com'},
      );
      final restored = AgoraUidMapper()
        ..restoreCallMapping(participantMap, source.canonicalIdsByIdentity);

      expect(restored.toAgoraUid('member-uid'), participantMap['member@example.com']);
      expect(restored.toUserId(participantMap['caller@example.com']!), 'caller@example.com');
    });

    test('rejects a session mapping whose UID differs from the stable mapping', () {
      final mapper = AgoraUidMapper();

      expect(
        () => mapper.restoreCallMapping(
          {'caller@example.com': 123},
          {'caller@example.com': 'caller@example.com'},
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('clears reverse mappings between calls', () {
      final mapper = AgoraUidMapper();
      final uid = mapper.mapCallParticipants(['david@example.com'])['david@example.com']!;

      expect(mapper.toUserId(uid), 'david@example.com');
      mapper.clear();
      expect(mapper.toUserId(uid), isNull);
    });
  });
}
