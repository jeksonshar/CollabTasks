import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/core/notifications/chat_notification_service.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/domain/models/user_status_entity.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_bloc.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_state.dart';
import 'package:collab_tasks/features/chats/ui/screens/chat_screen.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class _FakeChatEvent extends Fake implements ChatEvent {}

class _MockChatNotificationService extends Mock implements ChatNotificationService {}

void main() {
  late _MockChatBloc chatBloc;
  late _MockChatNotificationService notificationService;

  setUpAll(() {
    registerFallbackValue(_FakeChatEvent());
  });

  setUp(() async {
    await getIt.reset();
    chatBloc = _MockChatBloc();
    notificationService = _MockChatNotificationService();
    when(() => chatBloc.add(any())).thenReturn(null);
    when(() => chatBloc.close()).thenAnswer((_) async {});
    when(() => notificationService.activeChatId).thenReturn(null);
    when(() => notificationService.activeChatId = any()).thenReturn(null);

    getIt
      ..registerFactory<ChatBloc>(() => chatBloc)
      ..registerSingleton<ChatNotificationService>(notificationService);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('keeps chat actions accessible in compact and expanded app bars', (tester) async {
    tester.view.physicalSize = const Size(118, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const state = ChatLoaded(
      messages: [],
      opponentEmail: 'person@example.com',
      currentUserId: 'current@example.com',
      opponentStatus: UserStatusEntity(
        userId: 'person@example.com',
        status: UserStatus.offline,
        lastSeenMillis: 1790000000000,
      ),
    );
    whenListen(chatBloc, const Stream<ChatState>.empty(), initialState: state);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChatScreen(chatId: 'chat-1'),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(280, 800);
    await tester.pumpAndSettle();

    final localization = AppLocalizations.of(tester.element(find.byType(ChatScreen)))!;
    final subtitle = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data?.startsWith('was online') ?? false),
      ),
    );
    expect(subtitle.maxLines, 1);
    expect(subtitle.overflow, TextOverflow.ellipsis);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.videocam), findsNothing);
    expect(find.byIcon(Icons.phone), findsNothing);
    expect(find.byIcon(Icons.history), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(localization.group_details_participantVideoCall), findsOneWidget);
    expect(find.text(localization.group_details_participantAudioCall), findsOneWidget);
    expect(find.text(localization.callHistoryTitle), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tapAt(const Offset(10, 700));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();

    for (final icon in [Icons.videocam, Icons.phone, Icons.history]) {
      final action = tester.getRect(find.byIcon(icon));
      expect(action.right, lessThanOrEqualTo(tester.view.physicalSize.width));
    }
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
