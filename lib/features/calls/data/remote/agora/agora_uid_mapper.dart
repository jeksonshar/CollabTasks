import 'dart:convert';

import 'package:collab_tasks/features/calls/domain/models/call_identity.dart';
import 'package:crypto/crypto.dart';

typedef AgoraUidDigest = int Function(String canonicalIdentity);

class AgoraUidCollisionException implements Exception {
  final String firstIdentity;
  final String secondIdentity;
  final int uid;

  const AgoraUidCollisionException({
    required this.firstIdentity,
    required this.secondIdentity,
    required this.uid,
  });

  @override
  String toString() =>
      'Agora UID collision: "$firstIdentity" and "$secondIdentity" both map to $uid';
}

/// Produces stable positive Agora UIDs and holds the mapping for one call.
///
/// IDs are derived from SHA-256 of a canonical call identity. Aliases are only
/// accepted when their relationship to a canonical identity is supplied by a
/// trusted caller (currently FirebaseAuth for the local user).
class AgoraUidMapper {
  static const int maxUid = 0x7FFFFFFF;

  final AgoraUidDigest _digest;
  final Map<String, int> _identityToUid = {};
  final Map<String, String> _identityToCanonical = {};
  final Map<int, String> _uidToCanonical = {};

  AgoraUidMapper({AgoraUidDigest? digest}) : _digest = digest ?? _sha256Uid;

  /// Converts a stable participant identity to a positive 31-bit UID.
  int toAgoraUid(String userId) {
    final identity = normalizeCallIdentity(userId);
    final mapped = _identityToUid[identity];
    if (mapped != null) return mapped;

    // RTC callbacks use this explicit fallback when an Agora UID has not yet
    // been resolved to a roster identity. Preserve the native UID directly.
    if (identity.startsWith('user_')) {
      final parsedUid = int.tryParse(identity.substring('user_'.length));
      if (parsedUid != null && parsedUid > 0 && parsedUid <= maxUid) {
        final existingCanonical = _uidToCanonical[parsedUid];
        if (existingCanonical != null && existingCanonical != identity) {
          throw AgoraUidCollisionException(
            firstIdentity: existingCanonical,
            secondIdentity: identity,
            uid: parsedUid,
          );
        }
        _identityToUid[identity] = parsedUid;
        _identityToCanonical[identity] = identity;
        _uidToCanonical[parsedUid] = identity;
        return parsedUid;
      }
    }

    final uid = _uidForCanonical(identity);
    final existingCanonical = _uidToCanonical[uid];
    if (existingCanonical != null && existingCanonical != identity) {
      throw AgoraUidCollisionException(
        firstIdentity: existingCanonical,
        secondIdentity: identity,
        uid: uid,
      );
    }
    return uid;
  }

  /// Creates and validates one call's mapping before any member joins Agora.
  ///
  /// [aliases] must contain only verified alias-to-canonical relationships.
  /// The canonical identity must also be present in [participantIds].
  Map<String, int> mapCallParticipants(
    Iterable<String> participantIds, {
    Map<String, String> aliases = const {},
  }) {
    final normalizedIds = participantIds.map(normalizeCallIdentity).toSet();
    if (normalizedIds.isEmpty) {
      throw ArgumentError.value(participantIds, 'participantIds', 'Call roster must not be empty');
    }

    final normalizedAliases = <String, String>{};
    for (final entry in aliases.entries) {
      final alias = normalizeCallIdentity(entry.key);
      final canonical = normalizeCallIdentity(entry.value);
      if (!normalizedIds.contains(canonical)) {
        throw ArgumentError.value(
          entry.value,
          'aliases',
          'Canonical identity must be present in the call roster',
        );
      }
      normalizedAliases[alias] = canonical;
    }

    String canonicalFor(String identity) => normalizedAliases[identity] ?? identity;

    final canonicalIds = normalizedIds.map(canonicalFor).toSet();
    final canonicalToUid = <String, int>{};
    final uidToCanonical = <int, String>{};
    for (final canonical in canonicalIds) {
      final uid = _uidForCanonical(canonical);
      final previous = uidToCanonical[uid];
      if (previous != null && previous != canonical) {
        throw AgoraUidCollisionException(
          firstIdentity: previous,
          secondIdentity: canonical,
          uid: uid,
        );
      }
      canonicalToUid[canonical] = uid;
      uidToCanonical[uid] = canonical;
    }

    final identityToUid = <String, int>{};
    final identityToCanonical = <String, String>{};
    for (final identity in normalizedIds) {
      final canonical = canonicalFor(identity);
      identityToUid[identity] = canonicalToUid[canonical]!;
      identityToCanonical[identity] = canonical;
    }
    for (final entry in normalizedAliases.entries) {
      final existingCanonical = identityToCanonical[entry.key];
      if (existingCanonical != null && existingCanonical != entry.value) {
        throw ArgumentError('Identity "${entry.key}" has conflicting canonical mappings');
      }
      identityToUid[entry.key] = canonicalToUid[entry.value]!;
      identityToCanonical[entry.key] = entry.value;
    }

    _identityToUid
      ..clear()
      ..addAll(identityToUid);
    _identityToCanonical
      ..clear()
      ..addAll(identityToCanonical);
    _uidToCanonical
      ..clear()
      ..addAll(uidToCanonical);

    return Map.unmodifiable(identityToUid);
  }

  /// Maps supplied session data back into this shared mapper and verifies it.
  void restoreCallMapping(Map<dynamic, dynamic> participants, Map<dynamic, dynamic> canonicalIds) {
    final aliases = <String, String>{};
    for (final entry in canonicalIds.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('Call participant identity mapping is malformed');
      }
      aliases[entry.key as String] = entry.value as String;
    }

    final participantIds = participants.keys.whereType<String>().toList();
    if (participantIds.length != participants.length) {
      throw const FormatException('Call participant UID mapping contains a non-string identity');
    }
    final expected = mapCallParticipants(participantIds, aliases: aliases);
    for (final entry in participants.entries) {
      final suppliedUid = entry.value;
      final expectedUid = expected[normalizeCallIdentity(entry.key as String)];
      if (suppliedUid is! num || suppliedUid.toInt() != expectedUid) {
        throw FormatException('Agora UID mapping for "${entry.key}" does not match the stable map');
      }
    }
  }

  /// Resolves an Agora UID to the canonical call participant identity.
  String? toUserId(int uid) => _uidToCanonical[uid];

  /// A snapshot suitable for carrying the verified mapping inside CallSession.
  Map<String, String> get canonicalIdsByIdentity => Map.unmodifiable(_identityToCanonical);

  /// Returns the canonical identity associated with [userId] in this call.
  String canonicalIdentity(String userId) {
    final normalized = normalizeCallIdentity(userId);
    return _identityToCanonical[normalized] ?? normalized;
  }

  /// Clears the in-memory reverse map for the current call.
  void clear() {
    _identityToUid.clear();
    _identityToCanonical.clear();
    _uidToCanonical.clear();
  }

  int _uidForCanonical(String identity) {
    final uid = _digest(identity);
    if (uid <= 0 || uid > maxUid) {
      throw RangeError.range(uid, 1, maxUid, 'uid', 'Digest must return a positive 31-bit UID');
    }
    return uid;
  }

  static int _sha256Uid(String identity) {
    final bytes = sha256.convert(utf8.encode(identity)).bytes;
    final first32Bits = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    final uid = first32Bits & maxUid;
    return uid == 0 ? 1 : uid;
  }
}
