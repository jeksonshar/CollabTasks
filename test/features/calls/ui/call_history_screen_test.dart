import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_state.dart';
import 'package:collab_tasks/features/calls/ui/screens/call_history_screen.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCallHistoryBloc extends MockBloc<CallHistoryEvent, CallHistoryState>
    implements CallHistoryBloc {}

class _FakeCallHistoryEvent extends Fake implements CallHistoryEvent {}

void main() {
  const currentUserId = 'current-user';
  const groupId = 'group-1';
  const opponentId = 'peer-user';
  late _MockCallHistoryBloc callHistoryBloc;

  setUpAll(() {
    registerFallbackValue(_FakeCallHistoryEvent());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await getIt.reset();
    final preferences = await SharedPreferences.getInstance();
    setupLocator(preferences);

    callHistoryBloc = _MockCallHistoryBloc();
    when(() => callHistoryBloc.add(any())).thenReturn(null);
    when(() => callHistoryBloc.close()).thenAnswer((_) async {});
    getIt
      ..unregister<CallHistoryBloc>()
      ..registerFactory<CallHistoryBloc>(() => callHistoryBloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestableScreen(CallHistoryState state) {
    whenListen(callHistoryBloc, const Stream<CallHistoryState>.empty(), initialState: state);

    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CallHistoryScreen(
        title: 'History',
        currentUserId: currentUserId,
        groupId: groupId,
        opponentId: opponentId,
      ),
    );
  }

  CallHistoryLoaded loadedState(
    List<Call> calls, {
    CallHistoryCursor? nextCursor,
    Object? pageError,
    bool isLoadingMore = false,
  }) => CallHistoryLoaded(
    calls: calls,
    currentUserId: currentUserId,
    groupId: groupId,
    opponentId: opponentId,
    pageSize: CallHistoryBloc.pageSize,
    nextCursor: nextCursor,
    pageError: pageError,
    isLoadingMore: isLoadingMore,
  );

  testWidgets('shows retry on load error and reloads the same history request', (tester) async {
    await tester.pumpWidget(buildTestableScreen(CallHistoryError(StateError('offline'))));

    expect(find.text('Could not load call history'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    final events = verify(() => callHistoryBloc.add(captureAny())).captured;
    expect(events, hasLength(2));
    expect(
      events,
      everyElement(
        const LoadCallHistory(
          currentUserId: currentUserId,
          groupId: groupId,
          opponentId: opponentId,
        ),
      ),
    );
  });

  testWidgets('renders missed-call icon with the theme error color', (tester) async {
    final missedCall = Call(
      id: 'missed-call',
      callerId: opponentId,
      callerName: 'Peer',
      calleeIds: const [currentUserId],
      type: CallType.audio,
      status: CallStatus.missed,
      createdAt: DateTime(2026, 11, 17, 10),
    );

    await tester.pumpWidget(buildTestableScreen(loadedState([missedCall])));

    final icon = tester.widget<Icon>(find.byIcon(Icons.phone_missed));
    final screenContext = tester.element(find.byType(Scaffold));
    expect(icon.color, Theme.of(screenContext).colorScheme.error);
    expect(find.text('Missed audio call'), findsOneWidget);
  });

  testWidgets('renders the empty state', (tester) async {
    await tester.pumpWidget(buildTestableScreen(loadedState([])));
    expect(find.text('No calls yet'), findsOneWidget);
  });

  testWidgets('renders a call-history row', (tester) async {
    final answeredCall = Call(
      id: 'answered-call',
      callerId: opponentId,
      callerName: 'Peer',
      calleeIds: const [currentUserId],
      type: CallType.video,
      status: CallStatus.ended,
      createdAt: DateTime(2026, 11, 17, 10),
      startedAt: DateTime(2026, 11, 17, 10, 1),
      endedAt: DateTime(2026, 11, 17, 10, 3),
    );
    await tester.pumpWidget(buildTestableScreen(loadedState([answeredCall])));

    expect(find.text('Incoming video call'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.byIcon(Icons.call_received), findsOneWidget);
  });

  testWidgets('requests another page as the call list approaches its end', (tester) async {
    final calls = List.generate(
      CallHistoryBloc.pageSize,
      (index) => Call(
        id: 'call-$index',
        callerId: opponentId,
        callerName: 'Peer',
        calleeIds: const [currentUserId],
        type: CallType.audio,
        status: CallStatus.ended,
        createdAt: DateTime(2026, 11, 17, 10).add(Duration(minutes: index)),
        startedAt: DateTime(2026, 11, 17, 10).add(Duration(minutes: index, seconds: 10)),
        endedAt: DateTime(2026, 11, 17, 10).add(Duration(minutes: index, seconds: 50)),
      ),
    );
    await tester.pumpWidget(
      buildTestableScreen(
        loadedState(
          calls,
          nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'older-call'),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();

    final events = verify(() => callHistoryBloc.add(captureAny())).captured;
    expect(events.whereType<LoadMoreCallHistory>(), isNotEmpty);
  });

  testWidgets('requests another page when the first page does not fill the viewport', (
    tester,
  ) async {
    final singleCall = Call(
      id: 'short-page-call',
      callerId: opponentId,
      callerName: 'Peer',
      calleeIds: const [currentUserId],
      type: CallType.audio,
      status: CallStatus.ended,
      createdAt: DateTime(2026, 11, 17, 10),
    );
    await tester.pumpWidget(
      buildTestableScreen(
        loadedState([
          singleCall,
        ], nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'older-call')),
      ),
    );
    await tester.pump();

    final events = verify(() => callHistoryBloc.add(captureAny())).captured;
    expect(events.whereType<LoadMoreCallHistory>(), isNotEmpty);
  });

  testWidgets('allows retry after a later-page error', (tester) async {
    final call = Call(
      id: 'page-error-call',
      callerId: opponentId,
      callerName: 'Peer',
      calleeIds: const [currentUserId],
      type: CallType.audio,
      status: CallStatus.ended,
      createdAt: DateTime(2026, 11, 17, 10),
    );
    await tester.pumpWidget(
      buildTestableScreen(
        loadedState(
          [call],
          nextCursor: const CallHistoryCursor(createdAtMillis: 1000, callId: 'older-call'),
          pageError: StateError('offline'),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    final events = verify(() => callHistoryBloc.add(captureAny())).captured;
    expect(events.whereType<LoadMoreCallHistory>(), hasLength(1));
  });
}
