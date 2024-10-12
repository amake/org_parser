import 'package:org_parser/src/query/query.dart';
import 'package:test/test.dart';

void main() {
  group('tag', () {
    test('single included tag', () {
      expect(orgQuery.parse('foo').value, OrgQueryTagMatcher('foo'));
      expect(orgQuery.parse('+foo').value, OrgQueryTagMatcher('foo'));
    });
    test('single excluded tag', () {
      expect(
        orgQuery.parse('-foo').value,
        OrgQueryNotMatcher(OrgQueryTagMatcher('foo')),
      );
    });
    test('non-ASCII tag', () {
      expect(orgQuery.parse('あ').value, OrgQueryTagMatcher('あ'));
      expect(orgQuery.parse('+あ').value, OrgQueryTagMatcher('あ'));
    });
    test('implicit and', () {
      expect(
        orgQuery.parse('foo+bar').value,
        OrgQueryAndMatcher(
          [OrgQueryTagMatcher('foo'), OrgQueryTagMatcher('bar')],
        ),
      );
      expect(
        orgQuery.parse('foo-bar').value,
        OrgQueryAndMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryNotMatcher(OrgQueryTagMatcher('bar')),
          ],
        ),
      );
      expect(
        orgQuery.parse('foo+bar-baz').value,
        OrgQueryAndMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryAndMatcher([
              OrgQueryTagMatcher('bar'),
              OrgQueryNotMatcher(OrgQueryTagMatcher('baz')),
            ])
          ],
        ),
      );
      expect(
        orgQuery.parse('foo+bar-baz+buzz').value,
        OrgQueryAndMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryAndMatcher([
              OrgQueryTagMatcher('bar'),
              OrgQueryAndMatcher([
                OrgQueryNotMatcher(OrgQueryTagMatcher('baz')),
                OrgQueryTagMatcher('buzz'),
              ])
            ])
          ],
        ),
      );
    });
    test('explicit and', () {
      expect(
        orgQuery.parse('foo&bar').value,
        OrgQueryAndMatcher(
          [OrgQueryTagMatcher('foo'), OrgQueryTagMatcher('bar')],
        ),
      );
      expect(
        orgQuery.parse('foo&+bar').value,
        OrgQueryAndMatcher(
          [OrgQueryTagMatcher('foo'), OrgQueryTagMatcher('bar')],
        ),
      );
      expect(
        orgQuery.parse('foo&-bar').value,
        OrgQueryAndMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryNotMatcher(OrgQueryTagMatcher('bar')),
          ],
        ),
      );
      expect(
        orgQuery.parse('foo&bar&-baz').value,
        OrgQueryAndMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryAndMatcher([
              OrgQueryTagMatcher('bar'),
              OrgQueryNotMatcher(OrgQueryTagMatcher('baz')),
            ])
          ],
        ),
      );
      expect(
        orgQuery.parse('foo&+bar&-baz&buzz').value,
        OrgQueryAndMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryAndMatcher([
              OrgQueryTagMatcher('bar'),
              OrgQueryAndMatcher([
                OrgQueryNotMatcher(OrgQueryTagMatcher('baz')),
                OrgQueryTagMatcher('buzz'),
              ])
            ])
          ],
        ),
      );
      expect(
        orgQuery.parse('foo+bar&-baz+buzz').value,
        OrgQueryAndMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryAndMatcher([
              OrgQueryTagMatcher('bar'),
              OrgQueryAndMatcher([
                OrgQueryNotMatcher(OrgQueryTagMatcher('baz')),
                OrgQueryTagMatcher('buzz'),
              ])
            ])
          ],
        ),
      );
    });
    test('alternates', () {
      expect(
        orgQuery.parse('foo|bar').value,
        OrgQueryOrMatcher(
          [OrgQueryTagMatcher('foo'), OrgQueryTagMatcher('bar')],
        ),
      );
      expect(
        orgQuery.parse('foo|+bar').value,
        OrgQueryOrMatcher(
          [OrgQueryTagMatcher('foo'), OrgQueryTagMatcher('bar')],
        ),
      );
      expect(
        orgQuery.parse('foo|-bar').value,
        OrgQueryOrMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryNotMatcher(OrgQueryTagMatcher('bar')),
          ],
        ),
      );
      expect(
        orgQuery.parse('foo&bar|-baz').value,
        OrgQueryOrMatcher(
          [
            OrgQueryAndMatcher([
              OrgQueryTagMatcher('foo'),
              OrgQueryTagMatcher('bar'),
            ]),
            OrgQueryNotMatcher(OrgQueryTagMatcher('baz')),
          ],
        ),
      );
      expect(
        orgQuery.parse('foo+bar|-baz&buzz').value,
        OrgQueryOrMatcher(
          [
            OrgQueryAndMatcher([
              OrgQueryTagMatcher('foo'),
              OrgQueryTagMatcher('bar'),
            ]),
            OrgQueryAndMatcher([
              OrgQueryNotMatcher(OrgQueryTagMatcher('baz')),
              OrgQueryTagMatcher('buzz'),
            ]),
          ],
        ),
      );
      expect(
        orgQuery.parse('foo|+bar&-baz|+buzz').value,
        OrgQueryOrMatcher(
          [
            OrgQueryTagMatcher('foo'),
            OrgQueryOrMatcher([
              OrgQueryAndMatcher([
                OrgQueryTagMatcher('bar'),
                OrgQueryNotMatcher(OrgQueryTagMatcher('baz')),
              ]),
              OrgQueryTagMatcher('buzz'),
            ]),
          ],
        ),
      );
    });
  });
  group('property', () {
    test('single included tag', () {
      expect(
        orgQuery.parse('TODO="TODO"').value,
        OrgQueryPropertyMatcher(
          property: 'TODO',
          operator: '=',
          value: 'TODO',
        ),
      );
      expect(
        orgQuery.parse('+TODO="TODO"').value,
        OrgQueryPropertyMatcher(
          property: 'TODO',
          operator: '=',
          value: 'TODO',
        ),
      );
    });
    test('multiple', () {
      expect(
        orgQuery.parse('LEVEL>2-foo').value,
        OrgQueryAndMatcher([
          OrgQueryPropertyMatcher(
            property: 'LEVEL',
            operator: '>',
            value: 2,
          ),
          OrgQueryNotMatcher(OrgQueryTagMatcher('foo')),
        ]),
      );
      expect(
        orgQuery.parse('-LEVEL>2+PRIORITY="C"').value,
        OrgQueryAndMatcher([
          OrgQueryNotMatcher(OrgQueryPropertyMatcher(
            property: 'LEVEL',
            operator: '>',
            value: 2,
          )),
          OrgQueryPropertyMatcher(
            property: 'PRIORITY',
            operator: '=',
            value: 'C',
          ),
        ]),
      );
    });
  });
}
