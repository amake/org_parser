import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('table', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.table()).end();
    test('simple', () {
      final markup = '''  | foo | *bar* | baz |
  |-----+-----+-----|
  |   1 |   2 |   3 |
''';
      final result = parser.parse(markup);
      final table = result.value as OrgTable;
      expect(table.contains('foo'), isTrue);
      expect(table.contains('bar'), isTrue);
      expect(table.contains('*bar*'), false);
      expect(table.toMarkup(), markup);
    });
    test('empty', () {
      final markup = '||';
      final result = parser.parse(markup);
      final table = result.value as OrgTable;
      expect(table.toMarkup(), markup);
    });
  });
}
