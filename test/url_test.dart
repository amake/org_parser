import 'package:org_parser/src/url.dart';
import 'package:test/test.dart';

void main() {
  test('local section url parser', () {
    expect(isOrgLocalSectionUrl('*foo'), isTrue);
    expect(isOrgLocalSectionUrl('foo'), isFalse);
    expect(parseOrgLocalSectionUrl('*foo bar'), 'foo bar');
    expect(parseOrgLocalSectionUrl('''*foo
  bar'''), 'foo bar');
  });
  test('custom ID url parser', () {
    expect(isOrgCustomIdUrl('#foo'), isTrue);
    expect(isOrgCustomIdUrl('foo'), isFalse);
    expect(parseOrgCustomIdUrl('#foo bar'), 'foo bar');
  });
  test('ID url parser', () {
    expect(isOrgIdUrl('id:foo'), isTrue);
    expect(isOrgIdUrl('foo'), isFalse);
    expect(parseOrgIdUrl('id:foo bar'), 'foo bar');
  });
  test('Coderef url parser', () {
    expect(isCoderefUrl('(foo)'), isTrue);
    expect(isCoderefUrl('foo'), isFalse);
    expect(isCoderefUrl('(f(o)o)'), isFalse);
    expect(parseCoderefUrl('(foo bar)'), 'foo bar');
  });
}
