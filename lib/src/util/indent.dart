import 'package:petitparser/petitparser.dart';

/// Returns a parser that applies [parser] to a uniformly indented region
/// starting at the current position.
Parser indentedRegion({Parser? parser}) => IndentedRegionParser(
      parser ?? any().starString('Region content expected'),
    );

/// A parser that applies [delegate] to a uniformly indented region
/// starting at the current position.
class IndentedRegionParser<R> extends DelegateParser<R, R> {
  IndentedRegionParser(super.delegate);

  @override
  IndentedRegionParser<R> copy() => IndentedRegionParser(delegate);

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
    final indent = startOfLine < 0 ? position : position - startOfLine - 1;
    var here = _endOfNextNewLineRun(buffer, position);
    while (here >= 0 && here < buffer.length - indent) {
      if (!_isIndentedTo(buffer, here, indent)) {
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

  bool _isIndentedTo(String buffer, int position, int indent) {
    for (var i = position; i < position + indent; i++) {
      if (buffer.codeUnitAt(i) != 0x20) {
        return false;
      }
    }
    return true;
  }

  int _endOfNextNewLineRun(String buffer, int position) {
    // Org Mode explicitly checks for blocks and drawers:
    // https://git.savannah.gnu.org/cgit/emacs/org-mode.git/tree/lisp/org-list.el?h=release_9.7.16#n754
    position = _skipAll(buffer, position);
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
          if (lines > 2) {
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

  int _skipAll(String buffer, int position) {
    while (true) {
      var next = _skipOne(buffer, position, _blockStart, _blockEnd);
      next = _skipOne(buffer, next, _drawerStart, _drawerEnd);
      if (next == position) break;
      position = next;
    }
    return position;
  }

  int _skipOne(String buffer, int position, Pattern start, Pattern end) {
    while (buffer.startsWith(start, position)) {
      final endStart = buffer.indexOf(end, position);
      if (endStart < 0) {
        break;
      }
      // It would be great not to have to do this match, but there doesn't seem
      // to be an equivalent of `indexOf` that lets us get the end of the match.
      final m = end.matchAsPrefix(buffer, endStart)!;
      position = m.end;
    }
    return position;
  }
}

final _blockStart =
    RegExp(r'^[ \t]*#\+begin_', multiLine: true, caseSensitive: false);

final _blockEnd =
    RegExp(r'^[ \t]*#\+end_', multiLine: true, caseSensitive: false);

// TODO(aaron): We are allowing the same drawer name here as in the main
// grammar, but it should really be `[:word:]`
final _drawerStart = RegExp(r'^[ \t]*:[a-zA-Z0-9_@#%]+:[ \t]*$',
    multiLine: true, caseSensitive: false);

final _drawerEnd =
    RegExp(r'^[ \t]*:END:', multiLine: true, caseSensitive: false);
