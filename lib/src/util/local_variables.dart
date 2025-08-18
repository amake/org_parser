import 'package:org_parser/src/util/util.dart';
import 'package:petitparser/petitparser.dart';

final _prefix = string('Local Variables:').neg().starString();
final _suffix = any().starLazy(lineEnd()).flatten(message: 'Suffix expected');
final _start = lineStart().flatten(message: 'Leading content expected') &
    _prefix &
    string('Local Variables:') &
    insignificantWhitespace().starString() &
    _suffix &
    lineEnd();

Parser localVariablesParser() => LocalVariablesParser();

class LocalVariablesParser extends Parser<List<dynamic>> {
  LocalVariablesParser();

  @override
  LocalVariablesParser copy() => LocalVariablesParser();

  @override
  Result<List<dynamic>> parseOn(Context context) {
    final startResult = _start.parseOn(context);
    if (startResult is Failure) {
      return startResult;
    }
    final prefix = startResult.value[1] as String;
    final suffix = startResult.value[4] as String;
    final contentResult = _rest(prefix, suffix)
        .parseOn(Context(context.buffer, startResult.position));
    if (contentResult is Failure) {
      return contentResult;
    }
    return context.success(
      [
        // Manually flatten start line
        context.buffer.substring(context.position, startResult.position),
        ...contentResult.value,
      ],
      contentResult.position,
    );
  }

  Parser _internalLine(String prefix, String suffix) {
    final end = suffix.isEmpty ? lineEnd() : string(suffix) & lineEnd();
    return (lineStart() &
            string(prefix) &
            string('End:')
                .neg()
                .starLazy(end)
                .flatten(message: 'Local variable line expected') &
            end.flatten(message: 'Trailing content expected'))
        .drop1(0);
  }

  Parser _endLine(String prefix, String suffix) {
    final end =
        suffix.isEmpty ? lineEnd().and() : string(suffix) & lineEnd().and();
    return (lineStart() &
            string(prefix) &
            string('End:') &
            insignificantWhitespace().starString() &
            end)
        .drop1(0);
  }

  Parser<List<dynamic>> _rest(String prefix, String suffix) =>
      _internalLine(prefix, suffix).star() &
      _endLine(prefix, suffix).flatten(message: 'End line expected');
}
