import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('inline LaTeX', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.latexInline()).end();
    test(r'single-$ delimiter', () {
      final result = parser.parse(r'$i$');
      final latex = result.value as OrgLatexInline;
      expect(latex.leadingDecoration, r'$');
      expect(latex.content, r'i');
      expect(latex.trailingDecoration, r'$');
    });
    test(r'double-$ delimiter', () {
      final result = parser.parse(r'$$ a^2 $$');
      final latex = result.value as OrgLatexInline;
      expect(latex.leadingDecoration, r'$$');
      expect(latex.content, r' a^2 ');
      expect(latex.trailingDecoration, r'$$');
    });
    test('paren delimiter', () {
      final result = parser.parse(r'\( foo \)');
      final latex = result.value as OrgLatexInline;
      expect(latex.leadingDecoration, r'\(');
      expect(latex.content, r' foo ');
      expect(latex.trailingDecoration, r'\)');
    });
    test('bracket delimiter', () {
      final result = parser.parse(r'\[ bar \]');
      final latex = result.value as OrgLatexInline;
      expect(latex.leadingDecoration, r'\[');
      expect(latex.content, r' bar ');
      expect(latex.trailingDecoration, r'\]');
    });
  });
}
