import 'package:org_parser/src/query/query.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('grammar', () {
    final grammarDefinition = OrgQueryGrammarDefinition();
    group('parts', () {
      test('tag', () {
        final parser =
            grammarDefinition.buildFrom(grammarDefinition.tag()).end();
        expect(parser.parse('tag').value, 'tag');
        expect(parser.parse('tag!'), isA<Failure>());
      });
      test('exclude', () {
        final parser =
            grammarDefinition.buildFrom(grammarDefinition.exclude()).end();
        expect(parser.parse('-tag').value, ['-', 'tag']);
        expect(parser.parse('tag'), isA<Failure>());
        expect(parser.parse('+tag'), isA<Failure>());
      });
      test('include', () {
        final parser =
            grammarDefinition.buildFrom(grammarDefinition.include()).end();
        expect(parser.parse('+tag').value, ['+', 'tag']);
        expect(parser.parse('tag').value, 'tag');
        expect(parser.parse('-tag'), isA<Failure>());
      });
      test('and', () {
        final parser =
            grammarDefinition.buildFrom(grammarDefinition.selection()).end();
        expect(parser.parse('+foo').value, ['+', 'foo']);
        expect(parser.parse('foo').value, 'foo');
        expect(parser.parse('-foo').value, ['-', 'foo']);
        expect(parser.parse('+foo+bar').value, [
          ['+', 'foo'],
          ['+', 'bar']
        ]);
        expect(parser.parse('foo-bar').value, [
          'foo',
          ['-', 'bar']
        ]);
        expect(parser.parse('foo+bar+baz').value, [
          'foo',
          [
            ['+', 'bar'],
            ['+', 'baz']
          ]
        ]);
        expect(parser.parse('foo&bar+baz').value, [
          'foo',
          '&',
          [
            'bar',
            ['+', 'baz']
          ]
        ]);
        expect(parser.parse('+foo-bar&+baz').value, [
          ['+', 'foo'],
          [
            ['-', 'bar'],
            '&',
            ['+', 'baz']
          ]
        ]);
        expect(parser.parse('foo-bar&baz&-buzz').value, [
          'foo',
          [
            ['-', 'bar'],
            '&',
            [
              'baz',
              '&',
              ['-', 'buzz']
            ]
          ]
        ]);
      });
      test('or', () {
        final parser =
            grammarDefinition.buildFrom(grammarDefinition.alternates()).end();
        expect(parser.parse('foo').value, 'foo');
        expect(parser.parse('foo|bar').value, ['foo', '|', 'bar']);
        expect(parser.parse('foo|bar|baz').value, [
          'foo',
          '|',
          ['bar', '|', 'baz']
        ]);
        expect(parser.parse('foo|bar&baz').value, [
          'foo',
          '|',
          ['bar', '&', 'baz']
        ]);
        expect(parser.parse('foo&bar|baz').value, [
          ['foo', '&', 'bar'],
          '|',
          'baz'
        ]);
        expect(parser.parse('foo|bar&baz|buzz').value, [
          'foo',
          '|',
          [
            ['bar', '&', 'baz'],
            '|',
            'buzz'
          ]
        ]);
        expect(parser.parse('foo|bar&baz|buzz&fizz').value, [
          'foo',
          '|',
          [
            ['bar', '&', 'baz'],
            '|',
            ['buzz', '&', 'fizz']
          ]
        ]);
        expect(parser.parse('foo+bar|bar-baz|buzz+fizz').value, [
          [
            'foo',
            ['+', 'bar']
          ],
          '|',
          [
            [
              'bar',
              ['-', 'baz']
            ],
            '|',
            [
              'buzz',
              ['+', 'fizz']
            ]
          ]
        ]);
      });
    });
  });
}
