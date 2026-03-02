import 'package:org_parser/src/org/org.dart';
import 'package:org_parser/src/search.dart';
import 'package:test/test.dart';

void main() {
  test('local section search parser', () {
    expect(isOrgLocalSectionSearch('*foo'), isTrue);
    expect(isOrgLocalSectionSearch('foo'), isFalse);
    expect(parseOrgLocalSectionSearch('*foo bar'), 'foo bar');
    expect(parseOrgLocalSectionSearch('''*foo
  bar'''), 'foo bar');
  });
  test('custom ID search parser', () {
    expect(isOrgCustomIdSearch('#foo'), isTrue);
    expect(isOrgCustomIdSearch('foo'), isFalse);
    expect(parseOrgCustomIdSearch('#foo bar'), 'foo bar');
  });
  test('ID search parser', () {
    expect(isOrgIdSearch('id:foo'), isTrue);
    expect(isOrgIdSearch('foo'), isFalse);
    expect(isOrgIdSearch('id:foo::/bar/'), isFalse);
    expect(parseOrgIdSearch('id:foo bar'), 'foo bar');
  });
  test('Coderef search parser', () {
    expect(isCoderefSearch('(foo)'), isTrue);
    expect(isCoderefSearch('foo'), isFalse);
    expect(isCoderefSearch('(f(o)o)'), isFalse);
    expect(parseCoderefSearch('(foo bar)'), 'foo bar');
  });
  group('OrgTreeSearch', () {
    final doc = OrgDocument.parse('''* foo
** bar
:PROPERTIES:
:ID: bar-id
:END:
** baz
:PROPERTIES:
:CUSTOM_ID: baz-custom-id
:END:
''');
    test('section title', () {
      expect(doc.sectionWithTitle('foo'), doc.sections.first);
      expect(doc.sectionForTarget('*foo'), doc.sections.first);
    });
    test('ID search', () {
      expect(doc.sectionWithId('bar-id'), doc.sections[0].sections[0]);
      expect(doc.sectionForTarget('id:bar-id'), doc.sections[0].sections[0]);
    });
    test('custom ID search', () {
      expect(doc.sectionWithCustomId('baz-custom-id'),
          doc.sections[0].sections[1]);
      expect(
          doc.sectionForTarget('#baz-custom-id'), doc.sections[0].sections[1]);
    });
  });
}
