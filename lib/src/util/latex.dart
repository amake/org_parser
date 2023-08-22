import 'package:petitparser/petitparser.dart';

Parser _latexBlockStart() =>
    string(r'\begin{') &
    (char('}').neg().plusLazy(char('}')))
        .flatten('LaTeX environment expected') &
    char('}');

class LatexBlockParser extends DelegateParser {
  LatexBlockParser() : super(_latexBlockStart());

  @override
  Result parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result is Success) {
      final environment = result.value[1] as String;
      final end = '\\end{$environment}';
      final index = result.buffer.indexOf(end, result.position);
      if (index > 0) {
        final content = result.buffer.substring(result.position, index);
        return result.success([result.value, content, end], index + end.length);
      }
    }
    return result;
  }

  @override
  Parser copy() => this;
}
