import 'package:org_parser/src/util/util.dart';
import 'package:petitparser/petitparser.dart';

final _start = stringIgnoreCase('#+begin_') &
    whitespace().neg().plusString('Block name expected') &
    lineTrailing().flatten('Trailing line content expected');

Parser blockParser([Parser? delegate]) =>
    BlockParser(delegate ?? any().starString('Block content expected'));

class BlockParser<R> extends DelegateParser<R, List<dynamic>> {
  BlockParser(Parser<R> delegate) : super(delegate);

  @override
  BlockParser<R> copy() => BlockParser(delegate);

  @override
  Result<List<dynamic>> parseOn(Context context) {
    final startResult = _start.parseOn(context);
    if (startResult is Failure) {
      return startResult;
    }
    final name = startResult.value[1];
    final endPattern = RegExp(
      '^(\\s*)(${RegExp.escape('#+end_$name')})',
      caseSensitive: false,
      multiLine: true,
    );
    final endMatch =
        endPattern.allMatches(context.buffer, startResult.position).firstOrNull;
    if (endMatch == null) {
      return context.failure('Block end expected');
    }
    final contentResult = delegate.parseOn(Context(
        context.buffer.substring(startResult.position, endMatch.start), 0));
    if (contentResult is Failure) {
      return contentResult;
    }
    return context.success(
      [
        startResult.value,
        contentResult.value,
        [endMatch[1]!, endMatch[2]!],
      ],
      endMatch.end,
    );
  }
}
