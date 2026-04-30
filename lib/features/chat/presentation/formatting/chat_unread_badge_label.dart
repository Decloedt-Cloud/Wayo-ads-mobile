/// Display string for chat unread badges (inbox list, conversation chrome).
///
/// Shows [1–9] literally, then [9+] for any count greater than 9.
String formatChatUnreadBadgeLabel(int count) {
  if (count <= 0) {
    return '0';
  }
  return count > 9 ? '9+' : '$count';
}
