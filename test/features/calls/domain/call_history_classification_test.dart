import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final callCreatedAt = DateTime.fromMillisecondsSinceEpoch(1000);
  final callStartedAt = DateTime.fromMillisecondsSinceEpoch(5000);
  final callEndedAt = DateTime.fromMillisecondsSinceEpoch(65000);

  Call makeCall({
    bool isGroup = false,
    CallStatus status = CallStatus.ended,
    DateTime? startedAt,
    DateTime? endedAt,
    bool hasEndedAt = true,
    List<CallParticipant> participants = const [],
  }) {
    return Call(
      id: 'call-1',
      callerId: 'caller@example.com',
      callerName: 'Caller',
      calleeIds: const ['callee@example.com'],
      type: CallType.audio,
      status: status,
      isGroup: isGroup,
      groupId: isGroup ? 'group-1' : null,
      participants: participants,
      createdAt: callCreatedAt,
      startedAt: startedAt,
      endedAt: hasEndedAt ? (endedAt ?? callEndedAt) : null,
    );
  }

  CallParticipant callee({
    CallParticipantStatus status = CallParticipantStatus.ringing,
    DateTime? joinedAt,
  }) => CallParticipant(
    userId: 'callee@example.com',
    displayName: 'Callee',
    status: status,
    joinedAt: joinedAt,
  );

  group('Call history classification', () {
    test('direct incoming decline and unanswered terminal calls are both missed', () {
      for (final status in [CallStatus.rejected, CallStatus.cancelled, CallStatus.ended]) {
        final call = makeCall(status: status);

        expect(call.isMissedFor('callee@example.com'), isTrue, reason: status.name);
      }
    });

    test('direct incoming call with a connected session is not missed', () {
      final call = makeCall(startedAt: callStartedAt, status: CallStatus.ended);

      expect(call.isMissedFor('callee@example.com'), isFalse);
    });

    test('direct outgoing call is not labeled missed for the caller', () {
      final call = makeCall(
        status: CallStatus.cancelled,
        endedAt: callEndedAt,
      ).copyWith(callerId: 'callee@example.com');

      expect(call.isMissedFor('callee@example.com'), isFalse);
    });

    test('group invitee without a join is missed even after another participant joined', () {
      final call = makeCall(
        isGroup: true,
        status: CallStatus.ended,
        startedAt: callStartedAt,
        participants: [
          CallParticipant(
            userId: 'caller@example.com',
            displayName: 'Caller',
            role: CallParticipantRole.host,
            status: CallParticipantStatus.left,
            joinedAt: callCreatedAt,
          ),
          callee(),
          CallParticipant(
            userId: 'other@example.com',
            displayName: 'Other',
            status: CallParticipantStatus.left,
            joinedAt: callStartedAt,
          ),
        ],
      );

      expect(call.isMissedFor('callee@example.com'), isTrue);
      expect(call.isMissedFor('other@example.com'), isFalse);
    });

    test('group decline and no-answer states share the missed classification', () {
      for (final status in [
        CallParticipantStatus.ringing,
        CallParticipantStatus.declined,
        CallParticipantStatus.left,
      ]) {
        final call = makeCall(
          isGroup: true,
          status: CallStatus.ended,
          startedAt: callStartedAt,
          participants: [callee(status: status)],
        );

        expect(call.isMissedFor('callee@example.com'), isTrue, reason: status.name);
      }
    });

    test('non-terminal group call is not yet classified as missed', () {
      final call = makeCall(
        isGroup: true,
        status: CallStatus.active,
        startedAt: callStartedAt,
        hasEndedAt: false,
        participants: [callee()],
      );

      expect(call.isMissedFor('callee@example.com'), isFalse);
    });

    test('participant without a stored record is not inferred to have missed the call', () {
      final call = makeCall(isGroup: true, status: CallStatus.ended, startedAt: callStartedAt);

      expect(call.isMissedFor('new-group-member@example.com'), isFalse);
    });

    test('group duration is the full connected session, not waiting time', () {
      final call = makeCall(
        isGroup: true,
        startedAt: callStartedAt,
        endedAt: callEndedAt,
        participants: [callee()],
      );

      expect(call.duration, const Duration(seconds: 60));
    });
  });
}
