library org_parser;

import 'package:petitparser/petitparser.dart';

class OrgGrammar extends GrammarParser {
  OrgGrammar() : super(OrgGrammarDefinition());
}

class OrgGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref(section).star().end();

  Parser section() => ref(header) & ref(content).optional();

  Parser header() =>
      ref(headerDecoration).trim() &
      ref(todo).trim().optional() &
      ref(headerTitle).trim(Token.newlineParser());

  Parser headerDecoration() => char('*').plus().flatten();

  Parser todo() => string('TODO') | string('DONE');

  Parser headerTitle() => Token.newlineParser().neg().star().flatten();

  Parser content() => ref(header).neg().plus().flatten();
}
