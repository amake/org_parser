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
}
