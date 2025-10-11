import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('fixed-width area', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.fixedWidthArea()).end();
    test('multiline', () {
      final markup = ''': foo
: bar
''';
      var result = parser.parse(markup);
      var area = result.value as OrgFixedWidthArea;
      expect(area.contains('foo'), isTrue);
      expect(area.contains('あ'), isFalse);
      expect(area.toMarkup(), markup);
      expect(area.toPlainText(), markup);
    });
    test('empty', () {
      final markup = ': ';
      final result = parser.parse(markup);
      final area = result.value as OrgFixedWidthArea;
      expect(area.contains(':'), isTrue);
      expect(area.contains('あ'), isFalse);
      expect(area.toMarkup(), markup);
      expect(area.toPlainText(), markup);
    });
  });
}
