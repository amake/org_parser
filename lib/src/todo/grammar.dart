import 'package:petitparser/petitparser.dart';

class TodoGrammar extends GrammarDefinition {
  @override
  Parser start() => ref0(workflow).end();

  Parser workflow() =>
      ref0(todoStates).optional() &
      ref0(doneStates).optional().map((items) => items?[1]);

  Parser todoStates() =>
      ref0(todoState).trim().plusLazy(char('|') | endOfInput());

  Parser doneStates() => char('|') & ref0(todoStates);

  Parser todoState() =>
      // FIXME(aaron): This is kind of insane. Actual Org Mode is very
      // imperative: it splits by whitespace and then parses out the annotation
      // with regex
      whitespace()
          .neg()
          .plusLazy(ref0(annotation) | whitespace() | endOfInput())
          .flatten('state name expected')
          .where((result) => result != '|') &
      ref0(annotation).optional();

  Parser annotation() =>
      char('(') &
      char(')').neg().plusGreedy(char(')')).flatten('annotation expected') &
      char(')');
}
