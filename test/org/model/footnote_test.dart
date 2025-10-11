import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('footnote', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.footnote()).end();
    test('simple', () {
      final markup = '[fn:1] foo *bar* biz baz';
      var result = parser.parse(markup);
      final footnote = result.value as OrgFootnote;
      expect(footnote.contains('foo'), isTrue);
      expect(footnote.contains('あ'), isFalse);
      expect(footnote.toMarkup(), markup);
      expect(footnote.toPlainText(), '[1] foo bar biz baz');
    });
  });
}
