import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('local variables', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.localVariables()).end();
    test('simple', () {
      final result = parser.parse('''# Local Variables:
# foo: bar
# End: ''');
      expect(result.value, [
        [
          '# Local Variables:\n',
          [
            ['# ', 'foo: bar', '\n']
          ],
          '# End: ',
        ],
        ''
      ]);
    });
    test('with suffix', () {
      final result = parser.parse('''# Local Variables: #
# foo: bar #
# End: #''');
      expect(result.value, [
        [
          '# Local Variables: #\n',
          [
            ['# ', 'foo: bar ', '#\n']
          ],
          '# End: #'
        ],
        ''
      ]);
    });
    test('bad prefix', () {
      final result = parser.parse('''# Local Variables:
## foo: bar
# End:''');
      expect(result, isA<Failure>());
    });
    test('bad suffix', () {
      final result = parser.parse('''/* Local Variables: */
/* foo: bar */
/* End: **/''');
      expect(result, isA<Failure>());
    });
  });
}
