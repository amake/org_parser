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
    });
  });
}
