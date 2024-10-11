import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('drawer', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.drawer()).end();
    test('indented', () {
      final result = parser.parse('''  :foo:
  :bar: baz
  :bizz: buzz
  :end:

''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.header, ':foo:\n');
      expect(drawer.properties().length, 2);
      final body = drawer.body as OrgContent;
      final property = body.children[0] as OrgProperty;
      expect(property.key, ':bar:');
      expect(property.value, ' baz');
      expect(drawer.footer, '  :end:');
      expect(drawer.properties().first, property);
    });
    test('simple', () {
      final result = parser.parse(''':LOGBOOK:
a
:END:
''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.header, ':LOGBOOK:\n');
      expect(drawer.properties().isEmpty, isTrue);
      final body = drawer.body as OrgContent;
      final text = body.children[0] as OrgPlainText;
      expect(text.content, 'a\n');
    });
    test('empty', () {
      final result = parser.parse(''':FOOBAR:
:END:''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.properties().isEmpty, isTrue);
      final body = drawer.body as OrgContent;
      expect(body.children.isEmpty, isTrue);
    });
  });
}
