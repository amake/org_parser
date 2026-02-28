import 'package:petitparser/petitparser.dart';

class PlistGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(elements).trim().end();

  Parser elements() => ref0(element).trim().star();

  Parser element() => ref0(string) | ref0(symbol);

  Parser symbol() => whitespace().neg().plusLazy(whitespace() | endOfInput());

  Parser string() => char('"') & ref0(stringContent) & char('"');

  Parser stringContent() => ref0(stringChar).plusLazy(char('"'));

  Parser stringChar() => ref0(escapedChar).castList<String>().pick(1) | any();

  Parser escapedChar() => char(r'\') & any();
}
