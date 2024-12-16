import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('PGP block', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.pgpBlock()).end();
    test('simple', () {
      final result = parser.parse('''-----BEGIN PGP MESSAGE-----

jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
=chda
-----END PGP MESSAGE-----
''');
      expect(result.value, [
        '',
        [
          '-----BEGIN PGP MESSAGE-----',
          '\n\n'
              'jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O\n'
              'X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=\n'
              '=chda\n',
          '-----END PGP MESSAGE-----',
        ],
        '\n'
      ]);
    });
    test('indented', () {
      final result = parser.parse('''   -----BEGIN PGP MESSAGE-----

   jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
   X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
   =chda
   -----END PGP MESSAGE-----

''');
      expect(result.value, [
        '   ',
        [
          '-----BEGIN PGP MESSAGE-----',
          '\n\n'
              '   jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O\n'
              '   X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=\n'
              '   =chda\n'
              '   ',
          '-----END PGP MESSAGE-----',
        ],
        '\n\n'
      ]);
    });
  });
}
