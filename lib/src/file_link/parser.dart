import 'package:org_parser/src/file_link/grammar.dart';
import 'package:org_parser/src/file_link/model.dart';
import 'package:petitparser/petitparser.dart';

/// File link parser
final orgFileLink = OrgFileLinkParserDefinition().build();

/// File link parser definition
class OrgFileLinkParserDefinition extends OrgFileLinkGrammarDefinition {
  @override
  Parser start() => super.start().map((values) {
        final scheme = values[0] as String;
        final body = values[1] as String;
        final extra = values[2] as String?;
        return OrgFileLink(
          scheme.isEmpty ? null : scheme,
          body,
          extra,
        );
      });
}
