import 'package:org_parser/src/org/org.dart';
import 'package:test/test.dart';

void main() {
  final parser = org;

  group('set property', () {
    group('empty doc', () {
      test('add drawer and property', () {
        final result = parser.parse('');
        final doc = result.value as OrgDocument;
        final updated = doc.setProperty(
          OrgProperty('', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), ''':PROPERTIES:
:PRIORITY: A
:END:
''');
      });
      test('add property', () {
        final result = parser.parse(''':PROPERTIES:
:END:
''');
        final doc = result.value as OrgDocument;
        final updated = doc.setProperty(
          OrgProperty('', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), ''':PROPERTIES:
:PRIORITY: A
:END:
''');
      });
      test('set property', () {
        final result = parser.parse(''':PROPERTIES:
:PRIORITY: B
:END:
''');
        final doc = result.value as OrgDocument;
        final updated = doc.setProperty(
          OrgProperty('', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), ''':PROPERTIES:
:PRIORITY: A
:END:
''');
      });
    });
  });
}
