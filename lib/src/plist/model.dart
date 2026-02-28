import 'package:org_parser/src/plist/parser.dart';

class Plist {
  factory Plist.from(String str) =>
      Plist(orgPlist.parse(str).value as List<String>);

  final List<String> tokens;

  Plist(Iterable<String> tokens) : tokens = List.unmodifiable(tokens);

  String? get(String key) {
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.toLowerCase() == key) {
        if (i + 1 < tokens.length) {
          return tokens[i + 1];
        }
      }
    }
    return null;
  }

  bool has(String key) {
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.toLowerCase() == key) {
        return true;
      }
    }
    return false;
  }
}
