import 'package:petitparser/petitparser.dart';

Parser<List<dynamic>> _latexBlockStart() =>
    string(r'\begin{') &
    (char('}').neg().plusLazy(char('}')))
        .flatten(message: 'LaTeX environment expected') &
    char('}');

class LatexBlockParser extends DelegateParser<List<dynamic>, List<dynamic>> {
  LatexBlockParser() : super(_latexBlockStart());

  @override
  Result<List<dynamic>> parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result is Failure) {
      return result;
    }
    final environment = result.value[1] as String;
    final end = '\\end{$environment}';
    final index = result.buffer.indexOf(end, result.position);
    if (index == -1) {
      return result.failure('Missing end of LaTeX environment');
    }
    final content = result.buffer.substring(result.position, index);
    return result.success([result.value, content, end], index + end.length);
  }

  @override
  LatexBlockParser copy() => LatexBlockParser();
}
