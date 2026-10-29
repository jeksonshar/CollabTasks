import 'dart:async';

import 'package:collab_tasks/features/calls/data/repositories/in_memory_call_repository.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_active_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_incoming_calls_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/bloc_components/calls_firestore_watch_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

class _CallbackWatchActiveCallUseCase extends WatchActiveCallUseCase {
  _CallbackWatchActiveCallUseCase(this._watch) : super(InMemoryCallRepository());

  final Stream<Call?> Function(String callId) _watch;

  @override
  Stream<Call?> call(String callId) => _watch(callId);
}

class _CallbackWatchIncomingCallsUseCase extends WatchIncomingCallsUseCase {
  _CallbackWatchIncomingCallsUseCase(this._watch) : super(InMemoryCallRepository());

  final Stream<List<Call>> Function(String userId) _watch;

  @override
  Stream<List<Call>> call(String userId) => _watch(userId);
}

void main() {
  test('replacing active-call watch cancels the old subscription first', () async {
    var oldCancelCount = 0;
    var newListenCount = 0;
    final oldStream = StreamController<Call?>.broadcast(onCancel: () => oldCancelCount++);
    final newStream = StreamController<Call?>.broadcast(onListen: () => newListenCount++);
    final coordinator = CallsFirestoreWatchCoordinator(
      watchActiveCall: _CallbackWatchActiveCallUseCase(
        (callId) => callId == 'old-call' ? oldStream.stream : newStream.stream,
      ),
      watchIncomingCalls: _CallbackWatchIncomingCallsUseCase((_) => const Stream.empty()),
    );

    await coordinator.watchActiveCall(
      'old-call',
      canListen: () => true,
      onData: (_) {},
      onError: (_) {},
    );
    await coordinator.watchActiveCall(
      'new-call',
      canListen: () => true,
      onData: (_) {},
      onError: (_) {},
    );

    expect(oldCancelCount, 1);
    expect(newListenCount, 1);
    await coordinator.cancelActiveCall();
    await oldStream.close();
    await newStream.close();
  });

  test('stream errors are forwarded and later incoming snapshots still arrive', () async {
    final incomingCalls = StreamController<List<Call>>.broadcast();
    final coordinator = CallsFirestoreWatchCoordinator(
      watchActiveCall: _CallbackWatchActiveCallUseCase((_) => const Stream.empty()),
      watchIncomingCalls: _CallbackWatchIncomingCallsUseCase((_) => incomingCalls.stream),
    );
    final received = <List<Call>>[];
    final errors = <Object>[];
    coordinator.listenIncomingCalls(
      'callee@example.com',
      onData: received.add,
      onError: errors.add,
    );

    incomingCalls
      ..addError(StateError('temporary Firestore stream error'))
      ..add(const <Call>[]);
    await Future<void>.delayed(Duration.zero);

    expect(errors, hasLength(1));
    expect(received, hasLength(1));
    expect(received.single, isEmpty);
    await coordinator.closeIncomingCalls();
    await incomingCalls.close();
  });
}
