import 'package:petitparser/petitparser.dart';

Parser lineStart() => startOfInput() | was(Token.newlineParser());

Parser lineEnd() => Token.newlineParser() | endOfInput();

Parser<List<R>> drop<R>(Parser<R> parser, List<int> indexes) {
  return parser.castList<R>().map<List<R>>((list) {
    var result = list;
    for (int index in indexes.reversed) {
      if (index < 0) {
        index = list.length + index;
      }
      result = result
          .sublist(0, index)
          .followedBy(result.sublist(index + 1))
          .toList();
    }
    return result;
  });
}

Parser<T> was<T>(Parser<T> parser) => LookBehindParser(parser);

class LookBehindParser<T> extends DelegateParser<T> {
  LookBehindParser(Parser delegate) : super(delegate);

  @override
  Result<T> parseOn(Context context) {
    final buffer = context.buffer;
    final position = context.position;
    if (position == 0) {
      return context.failure('Cannot look behind start of buffer');
    }
    final result = delegate.parseOn(Context(buffer, position - 1));
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

Parser<void> startOfInput([String message = 'end of input expected']) =>
    StartOfInputParser(message);

class StartOfInputParser extends Parser<void> {
  final String message;

  StartOfInputParser(this.message)
      : assert(message != null, 'message must not be null');

  @override
  Result parseOn(Context context) {
    return context.position > 0
        ? context.failure(message)
        : context.success(null);
  }

  @override
  int fastParseOn(String buffer, int position) => position > 0 ? -1 : position;

  @override
  String toString() => '${super.toString()}[$message]';

  @override
  StartOfInputParser copy() => StartOfInputParser(message);

  @override
  bool hasEqualProperties(StartOfInputParser other) =>
      super.hasEqualProperties(other) && message == other.message;
}
