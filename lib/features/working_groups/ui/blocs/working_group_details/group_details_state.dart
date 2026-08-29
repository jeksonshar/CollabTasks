import 'package:collab_tasks/features/chats/domain/models/direct_chat_result.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task_filter.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

enum GroupDetailsStatus {
  loading,
  loaded,
  saving,
  deleted,
  left,
  leaveRejectedWithActiveTasks,
  error,
}

class GroupDetailsState extends Equatable {
  const GroupDetailsState({
    this.status = GroupDetailsStatus.loading,
    this.participants = const [],
    this.tasks = const [],
    this.filter = GroupTaskFilter.all,
    this.currentUserId,
    this.currentUserEmail,
    this.group,
    this.errorMessage,
    this.pendingDirectChat,
    this.isConnectingToChat = false,
  });

  final GroupDetailsStatus status;
  final List<GroupParticipant> participants;
  final List<GroupTask> tasks;
  final GroupTaskFilter filter;
  final String? currentUserId;
  final String? currentUserEmail;
  final WorkingGroup? group;
  final String? errorMessage;

  /// Данные для навигации к личному чату.
  /// Сбрасывается в `null` сразу после того, как UI прочитал его.
  final DirectChatResult? pendingDirectChat;

  /// `true` пока идёт подключение/создание прямого чата (холодный старт WS).
  final bool isConnectingToChat;

  bool get isCurrentUserParticipant {
    final userId = currentUserId;
    final email = currentUserEmail?.trim().toLowerCase();
    if ((userId == null || userId.isEmpty) && (email == null || email.isEmpty)) {
      return false;
    }
    return participants.any(isCurrentUser);
  }

  List<GroupParticipant> get displayParticipants {
    final userId = currentUserId;
    final email = currentUserEmail?.trim().toLowerCase();
    final hasCurrentUserParticipant =
        userId != null &&
        userId.isNotEmpty &&
        participants.any((participant) => participant.userId == userId);

    if (!hasCurrentUserParticipant || email == null || email.isEmpty) {
      return participants;
    }

    return participants
        .where((participant) => participant.userId.trim().toLowerCase() != email)
        .toList(growable: false);
  }

  List<GroupTask> get visibleTasks {
    return switch (filter) {
      GroupTaskFilter.all => tasks,
      GroupTaskFilter.available =>
        tasks
            .where((task) => task.assignedUserId == null || task.assignedUserId!.isEmpty)
            .toList(growable: false),
      GroupTaskFilter.mine =>
        tasks
            .where((task) {
              final participant = participantById(task.assignedUserId);
              return isCurrentUser(participant);
            })
            .toList(growable: false),
    };
  }

  bool isCurrentUser(GroupParticipant? participant) {
    if (participant == null) return false;
    final userId = currentUserId;
    final email = currentUserEmail?.trim().toLowerCase();
    final participantUserId = participant.userId.trim();
    return participantUserId == userId || participantUserId.toLowerCase() == email;
  }

  GroupParticipant? participantById(String? id) {
    if (id == null || id.isEmpty) return null;
    debugPrint('participantById() id: $id');
    for (int i = 0; i < participants.length; i++) {
      debugPrint('participant#$i: ${participants[i]}');
    }
    for (final participant in participants) {
      if (participant.userId == id || participant.id == id) return participant;
    }
    return null;
  }

  GroupDetailsState copyWith({
    GroupDetailsStatus? status,
    List<GroupParticipant>? participants,
    List<GroupTask>? tasks,
    GroupTaskFilter? filter,
    String? currentUserId,
    String? currentUserEmail,
    WorkingGroup? group,
    String? errorMessage,
    DirectChatResult? pendingDirectChat,
    bool clearPendingDirectChat = false,
    bool? isConnectingToChat,
  }) {
    return GroupDetailsState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserEmail: currentUserEmail ?? this.currentUserEmail,
      group: group ?? this.group,
      errorMessage: errorMessage,
      pendingDirectChat: clearPendingDirectChat
          ? null
          : (pendingDirectChat ?? this.pendingDirectChat),
      isConnectingToChat: isConnectingToChat ?? this.isConnectingToChat,
    );
  }

  @override
  List<Object?> get props => [
    status,
    participants,
    tasks,
    filter,
    currentUserId,
    currentUserEmail,
    group,
    errorMessage,
    isCurrentUserParticipant,
    pendingDirectChat,
    isConnectingToChat,
  ];
}
