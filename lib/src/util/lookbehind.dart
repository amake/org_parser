import 'package:petitparser/petitparser.dart';

/// Returns a parser that attempts to match the given parser from one character
/// behind the actual current position.
Parser<T> was<T>(Parser<T> parser) => LookBehindParser(parser);

/// A parser that attempts to match the given parser from one character behind
/// the actual current position.
class LookBehindParser<T> extends DelegateParser<T> {
  LookBehindParser(Parser delegate) : super(delegate);

  @override
  Result<T> parseOn(Context context) {
    final buffer = context.buffer;
    final position = context.position;
    if (position == 0) {
      return context.failure('Cannot look behind start of buffer');
    }
    final result = delegate.parseOn(Context(buffer, position - 1)) as Result<T>;
    if (result.isSuccess) {
      return context.success(result.value);
    } else {
      return result;
    }
  }

  @override
  int fastParseOn(String buffer, int position) {
    if (position == 0) {
      return -1;
    }
    final result = delegate.fastParseOn(buffer, position - 1);
    return result < 0 ? -1 : position;
  }

  @override
  LookBehindParser<T> copy() => LookBehindParser<T>(delegate);
}
