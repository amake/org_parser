import 'package:petitparser/petitparser.dart';

// Is then code (a 16-bit unsigned integer) a UTF-16 lead surrogate.
bool _isLeadSurrogate(int code) => (code & 0xFC00) == 0xD800;

// Is then code (a 16-bit unsigned integer) a UTF-16 trail surrogate.
bool _isTrailSurrogate(int code) => (code & 0xFC00) == 0xDC00;

// Combine a lead and a trail surrogate value into a single code point.
int _combineSurrogatePair(int start, int end) {
  return 0x10000 + ((start & 0x3FF) << 10) + (end & 0x3FF);
}

Parser<int> codePointRange({required int from, required int to}) =>
    anyCodePoint().where((value) => from <= value && value <= to);

/// Returns a parser that accepts any input element. Like [any] but consumes
/// code point-wise, not code unit-wise, at the cost of some overhead. Returns
/// the numeric value rather than a string.
Parser<int> anyCodePoint([String message = 'input expected']) =>
    _AnyCodePointParser(message);

/// A parser that accepts any input element, code point-wise.
class _AnyCodePointParser extends Parser<int> {
  _AnyCodePointParser(this.message);

  /// Error message to annotate parse failures with.
  final String message;

  @override
  Result<int> parseOn(Context context) {
    final buffer = context.buffer;
    final position = context.position;
    if (position < buffer.length) {
      var result = buffer.codeUnitAt(position);
      var length = 1;
      if (_isLeadSurrogate(result) && position + 1 < buffer.length) {
        final next = buffer.codeUnitAt(position + 1);
        if (_isTrailSurrogate(next)) {
          result = _combineSurrogatePair(result, next);
          length++;
        }
      }
      return context.success(result, position + length);
    }
    return context.failure(message);
  }

  @override
  int fastParseOn(String buffer, int position) {
    if (position >= buffer.length) return -1;
    return position + 1 < buffer.length &&
            _isLeadSurrogate(buffer.codeUnitAt(position)) &&
            _isTrailSurrogate(buffer.codeUnitAt(position + 1))
        ? position + 2
        : position + 1;
  }

  @override
  String toString() => '${super.toString()}[$message]';

  @override
  _AnyCodePointParser copy() => _AnyCodePointParser(message);

  @override
  bool hasEqualProperties(_AnyCodePointParser other) =>
      super.hasEqualProperties(other) && message == other.message;
}
