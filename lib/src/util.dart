import 'package:petitparser/petitparser.dart';

Parser lineStart() => startOfInput() | was(Token.newlineParser());

Parser lineEnd() => Token.newlineParser() | endOfInput();

Parser<List<R>> drop<R>(Parser<R> parser, List<int> indexes) {
  return parser.castList<R>().map<List<R>>((list) {
    var result = list;
    for (var index in indexes.reversed) {
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

Parser<void> startOfInput([String message = 'start of input expected']) =>
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

const kUnlimitedSeparatingLineBreaks = -1;

Parser indentedRegion(
        {Parser parser,
        int indentAdjust = 0,
        int maxSeparatingLineBreaks = -1}) =>
    IndentedRegionParser(parser, indentAdjust, maxSeparatingLineBreaks);

class IndentedRegionParser extends DelegateParser {
  IndentedRegionParser(
      Parser delegate, this.indentAdjust, this.maxSeparatingLineBreaks)
      : assert(maxSeparatingLineBreaks == kUnlimitedSeparatingLineBreaks ||
            maxSeparatingLineBreaks > 0),
        super(delegate ?? any().star().flatten('Region content expected'));

  final int indentAdjust;
  final int maxSeparatingLineBreaks;

  @override
  DelegateParser copy() =>
      IndentedRegionParser(delegate, indentAdjust, maxSeparatingLineBreaks);

  @override
  Result parseOn(Context context) {
    final end = _endOfRegion(context.buffer, context.position);
    final delegateResult = delegate.parseOn(_regionContext(context, end));
    if (delegateResult.isFailure) {
      return context.failure('Indented region delegate parser failed');
    } else {
      return context.success(delegateResult.value, end);
    }
  }

  Context _regionContext(Context current, int regionEnd) {
    if (current.buffer.length == regionEnd) {
      return current;
    } else {
      final regionBuffer =
          current.buffer.substring(current.position, regionEnd);
      return Context(regionBuffer, 0);
    }
  }

  @override
  int fastParseOn(String buffer, int position) {
    final end = _endOfRegion(buffer, position);
    final delegateResult =
        delegate.fastParseOn(buffer.substring(position, end), 0);
    return delegateResult >= 0 ? end : -1;
  }

  int _endOfRegion(String buffer, int position) {
    final startOfLine = buffer.lastIndexOf('\n', position);
    final indent = (startOfLine < 0 ? position : position - startOfLine - 1) +
        indentAdjust;
    final indentPattern = ' ' * indent;
    var here = _endOfNextNewLineRun(buffer, position);
    while (here >= 0 && here < buffer.length - indent) {
      if (!buffer.startsWith(indentPattern, here)) {
        break;
      }
      here = _endOfNextNewLineRun(buffer, here);
    }
    if (here < 0) {
      here = buffer.length;
    }
    assert(here >= 0, 'Region detection should never fail');
    return here;
  }

  int _endOfNextNewLineRun(String buffer, int position) {
    final start = buffer.indexOf('\n', position);
    var here = start;
    var lines = 0;
    while (
        here >= 0 && here < buffer.length && buffer.codeUnitAt(here) == 0x0a) {
      final next = here + 1;
      if (next < buffer.length && buffer.codeUnitAt(next) == 0x0d) {
        here++;
      }
      lines++;
      if (maxSeparatingLineBreaks != kUnlimitedSeparatingLineBreaks &&
          lines > maxSeparatingLineBreaks) {
        break;
      }
      here++;
    }
    return here;
  }
}
