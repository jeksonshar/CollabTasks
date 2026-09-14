import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_state.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/widgets/participants_tab.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ru'), Locale('uk')],
    home: Scaffold(body: child),
  );
}

void main() {
  const currentUserId = 'user-me';
  const otherUserId = 'user-other';

  const meParticipant = GroupParticipant(
    id: 'group-1:user-me',
    groupId: 'group-1',
    userId: currentUserId,
    name: 'Current User',
    updatedAt: 1000,
  );

  const otherParticipant = GroupParticipant(
    id: 'group-1:user-other',
    groupId: 'group-1',
    userId: otherUserId,
    name: 'Other User',
    updatedAt: 1000,
  );

  testWidgets('shows popup menu only for other participants and not for current user', (
    tester,
  ) async {
    const state = GroupDetailsState(
      status: GroupDetailsStatus.loaded,
      currentUserId: currentUserId,
      participants: [meParticipant, otherParticipant],
    );

    await tester.pumpWidget(
      buildTestApp(
        ParticipantsTab(
          state: state,
          isParticipant: true,
          onRefresh: () async {},
          onDirectChatTap: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current User'), findsOneWidget);
    expect(find.text('Other User'), findsOneWidget);

    // Only 1 PopupMenuButton for otherParticipant, none for meParticipant
    expect(find.byType(PopupMenuButton<ParticipantAction>), findsOneWidget);
  });

  testWidgets('tapping tile directly invokes onParticipantTap for other participant', (
    tester,
  ) async {
    String? tappedParticipantId;
    const state = GroupDetailsState(
      status: GroupDetailsStatus.loaded,
      currentUserId: currentUserId,
      participants: [otherParticipant],
    );

    await tester.pumpWidget(
      buildTestApp(
        ParticipantsTab(
          state: state,
          isParticipant: true,
          onRefresh: () async {},
          onDirectChatTap: (id) => tappedParticipantId = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other User'));
    await tester.pumpAndSettle();

    expect(tappedParticipantId, otherParticipant.id);
  });

  testWidgets('popup menu provides direct chat, audio call and video call actions', (tester) async {
    String? directChatParticipantId;
    String? audioCallParticipantId;
    String? videoCallParticipantId;

    const state = GroupDetailsState(
      status: GroupDetailsStatus.loaded,
      currentUserId: currentUserId,
      participants: [otherParticipant],
    );

    await tester.pumpWidget(
      buildTestApp(
        ParticipantsTab(
          state: state,
          isParticipant: true,
          onRefresh: () async {},
          onDirectChatTap: (id) => directChatParticipantId = id,
          onAudioCallTap: (id) => audioCallParticipantId = id,
          onVideoCallTap: (id) => videoCallParticipantId = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Test Open direct chat
    await tester.tap(find.byType(PopupMenuButton<ParticipantAction>));
    await tester.pumpAndSettle();

    expect(find.text('Open direct chat'), findsOneWidget);
    expect(find.text('Audio call'), findsOneWidget);
    expect(find.text('Video call'), findsOneWidget);

    await tester.tap(find.text('Open direct chat'));
    await tester.pumpAndSettle();
    expect(directChatParticipantId, otherParticipant.id);

    // 2. Test Audio call
    await tester.tap(find.byType(PopupMenuButton<ParticipantAction>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Audio call'));
    await tester.pumpAndSettle();
    expect(audioCallParticipantId, otherParticipant.id);

    // 3. Test Video call
    await tester.tap(find.byType(PopupMenuButton<ParticipantAction>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Video call'));
    await tester.pumpAndSettle();
    expect(videoCallParticipantId, otherParticipant.id);
  });
}
