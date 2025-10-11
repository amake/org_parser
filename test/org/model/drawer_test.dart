import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('drawer', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.drawer()).end();
    test('indented', () {
      final markup = '''  :foo:
  :bar: baz
  :bizz: buzz
  :end:

''';
      final result = parser.parse(markup);
      final drawer = result.value as OrgDrawer;
      expect(drawer.contains('foo'), isTrue);
      expect(drawer.contains('あ'), isFalse);
      expect(drawer.toMarkup(), markup);
      expect(drawer.toPlainText(), markup);
    });
    test('simple', () {
      final markup = ''':LOGBOOK:
a
:END:
''';
      final result = parser.parse(markup);
      final drawer = result.value as OrgDrawer;
      expect(drawer.contains('a'), isTrue);
      expect(drawer.contains('あ'), isFalse);
      expect(drawer.toMarkup(), markup);
      expect(drawer.toPlainText(), markup);
    });
    test('empty', () {
      final markup = ''':FOOBAR:
:END:''';
      final result = parser.parse(markup);
      final drawer = result.value as OrgDrawer;
      expect(drawer.contains('FOOBAR'), isTrue);
      expect(drawer.contains('あ'), isFalse);
      expect(drawer.toMarkup(), markup);
      expect(drawer.toPlainText(), markup);
    });
  });
}
