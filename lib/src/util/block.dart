import 'package:org_parser/src/util/util.dart';
import 'package:petitparser/petitparser.dart';

final _start = string('#+begin_', ignoreCase: true) &
    whitespace().neg().plusString(message: 'Block name expected') &
    lineTrailing().flatten(message: 'Trailing line content expected');

Parser blockParser([Parser? delegate]) => BlockParser(
    delegate ?? any().starString(message: 'Block content expected'));

class BlockParser<R> extends DelegateParser<R, List<dynamic>> {
  BlockParser(super.delegate);

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
        // Returning the name as if it was a part of the content is a hack. I
        // would have preferred to return a record like
        //
        //   (type: name, parts: [...])
        //
        // but records containing lists would need a custom matcher, and I just
        // can't be bothered with all that.
        name,
        startResult.value,
        contentResult.value,
        [endMatch[1]!, endMatch[2]!],
      ],
      endMatch.end,
    );
  }
}
