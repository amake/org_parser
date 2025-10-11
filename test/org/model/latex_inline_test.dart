import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('inline LaTeX', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.latexInline()).end();
    test(r'single-$ delimiter', () {
      final markup = r'$i$';
      final result = parser.parse(markup);
      final latex = result.value as OrgLatexInline;
      expect(latex.contains('i'), isTrue);
      expect(latex.contains('あ'), isFalse);
      expect(latex.toMarkup(), markup);
      expect(latex.toPlainText(), 'i');
    });
    test(r'double-$ delimiter', () {
      final markup = r'$$ a^2 $$';
      final result = parser.parse(markup);
      final latex = result.value as OrgLatexInline;
      expect(latex.contains('a^2'), isTrue);
      expect(latex.contains('あ'), isFalse);
      expect(latex.toMarkup(), markup);
      expect(latex.toPlainText(), 'a^2');
    });
    test('paren delimiter', () {
      final markup = r'\( foo \)';
      final result = parser.parse(markup);
      final latex = result.value as OrgLatexInline;
      expect(latex.contains('foo'), isTrue);
      expect(latex.contains('あ'), isFalse);
      expect(latex.toMarkup(), markup);
      expect(latex.toPlainText(), 'foo');
    });
    test('bracket delimiter', () {
      final markup = r'\[ bar \]';
      final result = parser.parse(markup);
      final latex = result.value as OrgLatexInline;
      expect(latex.contains('bar'), isTrue);
      expect(latex.contains('あ'), isFalse);
      expect(latex.toMarkup(), markup);
      expect(latex.toPlainText(), 'bar');
    });
  });
}
