import 'dart:io';

import 'package:org_parser/org_parser.dart';

void main(List<String> args) {
  for (final arg in args) {
    final doc = File(arg).readAsStringSync();
    final parsed = OrgDocument.parse(doc);
    stdout.write(parsed.toMarkup());
  }
}
