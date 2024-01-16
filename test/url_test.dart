import 'package:org_parser/src/url.dart';
import 'package:test/test.dart';

void main() {
  test('local section url parser', () {
    expect(true, isOrgLocalSectionUrl('*foo'));
    expect(false, isOrgLocalSectionUrl('foo'));
    expect('foo bar', parseOrgLocalSectionUrl('*foo bar'));
    expect('foo bar', parseOrgLocalSectionUrl('''*foo
  bar'''));
  });
  test('custom ID url parser', () {
    expect(true, isOrgCustomIdUrl('#foo'));
    expect(false, isOrgCustomIdUrl('foo'));
    expect('foo bar', parseOrgCustomIdUrl('#foo bar'));
  });
  test('ID url parser', () {
    expect(true, isOrgIdUrl('id:foo'));
    expect(false, isOrgIdUrl('foo'));
    expect('foo bar', parseOrgIdUrl('id:foo bar'));
  });
}
