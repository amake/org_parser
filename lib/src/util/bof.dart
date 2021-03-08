import 'package:petitparser/petitparser.dart';

/// Returns a parser that succeeds at the start of input. Mirrors [endOfInput]
/// in PetitParser.
Parser<void> startOfInput([String message = 'start of input expected']) =>
    StartOfInputParser(message);

/// A parser that succeeds at the start of input. Mirrors [EndOfInputParser] in
/// PetitParser.
class StartOfInputParser extends Parser<void> {
  final String message;

  StartOfInputParser(this.message);

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
