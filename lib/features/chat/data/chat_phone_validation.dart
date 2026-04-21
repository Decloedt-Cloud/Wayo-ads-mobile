/// Mirrors `containsPhoneNumber` in `AdvertiserChatDialog.tsx` (product rule).
bool chatTextLooksLikePhoneNumber(String value) {
  final v = value.trim();
  if (v.isEmpty) return false;
  final patterns = <RegExp>[
    RegExp(r'\+?\d{1,3}[\s\-.\(\)]*\d{2,3}[\s\-.\(\)]*\d{2,3}[\s\-.\(\)]*\d{2}[\s\-.\(\)]*\d{2}'),
    RegExp(r'0[1-9](?:[\s\-.\.]?\d{2}){4}'),
    RegExp(r'\(\d{3}\)\s*\d{3}[-\s]\d{4}'),
    RegExp(r'(?<!\d)\d{10,11}(?!\d)'),
    RegExp(r'\d(?:[\s\-.\.]?\d){9,10}'),
  ];
  return patterns.any((p) => p.hasMatch(v));
}
