import 'package:org_parser/src/query/query.dart';
import 'package:test/test.dart';

import 'matchers.dart';

void main() {
  group('and', () {
    test('empty', () {
      expect(OrgQueryAndMatcher([]), acceptsSection('* blah'));
    });
  });
  group('or', () {
    test('empty', () {
      expect(OrgQueryOrMatcher([]), rejectsSection('* blah'));
    });
  });
  group('tag', () {
    test('single included tag', () {
      expect(OrgQueryTagMatcher('foo'), acceptsSection('* blah :foo:'));
      expect(OrgQueryTagMatcher('foo'), rejectsSection('* blah :bar:'));
    });
    test('single excluded tag', () {
      expect(
        OrgQueryNotMatcher(OrgQueryTagMatcher('foo')),
        acceptsSection('* blah :bar:'),
      );
      expect(
        OrgQueryNotMatcher(OrgQueryTagMatcher('foo')),
        rejectsSection('* blah :foo:'),
      );
    });
    test('and tags', () {
      expect(
        OrgQueryAndMatcher([
          OrgQueryTagMatcher('foo'),
          OrgQueryTagMatcher('bar'),
        ]),
        acceptsSection('* blah :foo:bar:'),
      );
      expect(
        OrgQueryAndMatcher([
          OrgQueryNotMatcher(OrgQueryTagMatcher('foo')),
          OrgQueryTagMatcher('bar'),
        ]),
        acceptsSection('* blah :bar:'),
      );
      expect(
        OrgQueryAndMatcher([
          OrgQueryTagMatcher('foo'),
          OrgQueryTagMatcher('bar'),
        ]),
        rejectsSection('* blah :foo:'),
      );
    });
  });
  group('property', () {
    test('todo', () {
      expect(
        OrgQueryPropertyMatcher(property: 'TODO', operator: '=', value: 'DONE'),
        acceptsSection('* DONE blah'),
      );
      expect(
        OrgQueryPropertyMatcher(property: 'TODO', operator: '=', value: 'TODO'),
        acceptsSection('* TODO foo'),
      );
      expect(
        OrgQueryPropertyMatcher(property: 'TODO', operator: '=', value: 'DONE'),
        rejectsSection('* TODO blah'),
      );
      expect(
        OrgQueryPropertyMatcher(property: 'TODO', operator: '=', value: 'DONE'),
        rejectsSection('* blah'),
      );
    });
    test('level', () {
      expect(
        OrgQueryPropertyMatcher(property: 'LEVEL', operator: '=', value: 1),
        acceptsSection('* blah'),
      );
      expect(
        OrgQueryPropertyMatcher(property: 'LEVEL', operator: '=', value: 1),
        rejectsSection('** blah'),
      );
      expect(
        OrgQueryPropertyMatcher(property: 'LEVEL', operator: '=', value: 2),
        acceptsSection('** blah'),
      );
      expect(
        OrgQueryPropertyMatcher(property: 'LEVEL', operator: '=', value: 2),
        rejectsSection('*** blah'),
      );
      expect(
        OrgQueryPropertyMatcher(property: 'LEVEL', operator: '>', value: 2),
        acceptsSection('*** blah'),
      );
    });
    test('priority', () {
      expect(
        OrgQueryPropertyMatcher(
          property: 'PRIORITY',
          operator: '=',
          value: 'A',
        ),
        acceptsSection('* [#A] blah'),
      );
      expect(
        OrgQueryPropertyMatcher(
          property: 'PRIORITY',
          operator: '=',
          value: 'B',
        ),
        rejectsSection('* [#A] blah'),
      );
    });
  });
}
