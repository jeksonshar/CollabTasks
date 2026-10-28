import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.fromMillisecondsSinceEpoch(1000);
  final host = CallParticipant(
    userId: 'host@example.com',
    displayName: 'Host',
    role: CallParticipantRole.host,
    status: CallParticipantStatus.connected,
    joinedAt: createdAt,
  );
  const invitee = CallParticipant(
    userId: 'Invitee@example.com',
    displayName: 'Invitee',
    status: CallParticipantStatus.ringing,
  );

  test('serializes participants as a normalized user-keyed map', () {
    final call = Call(
      id: 'call-1',
      callerId: host.userId,
      callerName: host.displayName,
      calleeIds: [invitee.userId.toLowerCase()],
      type: CallType.audio,
      status: CallStatus.ringing,
      isGroup: true,
      participants: [host, invitee],
      createdAt: createdAt,
    );

    final data = call.toMap();

    expect(data['participants'], isNull);
    final keyedParticipants = data['participantsByUser'] as Map<String, dynamic>;
    expect(keyedParticipants.keys, containsAll(['host@example.com', 'invitee@example.com']));
    expect(keyedParticipants['invitee@example.com']['status'], 'ringing');
  });

  test('normalizes email identifiers without changing case-sensitive UIDs', () {
    final call = Call(
      id: 'call-uid',
      callerId: 'CaseSensitiveCallerUid',
      callerName: 'Host',
      calleeIds: const ['CASE@example.com', 'CaseSensitiveCalleeUid'],
      type: CallType.audio,
      status: CallStatus.ringing,
      participants: [
        host.copyWith(userId: 'CaseSensitiveCallerUid'),
        invitee.copyWith(userId: 'CASE@example.com'),
        invitee.copyWith(userId: 'CaseSensitiveCalleeUid'),
      ],
      createdAt: createdAt,
    );

    final data = call.toMap();
    final keyedParticipants = data['participantsByUser'] as Map<String, dynamic>;
    expect(data['callerId'], 'CaseSensitiveCallerUid');
    expect(data['calleeIds'], ['case@example.com', 'CaseSensitiveCalleeUid']);
    expect(
      keyedParticipants.keys,
      containsAll(['CaseSensitiveCallerUid', 'case@example.com', 'CaseSensitiveCalleeUid']),
    );
  });

  test('reads keyed participants and preserves legacy array reads', () {
    final call = Call(
      id: 'call-1',
      callerId: host.userId,
      callerName: host.displayName,
      calleeIds: [invitee.userId.toLowerCase()],
      type: CallType.audio,
      status: CallStatus.ringing,
      isGroup: true,
      participants: [host, invitee],
      createdAt: createdAt,
    );
    final keyed = call.toMap();

    final restored = Call.fromMap(keyed);
    expect(
      restored.participants.map((participant) => participant.userId),
      containsAll([host.userId, 'invitee@example.com']),
    );

    final legacy = Map<String, dynamic>.from(keyed)
      ..remove('participantsByUser')
      ..['participants'] = [host.toMap(), invitee.toMap()];
    expect(Call.fromMap(legacy).participants, containsAll([host, invitee]));
  });
}
