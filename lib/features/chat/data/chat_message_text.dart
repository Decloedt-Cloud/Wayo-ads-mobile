/// Strips WhatsApp-style `>` quote lines — same contract as cinematic bubble [_parseReplyQuote].
({String quote, String body}) splitReplyQuotes(String raw) {
  final t = raw.trim();
  if (!t.startsWith('>')) {
    return (quote: '', body: t);
  }
  final lines = raw.split('\n');
  final quoteLines = <String>[];
  var i = 0;
  while (i < lines.length && lines[i].startsWith('>')) {
    quoteLines.add(lines[i].replaceFirst(RegExp(r'^>\s?'), ''));
    i++;
  }
  while (i < lines.length && lines[i].trim().isEmpty) {
    i++;
  }
  final body = lines.sublist(i).join('\n').trim();
  final quote = quoteLines.join('\n').trim();
  if (quote.isEmpty) {
    return (quote: '', body: t);
  }
  return (quote: quote, body: body);
}

/// Plain text suitable for clipboard / forwarded text payloads (captions included).
String plainBodyFromChatContent(String rawContent) =>
    splitReplyQuotes(rawContent).body.trim();
