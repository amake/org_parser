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
  :bazinga:
  :bizz: buzz
  :end:

''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.header, ':foo:\n');
      expect(drawer.properties().length, 3);
      final body = drawer.body;
      final property = body.children[0] as OrgProperty;
      expect(property.key, ':bar:');
      final value = property.value!.children[0] as OrgPlainText;
      expect(value.content, 'baz');
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
      final body = drawer.body;
      final text = body.children[0] as OrgPlainText;
      expect(text.content, 'a\n');
    });
    test('rich property', () {
      final result = parser.parse(''':LOGBOOK:
:foo: *bar*
:END:
''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.header, ':LOGBOOK:\n');
      final property = drawer.properties().first;
      expect(property.isEmpty, isFalse);
      expect(property.isNotEmpty, isTrue);
      final value = property.value!.children[0] as OrgMarkup;
      expect(value.toMarkup(), '*bar*');
    });
    test('empty', () {
      final result = parser.parse(''':FOOBAR:
:END:''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.properties().isEmpty, isTrue);
      final body = drawer.body;
      expect(body.children.isEmpty, isTrue);
    });
    test('empty property', () {
      final result = parser.parse(''':FOOBAR:
:foo:
:END:''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.properties().length, 1);
      final body = drawer.body;
      final property = body.children[0] as OrgProperty;
      expect(property.key, ':foo:');
      expect(property.isEmpty, isTrue);
      expect(property.isNotEmpty, isFalse);
    });
    test('whitespace-only property', () {
      final result = parser.parse(''':FOOBAR:
:foo:${' '}
:END:''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.properties().length, 1);
      final body = drawer.body;
      final property = body.children[0] as OrgProperty;
      expect(property.key, ':foo:');
      expect(property.isEmpty, isTrue);
      expect(property.isNotEmpty, isFalse);
    });
    test('empty and real value property', () {
      final result = parser.parse(''':FOOBAR:
:foo:
:foo: bar
:END:''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.properties().length, 2);
      final body = drawer.body;
      final property = body.children[0] as OrgProperty;
      expect(property.key, ':foo:');
      expect(property.isEmpty, isTrue);
      expect(property.isNotEmpty, isFalse);
      final property2 = body.children[1] as OrgProperty;
      expect(property2.key, ':foo:');
      expect(property2.isEmpty, isFalse);
      expect(property2.isNotEmpty, isTrue);
    });
  });
}
