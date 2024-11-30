import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('PGP block', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.pgpBlock()).end();
    test('simple', () {
      final markup = '''-----BEGIN PGP MESSAGE-----

jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
=chda
-----END PGP MESSAGE-----
''';
      final result = parser.parse(markup);
      final pgp = result.value as OrgPgpBlock;
      expect(pgp.contains('BEGIN PGP MESSAGE'), isTrue);
      expect(pgp.contains('あ'), isFalse);
      expect(pgp.toMarkup(), markup);
      expect(pgp.toRfc4880(), markup.trim());
    });
    test('indented', () {
      final markup = '''   -----BEGIN PGP MESSAGE-----

   jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
   X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
   =chda
   -----END PGP MESSAGE-----
''';
      final result = parser.parse(markup);
      final pgp = result.value as OrgPgpBlock;
      expect(pgp.contains('END PGP MESSAGE'), isTrue);
      expect(pgp.contains('あ'), isFalse);
      expect(pgp.toMarkup(), markup);
      expect(pgp.toRfc4880(), '''-----BEGIN PGP MESSAGE-----

jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
=chda
-----END PGP MESSAGE-----''');
    });
  });
}
