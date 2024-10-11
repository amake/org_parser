import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final definition = OrgContentParserDefinition();
  final parser = definition.buildFrom(definition.latexBlock()).end();
  test('LaTeX block', () {
    final markup = r'''\begin{equation}
\begin{matrix}
   a & b \\
   c & d
\end{matrix}
\end{equation}
''';
    final result = parser.parse(markup);
    final latex = result.value as OrgLatexBlock;
    expect(latex.contains(r'\begin{matrix}'), isTrue);
    expect(latex.toMarkup(), markup);
  });
}
