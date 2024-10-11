import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final definition = OrgContentParserDefinition();
  final parser = definition.buildFrom(definition.latexBlock()).end();
  test('LaTeX block', () {
    final result = parser.parse(r'''\begin{equation}
\begin{matrix}
   a & b \\
   c & d
\end{matrix}
\end{equation}
''');
    final latex = result.value as OrgLatexBlock;
    expect(latex.environment, 'equation');
    expect(latex.begin, r'\begin{equation}');
    expect(latex.content,
        '\n\\begin{matrix}\n   a & b \\\\\n   c & d\n\\end{matrix}\n');
    expect(latex.end, r'\end{equation}');
  });
}
