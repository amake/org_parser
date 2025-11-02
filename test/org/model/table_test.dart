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
  |   1 | ~2~ |   3 |
  |   1 | +2+ | buz |
''';
      final result = parser.parse(markup);
      final table = result.value as OrgTable;
      expect(table.contains('foo'), isTrue);
      expect(table.contains('bar'), isTrue);
      expect(table.contains('*bar*'), isFalse);
      expect(table.toMarkup(), markup);
      expect(table.toPlainText(), '''  | foo | bar | baz |
  |-----+-----+-----|
  |   1 | 2 |   3 |
  |   1 | 2 | buz |
''');
      expect(table.columnCount, 3);
      expect(table.columnIsNumeric(0), isTrue);
      expect(table.columnIsNumeric(1), isTrue);
      expect(table.columnIsNumeric(2), isFalse);
      expect(() => table.columnIsNumeric(3), throwsRangeError);
    });
    test('empty', () {
      final markup = '||';
      final result = parser.parse(markup);
      final table = result.value as OrgTable;
      expect(table.toMarkup(), markup);
      expect(table.toPlainText(), markup);
      expect(table.columnCount, 1);
      expect(table.columnIsNumeric(0), isFalse);
      expect(() => table.columnIsNumeric(1), throwsRangeError);
    });
  });
}
