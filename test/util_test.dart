import 'package:org_parser/src/org.dart';
import 'package:org_parser/src/util/util.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  test('indent parser', () {
    final parser = whitespace().star() & indentedRegion();
    var result = parser.end().pick(1).parse('''  abc
  def
  hij''');
    expect(result.value, 'abc\n  def\n  hij');
    result = parser.pick(1).parse('''  abc
  def
 hij''');
    expect(result.value, 'abc\n  def\n',
        reason: 'last line has less indentation');
    result = parser.end().pick(1).parse('''  abc
   def
  hij''');
    expect(result.value, 'abc\n   def\n  hij',
        reason: 'more indentation is ok');
    result = parser.end().pick(1).parse('''  abc
  def

  hij''');
    expect(result.value, 'abc\n  def\n\n  hij', reason: 'blank lines are ok');
  });
  test('indent parser with max blank lines', () {
    final parser =
        whitespace().star() & indentedRegion(maxSeparatingLineBreaks: 1);
    final result = parser.pick(1).parse('''  abc
  def

  hij''');
    expect(result.value, 'abc\n  def\n', reason: 'blank lines are ok');
  });
  test('indent parser with adjustment', () {
    final parser = whitespace().star() & indentedRegion(indentAdjust: 1);
    var result = parser.end().pick(1).parse('''  abc
   def
   hij''');
    expect(result.value, 'abc\n   def\n   hij');
    result = parser.pick(1).parse('''  abc
 def
 hij''');
    expect(result.value, 'abc\n',
        reason: '1 extra space of indentation required');
  });
  test('recursive list parser', () {
    final listStart =
        (lineStart() & whitespace().star() & string('- ')).flatten();
    final list = undefined();
    list.set(listStart &
        indentedRegion(
            parser: (list | any().plusLazy(listStart | endOfInput()).flatten())
                .star()));
    final result = list.plus().end().parse('''- abc
- def
  - hij''');
    expect(result.value, [
      [
        '- ',
        ['abc\n']
      ],
      [
        '- ',
        [
          'def\n',
          [
            '  - ',
            ['hij']
          ]
        ]
      ]
    ]);
  });
  test('no-op parser', () {
    var parser = noOpFail();
    var result = parser.parse('');
    expect(result.isFailure, true);
    parser = NoOpParser(true);
    result = parser.parse('');
    expect(result.isSuccess, true);
    expect(result.value, '');
  });
  test('url parser', () {
    expect(true, isOrgLocalSectionUrl('*foo'));
    expect(false, isOrgLocalSectionUrl('foo'));
    expect('foo bar', parseOrgLocalSectionUrl('*foo bar'));
    expect('foo bar', parseOrgLocalSectionUrl('''*foo
  bar'''));
  });
}
