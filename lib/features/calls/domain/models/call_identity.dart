/// Normalizes a call identity without changing case-sensitive Firebase UIDs.
///
/// Email addresses are compared case-insensitively; other identifiers, including
/// Firebase UIDs, retain their original case.
String normalizeCallIdentity(String identity) {
  final trimmed = identity.trim();
  return trimmed.contains('@') ? trimmed.toLowerCase() : trimmed;
}
