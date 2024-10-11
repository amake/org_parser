import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('PGP block', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.pgpBlock()).end();
    test('simple', () {
      final result = parser.parse('''-----BEGIN PGP MESSAGE-----

jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
=chda
-----END PGP MESSAGE-----
''');
      final block = result.value as OrgPgpBlock;
      expect(block.indent, '');
      expect(block.header, '-----BEGIN PGP MESSAGE-----');
      expect(
        block.body,
        '\n\n'
        'jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O\n'
        'X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=\n'
        '=chda\n',
      );
      expect(block.footer, '-----END PGP MESSAGE-----');
      expect(block.trailing, '\n');
    });
  });
}
