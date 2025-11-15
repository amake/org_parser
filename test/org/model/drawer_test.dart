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
    group('editing', () {
      test('add to empty', () {
        final markup = ''':FOOBAR:
:END:''';
        final result = parser.parse(markup);
        final drawer = result.value as OrgDrawer;
        final updated = drawer.setProperty(OrgProperty(
            '', ':bizz:', OrgContent([OrgPlainText(' buzz')]), '\n'));
        expect(updated.toMarkup(), ''':FOOBAR:
:bizz: buzz
:END:''');
      });
      test('add to empty with indent', () {
        final markup = '''  :FOOBAR:
  :END:''';
        final result = parser.parse(markup);
        final drawer = result.value as OrgDrawer;
        final updated = drawer.setProperty(OrgProperty(
            '  ', ':bizz:', OrgContent([OrgPlainText(' buzz')]), '\n'));
        expect(updated.toMarkup(), '''  :FOOBAR:
  :bizz: buzz
  :END:''');
      });
      test('add', () {
        final markup = ''':FOOBAR:
:bazz: fizz
:END:''';
        final result = parser.parse(markup);
        final drawer = result.value as OrgDrawer;
        final updated = drawer.setProperty(OrgProperty(
            '', ':bizz:', OrgContent([OrgPlainText(' buzz')]), '\n'));
        expect(updated.toMarkup(), ''':FOOBAR:
:bazz: fizz
:bizz: buzz
:END:''');
      });
      test('replace', () {
        final markup = ''':FOOBAR:
:bizz: fizz
:END:''';
        final result = parser.parse(markup);
        final drawer = result.value as OrgDrawer;
        final updated = drawer.setProperty(OrgProperty(
            '', ':bizz:', OrgContent([OrgPlainText(' buzz')]), '\n'));
        expect(updated.toMarkup(), ''':FOOBAR:
:bizz: buzz
:END:''');
      });
    });
  });
}
