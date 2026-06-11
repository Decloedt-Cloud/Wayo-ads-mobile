/// Apple Sign in with Apple — Hide My Email relay addresses.
bool isAppleHideMyEmailAddress(String email) {
  final normalized = email.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.endsWith('@privaterelay.appleid.com');
}
