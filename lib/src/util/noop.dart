import 'package:petitparser/petitparser.dart';

Parser noOpFail() => NoOpParser(false);

class NoOpParser extends Parser {
  NoOpParser(this.succeed);

  final bool succeed;

  @override
  Parser copy() => NoOpParser(succeed);

  @override
  Result parseOn(Context context) =>
      succeed ? context.success('') : context.failure('No-op');
}
