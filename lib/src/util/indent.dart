import 'package:petitparser/petitparser.dart';

const kUnlimitedSeparatingLineBreaks = -1;

/// Returns a parser that applies [parser] to a uniformly indented region
/// starting at the current position.
///
/// [indentAdjust] allows applying an offset to the current position for
/// determining the required level of indentation.
///
/// [maxSeparatingLineBreaks] indicates how many consecutive line breaks are
/// allowed without considering the region to have ended. The default is
/// [kUnlimitedSeparatingLineBreaks], in which case any number of line breaks is
/// allowed.
Parser indentedRegion(
        {Parser? parser,
        int indentAdjust = 0,
        int maxSeparatingLineBreaks = -1}) =>
    IndentedRegionParser(
      parser ?? any().starString('Region content expected'),
      indentAdjust,
      maxSeparatingLineBreaks,
    );

/// A parser that applies [delegate] to a uniformly indented region
/// starting at the current position.
///
/// [indentAdjust] allows applying an offset to the current position for
/// determining the required level of indentation.
///
/// [maxSeparatingLineBreaks] indicates how many consecutive line breaks are
/// allowed without considering the region to have ended. The default is
/// [kUnlimitedSeparatingLineBreaks], in which case any number of line breaks is
/// allowed.
class IndentedRegionParser<R> extends DelegateParser<R, R> {
  IndentedRegionParser(
      Parser<R> delegate, this.indentAdjust, this.maxSeparatingLineBreaks)
      : assert(maxSeparatingLineBreaks == kUnlimitedSeparatingLineBreaks ||
            maxSeparatingLineBreaks > 0),
        super(delegate);

  final int indentAdjust;
  final int maxSeparatingLineBreaks;

  @override
  IndentedRegionParser<R> copy() =>
      IndentedRegionParser(delegate, indentAdjust, maxSeparatingLineBreaks);

  @override
  Result<R> parseOn(Context context) {
    final end = _endOfRegion(context.buffer, context.position);
    final delegateResult = delegate.parseOn(_regionContext(context, end));
    if (delegateResult is Failure) {
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
    var end = start, here = start;
    var lines = 0;
    outer:
    while (here >= 0 && here < buffer.length) {
      switch (buffer.codeUnitAt(here)) {
        case 0x20: // space
        case 0x09: // tab
        case 0x0d: // carriage return
          here++;
          break;
        case 0x0a: // line feed
          lines++;
          if (maxSeparatingLineBreaks != kUnlimitedSeparatingLineBreaks &&
              lines > maxSeparatingLineBreaks) {
            break outer;
          } else {
            end = ++here;
          }
          break;
        default:
          break outer;
      }
    }
    return end;
  }
}
