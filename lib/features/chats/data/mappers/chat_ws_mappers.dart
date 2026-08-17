import 'package:collab_tasks/features/chats/data/remote/models/ws_typing_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/ws_user_status_dto.dart';
import 'package:collab_tasks/features/chats/domain/models/typing_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/user_status_entity.dart';

/// Маппер: [WsUserStatusDto] (слой данных) → [UserStatusEntity] (доменный слой).
UserStatusEntity wsUserStatusDtoToEntity(WsUserStatusDto dto) {
  return UserStatusEntity(
    userId: dto.userId,
    status: dto.status == WsUserStatus.online ? UserStatus.online : UserStatus.offline,
    lastSeenMillis: dto.lastSeenMillis,
  );
}

/// Маппер: [WsTypingDto] (слой данных) → [TypingStatusEntity] (доменный слой).
TypingStatusEntity wsTypingDtoToEntity(WsTypingDto dto) {
  return TypingStatusEntity(chatId: dto.chatId, userId: dto.userId, isTyping: dto.isTyping);
}
