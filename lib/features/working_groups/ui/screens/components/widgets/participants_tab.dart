import 'package:collab_tasks/core/text/text_utils.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_state.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'participant_avatar.dart';

enum ParticipantAction { directChat, audioCall, videoCall }

class ParticipantsTab extends StatelessWidget {
  const ParticipantsTab({
    super.key,
    required this.state,
    required this.isParticipant,
    required this.onRefresh,
    required this.onDirectChatTap,
    this.onAudioCallTap,
    this.onVideoCallTap,
  });

  final GroupDetailsState state;
  final bool isParticipant;
  final RefreshCallback onRefresh;
  final ValueChanged<String> onDirectChatTap;
  final ValueChanged<String>? onAudioCallTap;
  final ValueChanged<String>? onVideoCallTap;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final participants = _filterInvitedParticipants(state.displayParticipants);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (!isParticipant)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.only(left: 24, right: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localization.group_details_titleWhenNoPartisipant,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.indigo.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          if (participants.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(localization.group_details_emptyParticipantsTitle)),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final participant = participants[index];
                final isMe = state.isCurrentUser(participant);

                return ListTile(
                  leading: ParticipantAvatar(participant: participant),
                  title: Text(participant.name),
                  subtitle: isMe ? Text(localization.group_details_ifParticipantYou) : null,
                  // Передаем id наверх при тапе:
                  onTap: isMe ? null : () => onDirectChatTap(participant.id),
                  trailing: isMe
                      ? null
                      : PopupMenuButton<ParticipantAction>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (action) {
                            switch (action) {
                              case ParticipantAction.directChat:
                                onDirectChatTap(participant.id);
                              case ParticipantAction.audioCall:
                                onAudioCallTap?.call(participant.id);
                              case ParticipantAction.videoCall:
                                onVideoCallTap?.call(participant.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: ParticipantAction.directChat,
                              child: Text(localization.group_details_participantOpenDirectChat),
                            ),
                            PopupMenuItem(
                              value: ParticipantAction.audioCall,
                              child: Text(localization.group_details_participantAudioCall),
                            ),
                            PopupMenuItem(
                              value: ParticipantAction.videoCall,
                              child: Text(localization.group_details_participantVideoCall),
                            ),
                          ],
                        ),
                );
              }, childCount: participants.length),
            ),
        ],
      ),
    );
  }
}

List<GroupParticipant> _filterInvitedParticipants(List<GroupParticipant> participants) {
  final Map<String, GroupParticipant> uniqueParticipants = {};

  for (final participant in participants) {
    // В качестве ключа берем userId (или name, если email сохранен там)
    final key = participant.id.substringAfterLast(':');
    final existing = uniqueParticipants[key];

    if (existing == null) {
      // Если такого пользователя еще нет в карте, просто добавляем его
      uniqueParticipants[key] = participant;
    } else {
      // Если пользователь уже есть, проверяем: у кого из них id содержит 'invite:'
      // перезаписываем элемент только если текущий имеет приоритетный 'invite:'
      // а у уже сохраненного его нет.
      // if (participant.id.contains('invite:') && !existing.id.contains('invite:')) {
      uniqueParticipants[key] = participant;
      // }
    }
  }

  return uniqueParticipants.values.toList();
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => oldDelegate.child != child;
}
