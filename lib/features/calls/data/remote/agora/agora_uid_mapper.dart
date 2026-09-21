class AgoraUidMapper {
  final Map<String, int> _userToUid = {};
  final Map<int, String> _uidToUser = {};

  /// Converts a String [userId] to a positive 32-bit integer Agora UID.
  int toAgoraUid(String userId) {
    final existing = _userToUid[userId];
    if (existing != null) return existing;

    // Use a positive 31-bit integer from hash code
    int uid = userId.hashCode & 0x7FFFFFFF;
    if (uid == 0) uid = 1;

    // Handle collision if any
    while (_uidToUser.containsKey(uid) && _uidToUser[uid] != userId) {
      uid = (uid + 1) & 0x7FFFFFFF;
      if (uid == 0) uid = 1;
    }

    _userToUid[userId] = uid;
    _uidToUser[uid] = userId;
    return uid;
  }

  /// Resolves an integer Agora UID back to the domain String [userId].
  String? toUserId(int uid) {
    return _uidToUser[uid];
  }

  /// Manually registers a known mapping between [userId] and [uid].
  void register(String userId, int uid) {
    _userToUid[userId] = uid;
    _uidToUser[uid] = userId;
  }

  /// Clears all stored mappings.
  void clear() {
    _userToUid.clear();
    _uidToUser.clear();
  }
}
