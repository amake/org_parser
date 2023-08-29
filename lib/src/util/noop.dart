import 'package:petitparser/petitparser.dart';

/// Returns a parser that fails unconditionally without consuming anything.
///
/// This is useful for replacing a parser in a sequence when you want the same
/// sequence but without that one parser.
Parser noOpFail() => NoOpParser(false);

/// A parser that succeeds if [succeed] is true, or otherwise fails
/// unconditionally, both without consuming anything.
class NoOpParser extends Parser<void> {
  NoOpParser(this.succeed);

  final bool succeed;

  @override
  NoOpParser copy() => NoOpParser(succeed);

  @override
  Result<void> parseOn(Context context) {
    if (succeed) {
      return context.success(null);
    } else {
      return context.failure('No-op');
    }
  }
}
