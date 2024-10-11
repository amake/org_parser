import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('footnote', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.footnote()).end();
    test('simple', () {
      final result = parser.parse('[fn:1] foo *bar* biz baz');
      final footnote = result.value as OrgFootnote;
      expect(footnote.marker.isDefinition, isTrue);
      expect(footnote.marker.name, '1');
      final firstText = footnote.content.children[0] as OrgPlainText;
      expect(firstText.content, ' foo ');
    });
    test('invalid indent', () {
      final result = parser.parse(' [fn:2] bazinga');
      expect(result, isA<Failure>(), reason: 'Indent not allowed');
    });
  });
}
