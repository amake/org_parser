import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('table', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.table()).end();
    test('simple', () {
      final result = parser.parse('''  | foo | *bar* | baz |
  |-----+-----+-----|
  |   1 |   2 |   3 |
''');
      final table = result.value as OrgTable;
      final row0 = table.rows[0] as OrgTableCellRow;
      final row0Cell0 = row0.cells[0].content.children[0] as OrgPlainText;
      expect(row0Cell0.content, 'foo');
      final row0Cell1 = row0.cells[1].content.children[0] as OrgMarkup;
      final row0Cell1Content =
          row0Cell1.content.children.single as OrgPlainText;
      expect(row0Cell1Content.content, 'bar');
      expect(row0Cell1.leadingDecoration, '*');
      expect(row0Cell1.trailingDecoration, '*');
      expect(row0.cells.length, 3);
      expect(table.rows[1], isA<OrgTableDividerRow>());
      final row2 = table.rows[2] as OrgTableCellRow;
      expect(row2.cells.length, 3);
    });
    test('empty', () {
      final result = parser.parse('||');
      final table = result.value as OrgTable;
      final row0 = table.rows[0] as OrgTableCellRow;
      expect(row0.cells[0].content.children.isEmpty, isTrue);
      expect(table.rectangular, isTrue);
      expect(table.columnCount, 1);
      expect(table.columnIsNumeric(0), isFalse);
    });
    test('With non-markup plus in cell', () {
      // https://github.com/amake/orgro/issues/175
      final result = parser.parse('''  |-------+------|
| +Text | Text |
|-------+------|
|   +5+ |  -10 |
|-------+------|
''');
      final table = result.value as OrgTable;
      expect(table.columnCount, 2);
      expect(table.rectangular, isTrue);
      expect(table.rows[0], isA<OrgTableDividerRow>());
      final row1 = table.rows[1] as OrgTableCellRow;
      final cell0 = row1.cells[0].content.children[0] as OrgPlainText;
      expect(cell0.content, '+Text');
      final row4 = table.rows[3] as OrgTableCellRow;
      final cell0Row4 = row4.cells[0].content.children[0] as OrgMarkup;
      final cell0Row4Content =
          cell0Row4.content.children.single as OrgPlainText;
      expect(cell0Row4Content.content, '5');
      expect(cell0Row4.leadingDecoration, '+');
      expect(cell0Row4.trailingDecoration, '+');
    });
    test('no columns', () {
      final result = parser.parse('+-+');
      final table = result.value as OrgTable;
      expect(table.rows[0], isA<OrgTableDividerRow>());
      expect(table.columnCount, 0);
      expect(table.rectangular, isFalse);
      expect(() => table.columnIsNumeric(0), throwsRangeError);
    });
    test('uneven rows', () {
      final result = parser.parse('''| a | b | c |
|---+---+---|
| 1 | 2 |
| 3 | 4 | 5 |
''');
      final table = result.value as OrgTable;
      expect(table.columnCount, 3);
      expect(table.rectangular, isFalse);
      expect(table.columnIsNumeric(2), isTrue);
      expect(table.rows.length, 4);
    });
  });
}
