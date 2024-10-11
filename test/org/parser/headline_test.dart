import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('headline', () {
    final definition = OrgParserDefinition();
    final parser = definition.buildFrom(definition.headline()).end();
    test('full', () {
      final result = parser.parse('** TODO [#A] Title *foo* bar :biz:baz:');
      final headline = result.value as OrgHeadline;
      final title = headline.title!.children[0] as OrgPlainText;
      expect(title.content, 'Title ');
      final titleEmphasis = headline.title!.children[1] as OrgMarkup;
      expect(titleEmphasis.content, 'foo');
      expect(headline.tags?.values, ['biz', 'baz']);
    });
    test('empty', () {
      final result = parser.parse('* ');
      final headline = result.value as OrgHeadline;
      expect(headline.title, isNull);
    });
    test('with latex', () {
      final result = parser.parse(r'* foo \( \pi \)');
      final headline = result.value as OrgHeadline;
      final [title0, title1] = headline.title!.children;
      expect((title0 as OrgPlainText).content, 'foo ');
      expect((title1 as OrgLatexInline).content, r' \pi ');
    });
  });
}
