import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/get_call_history_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetCallHistoryUseCase extends Mock implements GetCallHistoryUseCase {}

void main() {
  const currentUserId = 'current-user';
  const opponentId = 'peer-user';
  final createdAt = DateTime.fromMillisecondsSinceEpoch(1000);
  final pageFailure = StateError('page fetch failed');
  late _MockGetCallHistoryUseCase getCallHistory;

  Call call(String id, DateTime date) => Call(
    id: id,
    callerId: opponentId,
    callerName: 'Peer',
    calleeIds: const [currentUserId],
    type: CallType.audio,
    status: CallStatus.ended,
    createdAt: date,
  );

  setUp(() {
    getCallHistory = _MockGetCallHistoryUseCase();
  });

  blocTest<CallHistoryBloc, CallHistoryState>(
    'loads the first page and stores its query and continuation cursor',
    setUp: () {
      when(
        () => getCallHistory(
          currentUserId: currentUserId,
          pageSize: CallHistoryBloc.pageSize,
          groupId: null,
          opponentId: opponentId,
          cursor: null,
        ),
      ).thenAnswer(
        (_) async => CallHistoryPage(
          calls: [call('call-1', createdAt)],
          nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1'),
        ),
      );
    },
    build: () => CallHistoryBloc(getCallHistory),
    act: (bloc) =>
        bloc.add(const LoadCallHistory(currentUserId: currentUserId, opponentId: opponentId)),
    expect: () => [
      const CallHistoryLoading(),
      CallHistoryLoaded(
        calls: [call('call-1', createdAt)],
        currentUserId: currentUserId,
        opponentId: opponentId,
        pageSize: CallHistoryBloc.pageSize,
        nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1'),
      ),
    ],
  );

  blocTest<CallHistoryBloc, CallHistoryState>(
    'appends a later page and removes calls repeated across a page boundary',
    setUp: () {
      const cursor = CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1');
      when(
        () => getCallHistory(
          currentUserId: currentUserId,
          pageSize: CallHistoryBloc.pageSize,
          groupId: null,
          opponentId: opponentId,
          cursor: null,
        ),
      ).thenAnswer(
        (_) async => CallHistoryPage(calls: [call('call-1', createdAt)], nextCursor: cursor),
      );
      when(
        () => getCallHistory(
          currentUserId: currentUserId,
          pageSize: CallHistoryBloc.pageSize,
          groupId: null,
          opponentId: opponentId,
          cursor: cursor,
        ),
      ).thenAnswer(
        (_) async => CallHistoryPage(
          calls: [call('call-1', createdAt), call('call-2', DateTime(2026, 1, 1))],
        ),
      );
    },
    build: () => CallHistoryBloc(getCallHistory),
    act: (bloc) async {
      bloc.add(const LoadCallHistory(currentUserId: currentUserId, opponentId: opponentId));
      await bloc.stream.firstWhere((state) => state is CallHistoryLoaded);
      bloc.add(const LoadMoreCallHistory());
    },
    expect: () => [
      const CallHistoryLoading(),
      CallHistoryLoaded(
        calls: [call('call-1', createdAt)],
        currentUserId: currentUserId,
        opponentId: opponentId,
        pageSize: CallHistoryBloc.pageSize,
        nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1'),
      ),
      CallHistoryLoaded(
        calls: [call('call-1', createdAt)],
        currentUserId: currentUserId,
        opponentId: opponentId,
        pageSize: CallHistoryBloc.pageSize,
        nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1'),
        isLoadingMore: true,
      ),
      CallHistoryLoaded(
        calls: [call('call-1', createdAt), call('call-2', DateTime(2026, 1, 1))],
        currentUserId: currentUserId,
        opponentId: opponentId,
        pageSize: CallHistoryBloc.pageSize,
      ),
    ],
  );

  blocTest<CallHistoryBloc, CallHistoryState>(
    'keeps the loaded page and cursor when loading a later page fails',
    setUp: () {
      const cursor = CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1');
      when(
        () => getCallHistory(
          currentUserId: currentUserId,
          pageSize: CallHistoryBloc.pageSize,
          groupId: null,
          opponentId: opponentId,
          cursor: null,
        ),
      ).thenAnswer(
        (_) async => CallHistoryPage(calls: [call('call-1', createdAt)], nextCursor: cursor),
      );
      when(
        () => getCallHistory(
          currentUserId: currentUserId,
          pageSize: CallHistoryBloc.pageSize,
          groupId: null,
          opponentId: opponentId,
          cursor: cursor,
        ),
      ).thenAnswer((_) async => throw pageFailure);
    },
    build: () => CallHistoryBloc(getCallHistory),
    act: (bloc) async {
      bloc.add(const LoadCallHistory(currentUserId: currentUserId, opponentId: opponentId));
      await bloc.stream.firstWhere((state) => state is CallHistoryLoaded);
      bloc.add(const LoadMoreCallHistory());
    },
    expect: () => [
      const CallHistoryLoading(),
      CallHistoryLoaded(
        calls: [call('call-1', createdAt)],
        currentUserId: currentUserId,
        opponentId: opponentId,
        pageSize: CallHistoryBloc.pageSize,
        nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1'),
      ),
      CallHistoryLoaded(
        calls: [call('call-1', createdAt)],
        currentUserId: currentUserId,
        opponentId: opponentId,
        pageSize: CallHistoryBloc.pageSize,
        nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1'),
        isLoadingMore: true,
      ),
      CallHistoryLoaded(
        calls: [call('call-1', createdAt)],
        currentUserId: currentUserId,
        opponentId: opponentId,
        pageSize: CallHistoryBloc.pageSize,
        nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'call-1'),
        pageError: pageFailure,
      ),
    ],
  );
}
