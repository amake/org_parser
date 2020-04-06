library org_parser;

import 'package:org_parser/src/org.dart';
import 'package:org_parser/src/parser.dart';

export 'src/grammar.dart';
export 'src/org.dart';
export 'src/parser.dart';

class OrgDocument extends OrgTree {
  factory OrgDocument(String text) {
    final parser = OrgParser();
    final result = parser.parse(text);
    final topContent = result.value[0] as OrgContent;
    final sections = result.value[1] as List;
    return OrgDocument._(topContent, List.unmodifiable(sections));
  }

  OrgDocument._(OrgContent content, Iterable<OrgSection> sections)
      : super(content, sections);

  @override
  int get level => 0;
}
