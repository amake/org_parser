typedef LocalVariables = List<({String key, String value})>;

LocalVariables? parseLocalVariables(String str) {
  final headerIdx = str.indexOf('Local Variables:');
  if (headerIdx == -1) return null;

  final startIdx = str.lastIndexOf('\n', headerIdx) + 1;
  final prefix = str.substring(startIdx, headerIdx);

  final endIdx =
      str.indexOf(RegExp('\n\r?${RegExp.escape(prefix)}End:'), startIdx);
  if (endIdx == -1) return null;

  final block = str.substring(startIdx, endIdx);

  if (!block.split(RegExp('\n\r?')).every((line) => line.startsWith(prefix))) {
    return null;
  }

  final unwrapped = block
      // Remove prefix from all lines
      .replaceAllMapped(RegExp('(\n\r?)${RegExp.escape(prefix)}'), (m) => m[1]!)
      // Unsplit lines manually broken by escaping the line break
      .replaceAll(RegExp(r'(?<!\\)(?:\\\\)*\\\n\r?'), '');

  final entries = unwrapped.split(RegExp('\n\r?'));

  if (!entries.every((e) => e.contains(':'))) {
    throw Exception('invalid local variables block');
  }

  return entries.skip(1).fold<LocalVariables>([], (acc, entry) {
    final e = entry.trim();
    final delimiterIdx = e.indexOf(':');
    final key = e.substring(0, delimiterIdx).trim();
    final value = e.substring(delimiterIdx + 1).trim();
    return acc..add((key: key, value: value));
  });
}
