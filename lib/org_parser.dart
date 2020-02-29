library org_parser;

import 'package:org_parser/src/org.dart';
import 'package:org_parser/src/parser.dart';

export 'src/grammar.dart';
export 'src/org.dart';
export 'src/parser.dart';

class OrgDocument {
  factory OrgDocument(String text) {
    final parser = OrgParser();
    final result = parser.parse(text);
    final topContent = result.value[0] as OrgContent;
    final sections = result.value[1] as List;
    return OrgDocument._(topContent, List.unmodifiable(sections));
  }

  OrgDocument._(this.topContent, this.sections);

  final OrgContent topContent;
  final List<OrgSection> sections;
}
