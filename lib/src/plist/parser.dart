import 'package:org_parser/src/plist/grammar.dart';
import 'package:petitparser/petitparser.dart';

final orgPlist = PlistParser().build();

class PlistParser extends PlistGrammar {
  @override
  Parser<dynamic> start() => super.start().castList<String>();

  @override
  Parser symbol() => super.symbol().flatten(message: 'symbol expected');

  @override
  Parser string() => super.string().castList<String>().pick(1);

  @override
  Parser stringContent() =>
      super.stringContent().castList<String>().map((chars) => chars.join());
}
